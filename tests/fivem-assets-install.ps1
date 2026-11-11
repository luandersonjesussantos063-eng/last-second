$ErrorActionPreference = 'Stop'
$fixture = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), 'prf-install-' + [guid]::NewGuid().ToString('N'))
function Check([bool]$condition, [string]$message) {
  if (-not $condition) { throw $message }
}
function Write-Metadata([string]$ResourceRoot, [string[]]$RelativePaths, [byte[]]$Bytes, $Assembly = $null) {
  $sha = [System.Security.Cryptography.SHA256]::Create()
  try { $hash = [System.BitConverter]::ToString($sha.ComputeHash($Bytes)).Replace('-', '').ToLowerInvariant() } finally { $sha.Dispose() }
  $entries = @($RelativePaths | ForEach-Object { @{ destination = $_; bytes = $Bytes.Length; sha256 = $hash } })
  $metadata = @{ files = $entries }
  if ($Assembly) { $metadata.assembly = $Assembly }
  [System.IO.File]::WriteAllText([System.IO.Path]::Combine($ResourceRoot, 'origem.json'), ($metadata | ConvertTo-Json -Depth 8))
  return $hash
}
try {
  $source = [System.IO.Path]::Combine($fixture, 'package')
  $scripts = [System.IO.Path]::Combine($source, 'scripts')
  $resources = [System.IO.Path]::Combine($source, 'resources', '[prf]')
  $server = [System.IO.Path]::Combine($fixture, 'server')
  [System.IO.Directory]::CreateDirectory($scripts) | Out-Null
  [System.IO.Directory]::CreateDirectory($server) | Out-Null
  $helper = [System.IO.Path]::Combine($scripts, 'install-prf-assets.ps1')
  [System.IO.File]::Copy([System.IO.Path]::Combine($PSScriptRoot, '..', 'fivem', 'scripts', 'install-prf-assets.ps1'), $helper)
  $cfg = [System.IO.Path]::Combine($server, 'server.cfg')
  $initial = "ensure unrelated`r`nadd_ace identifier.fivem:fixture prfrp.officer allow`r`nensure prf_core`r`nensure prf_trailblazer # keep note`r`n"
  [System.IO.File]::WriteAllText($cfg, $initial)

  # Um manifest sem streaming nao deve ser instalado nem ativado.
  $trail = [System.IO.Path]::Combine($resources, 'prf_trailblazer')
  [System.IO.Directory]::CreateDirectory($trail) | Out-Null
  [System.IO.File]::WriteAllText([System.IO.Path]::Combine($trail, 'fxmanifest.lua'), "game 'gta5'")
  & $helper -ServerDataPath $server
  Check ([System.IO.File]::ReadAllText($cfg) -eq $initial) 'Recurso vazio alterou server.cfg'
  Check (-not [System.IO.Directory]::Exists([System.IO.Path]::Combine($server, 'resources', '[prf]', 'prf_trailblazer'))) 'Copiou resource vazio'

  $stream = [System.IO.Path]::Combine($trail, 'stream')
  [System.IO.Directory]::CreateDirectory($stream) | Out-Null
  $bytes = [byte[]]@(82, 83, 67, 55, 0, 255, 128, 17)
  foreach ($name in @('police.yft', 'police_hi.yft', 'police.ytd')) {
    [System.IO.File]::WriteAllBytes([System.IO.Path]::Combine($stream, $name), $bytes)
  }
  $modelHash = Write-Metadata $trail @('stream/police.yft', 'stream/police_hi.yft', 'stream/police.ytd') $bytes
  & $helper -ServerDataPath $server
  $updated = [System.IO.File]::ReadAllText($cfg)
  Check ($updated.IndexOf('ensure prf_trailblazer') -lt $updated.IndexOf('ensure prf_core')) 'Ordem incorreta no cfg CRLF'
  Check ($updated.Contains('# keep note')) 'Comentario da linha movida foi perdido'
  Check ($updated.Contains('ensure unrelated') -and $updated.Contains('identifier.fivem:fixture')) 'Alterou configuracoes externas'
  $copied = [System.IO.File]::ReadAllBytes([System.IO.Path]::Combine($server, 'resources', '[prf]', 'prf_trailblazer', 'stream', 'police.ytd'))
  Check ([Convert]::ToBase64String($copied) -eq [Convert]::ToBase64String($bytes)) 'Bytes do mod foram alterados'
  $backups = @([System.IO.Directory]::GetFiles($server, 'server.cfg.bak-assets-*'))
  Check ($backups.Count -eq 1) 'Backup do cfg nao foi criado'
  Check ([System.IO.File]::ReadAllText($backups[0]) -eq $initial) 'Backup nao preserva o cfg original'
  & $helper -ServerDataPath $server
  Check ([System.IO.File]::ReadAllText($cfg) -eq $updated) 'Segunda instalacao nao e idempotente'

  # Recurso de roupas presente, com arquivo extra e diretorios, copia integralmente.
  $uniform = [System.IO.Path]::Combine($resources, 'prf_uniformes_wlukaas')
  $uniformStream = [System.IO.Path]::Combine($uniform, 'stream', 'male')
  [System.IO.Directory]::CreateDirectory($uniformStream) | Out-Null
  [System.IO.File]::WriteAllText([System.IO.Path]::Combine($uniform, 'fxmanifest.lua'), "game 'gta5'")
  [System.IO.File]::WriteAllText([System.IO.Path]::Combine($uniform, 'creditos.txt'), 'wlukaas')
  [System.IO.File]::WriteAllBytes([System.IO.Path]::Combine($uniformStream, 'component.ydd'), $bytes)
  [System.IO.File]::WriteAllBytes([System.IO.Path]::Combine($uniformStream, 'component.ytd'), $bytes)
  [void](Write-Metadata $uniform @('stream/male/component.ydd', 'stream/male/component.ytd') $bytes)
  [System.IO.File]::WriteAllText($cfg, "ensure unrelated`n")
  # Um uniforme com modelo mas sem uma textura declarada nao deve ser ativado.
  [System.IO.File]::Delete([System.IO.Path]::Combine($uniformStream, 'component.ytd'))
  & $helper -ServerDataPath $server
  Check (-not [System.IO.File]::ReadAllText($cfg).Contains('prf_uniformes_wlukaas')) 'Ativou uniforme parcial'
  Check (-not [System.IO.Directory]::Exists([System.IO.Path]::Combine($server, 'resources', '[prf]', 'prf_uniformes_wlukaas'))) 'Copiou uniforme parcial'
  [System.IO.File]::WriteAllBytes([System.IO.Path]::Combine($uniformStream, 'component.ytd'), $bytes)
  & $helper -ServerDataPath $server
  $noCore = [System.IO.File]::ReadAllText($cfg)
  Check ($noCore.Contains('ensure prf_trailblazer') -and $noCore.Contains('ensure prf_uniformes_wlukaas')) 'Nao adicionou ambos recursos antes do instalador principal'
  Check (-not $noCore.Contains('ensure prf_core')) 'Helper alterou ativacao do core'
  Check ([System.IO.File]::ReadAllText([System.IO.Path]::Combine($server, 'resources', '[prf]', 'prf_uniformes_wlukaas', 'creditos.txt')) -eq 'wlukaas') 'Nao copiou recurso completo'
  # O ZIP do GitHub leva o modelo em partes; ambos YFT sao identicos ao original.
  $partsFolder = [System.IO.Path]::Combine($trail, 'source')
  [System.IO.Directory]::CreateDirectory($partsFolder) | Out-Null
  $partOne = [System.IO.Path]::Combine($partsFolder, 'police.yft.part1')
  $partTwo = [System.IO.Path]::Combine($partsFolder, 'police.yft.part2')
  [System.IO.File]::WriteAllBytes($partOne, [byte[]]$bytes[0..3])
  [System.IO.File]::WriteAllBytes($partTwo, [byte[]]$bytes[4..7])
  $assembly = @{ parts = @('source/police.yft.part1', 'source/police.yft.part2'); outputs = @('stream/police.yft', 'stream/police_hi.yft'); bytes = $bytes.Length; sha256 = $modelHash }
  [void](Write-Metadata $trail @('stream/police.yft', 'stream/police_hi.yft', 'stream/police.ytd') $bytes $assembly)
  foreach ($name in @('police.yft', 'police_hi.yft')) { [System.IO.File]::Delete([System.IO.Path]::Combine($stream, $name)) }
  & $helper -ServerDataPath $server
  foreach ($name in @('police.yft', 'police_hi.yft')) {
    $path = [System.IO.Path]::Combine($stream, $name)
    Check ([Convert]::ToBase64String([System.IO.File]::ReadAllBytes($path)) -eq [Convert]::ToBase64String($bytes)) 'Modelo recomposto nao corresponde ao original'
    [System.IO.File]::SetLastWriteTimeUtc($path, [datetime]'2001-02-03T04:05:06Z')
  }
  & $helper -ServerDataPath $server
  Check ([System.IO.File]::GetLastWriteTimeUtc([System.IO.Path]::Combine($stream, 'police.yft')) -eq [datetime]'2001-02-03T04:05:06Z') 'Reescreveu origem integra'
  $highModel = [System.IO.Path]::Combine($stream, 'police_hi.yft')
  [System.IO.File]::WriteAllBytes($highModel, [byte[]]@(1, 2, 3))
  & $helper -ServerDataPath $server
  Check ([Convert]::ToBase64String([System.IO.File]::ReadAllBytes($highModel)) -eq [Convert]::ToBase64String($bytes)) 'Nao reparou origem corrompida preservando a origem valida'
  Check ([System.IO.File]::GetLastWriteTimeUtc([System.IO.Path]::Combine($stream, 'police.yft')) -eq [datetime]'2001-02-03T04:05:06Z') 'Reparo alterou a outra origem integra'
  $cfgBeforeFailure = [System.IO.File]::ReadAllText($cfg)
  foreach ($name in @('police.yft', 'police_hi.yft')) { [System.IO.File]::Delete([System.IO.Path]::Combine($stream, $name)) }
  # Mesmo tamanho, hash errado: a parte deve ser recusada antes de alterar servidor.
  [System.IO.File]::WriteAllBytes($partTwo, [byte[]]@(0, 255, 128, 99))
  $failed = $false
  try { & $helper -ServerDataPath $server } catch { $failed = $true }
  Check $failed 'Aceitou parte corrompida'
  Check ([System.IO.File]::ReadAllText($cfg) -eq $cfgBeforeFailure) 'Falha de montagem alterou cfg'
  $destinationModel = [System.IO.Path]::Combine($server, 'resources', '[prf]', 'prf_trailblazer', 'stream', 'police.yft')
  Check ([Convert]::ToBase64String([System.IO.File]::ReadAllBytes($destinationModel)) -eq [Convert]::ToBase64String($bytes)) 'Falha de montagem alterou modelo instalado'
  Check (@([System.IO.Directory]::GetFiles($stream, '*.tmp')).Count -eq 0) 'Montagem deixou temporarios'
  Check (-not [System.IO.File]::Exists([System.IO.Path]::Combine($stream, 'police.yft'))) 'Montagem invalida criou origem final'
  Write-Host 'FiveM assets installer: all checks passed'
} finally {
  if ([System.IO.Directory]::Exists($fixture)) { [System.IO.Directory]::Delete($fixture, $true) }
}
