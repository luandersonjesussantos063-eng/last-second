# Atualizacao de teste: base com interior, favela e operacoes. Execute com o servidor parado.
[CmdletBinding()]
param([string]$ServerDataPath = 'C:\txData\FiveMBasicServerCFXDefault_F3288B.base')
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression.FileSystem
$server = [IO.Path]::GetFullPath($ServerDataPath)
$cfg = [IO.Path]::Combine($server, 'server.cfg')
if (-not [IO.File]::Exists($cfg)) { throw "server.cfg nao encontrado: $server" }
$sourceRoot = [IO.Path]::GetFullPath([IO.Path]::Combine($PSScriptRoot, '..'))
$baseZip = [IO.Path]::Combine($sourceRoot, 'diagnostics', 'PRF-Base-Interior-Teste.zip')
$baseHash = '948697523bb966a3182ea6b4932a2512d5760bb4c078dec50d1ccde2992b960e'
if (-not [IO.File]::Exists($baseZip) -or
    (Get-FileHash -LiteralPath $baseZip -Algorithm SHA256).Hash.ToLowerInvariant() -ne $baseHash) {
  throw 'Pacote da base ausente ou alterado. Extraia o ZIP completo da atualizacao.'
}
$resources = [IO.Path]::Combine($server, 'resources', '[prf]')
$coreSource = [IO.Path]::Combine($sourceRoot, 'resources', '[prf]', 'prf_core')
$favelaSource = [IO.Path]::Combine($sourceRoot, 'resources', '[prf]', 'prf_favela_realista')
$vehicleSource = [IO.Path]::Combine($sourceRoot, 'resources', '[prf]', 'prf_equinox_replace')
$vehicleHashes = @{
  'police.yft' = 'd85a7aa4d481a34dbe89d3324081257c413c7c6c290a353f9b37044dfdc52d7e'
  'police_hi.yft' = '9c635a7dbf5f04c31fefe01718a29e78da31c101edbebed5c84204231ab3f857'
  'police.ytd' = 'e76742124ad52f0300781ed17fd1417273e281ec65a2b6481bdfafdfb70c01a1'
  'police+hi.ytd' = 'e76742124ad52f0300781ed17fd1417273e281ec65a2b6481bdfafdfb70c01a1'
}
foreach ($name in $vehicleHashes.Keys) {
  $file = [IO.Path]::Combine($vehicleSource,'stream',$name)
  if (-not [IO.File]::Exists($file) -or
      (Get-FileHash -LiteralPath $file -Algorithm SHA256).Hash.ToLowerInvariant() -ne $vehicleHashes[$name]) {
    throw "Pacote da viatura incompleto ou alterado: $name. Extraia o ZIP completo."
  }
}
if (-not [IO.File]::Exists([IO.Path]::Combine($vehicleSource,'fxmanifest.lua'))) {
  throw 'Falta o manifesto da viatura no ZIP.'
}
$coreFiles = @('fxmanifest.lua','config.lua','operations_config.lua','client.lua',
  'base_client.lua','keys_client.lua','squad_client.lua','operations_client.lua',
  'server.lua','operations_server.lua','people_client.lua','people_server.lua',
  'commands_client.lua','commands_server.lua','backup_client.lua','backup_server.lua','driver_client.lua','driver_server.lua','traffic_client.lua',
  'copom_config.lua','copom_client.lua','copom_server.lua','gameplay_config.lua','base_stream_client.lua','progress_server.lua','inventory_client.lua','inventory_server.lua',
  'tablet_client.lua','services_client.lua','services_server.lua','blitz_client.lua','blitz_server.lua',
  'html/index.html','html/style.css','html/app.js')
foreach ($name in $coreFiles) {
  if (-not [IO.File]::Exists([IO.Path]::Combine($coreSource,$name))) { throw "Pacote incompleto: prf_core/$name" }
}
$originPath = [IO.Path]::Combine($favelaSource, 'origem.json')
if (-not [IO.File]::Exists($originPath)) { throw 'Falta o recurso prf_favela_realista no ZIP.' }
$origin = [IO.File]::ReadAllText($originPath) | ConvertFrom-Json
if (-not $origin.deployment_files -or @($origin.deployment_files).Count -lt 20) {
  throw 'Manifesto de integridade da favela incompleto.'
}
foreach ($entry in $origin.deployment_files) {
  $relative = [string]$entry.path
  if ([IO.Path]::IsPathRooted($relative) -or $relative -match '(^|[\\/])\.\.([\\/]|$)') {
    throw 'Caminho invalido no manifesto da favela.'
  }
  $file = [IO.Path]::Combine($favelaSource,$relative.Replace('/',[IO.Path]::DirectorySeparatorChar))
  if (-not [IO.File]::Exists($file) -or
      (Get-FileHash -LiteralPath $file -Algorithm SHA256).Hash.ToLowerInvariant() -ne $entry.sha256) {
    throw "Favela incompleta ou alterada: $relative"
  }
}

function Copy-Tree([string]$Source, [string]$Destination) {
  [IO.Directory]::CreateDirectory($Destination) | Out-Null
  foreach ($path in [IO.Directory]::GetFiles($Source,'*',[IO.SearchOption]::AllDirectories)) {
    $relative = $path.Substring($Source.Length).TrimStart([char[]]@('\','/'))
    $target = [IO.Path]::Combine($Destination,$relative)
    [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($target)) | Out-Null
    [IO.File]::Copy($path,$target,$true)
  }
}
$temp = [IO.Path]::Combine([IO.Path]::GetTempPath(),'prf-update-'+[guid]::NewGuid().ToString('N'))
$backup = [IO.Path]::Combine($server,'_prf_backups',(Get-Date -Format 'yyyyMMdd-HHmmss-fffffff'))
$oldCfg = [IO.File]::ReadAllText($cfg)
# Os dois mods substituem police: conserva a Trailblazer ja instalada ou instala
# a Equinox incluida no ZIP. Apenas um replace deve ficar iniciado por vez.
$vehicleResource = 'prf_equinox_replace'
$otherVehicle = 'prf_trailblazer'
$trail = [IO.Path]::Combine($resources,'prf_trailblazer')
$hasTrail = [IO.File]::Exists([IO.Path]::Combine($trail,'fxmanifest.lua'))
foreach ($name in @('police.yft','police_hi.yft','police.ytd')) {
  $file = [IO.Path]::Combine($trail,'stream',$name)
  if (-not [IO.File]::Exists($file) -or [IO.FileInfo]::new($file).Length -lt 16) { $hasTrail = $false }
}
if ($hasTrail) { $vehicleResource = 'prf_trailblazer'; $otherVehicle = 'prf_equinox_replace' }
$created, $saved = @(), @()
try {
  [IO.Directory]::CreateDirectory($temp) | Out-Null
  [IO.Compression.ZipFile]::ExtractToDirectory($baseZip,$temp)
  $mapSource = [IO.Path]::Combine($temp,'prfMiniLN3d3v')
  if (-not [IO.File]::Exists([IO.Path]::Combine($mapSource,'fxmanifest.lua'))) { throw 'ZIP da base sem manifesto.' }
  [IO.Directory]::CreateDirectory($backup) | Out-Null
  [IO.File]::Copy($cfg,[IO.Path]::Combine($backup,'server.cfg'),$false)
  [IO.Directory]::CreateDirectory($resources) | Out-Null
  $sources = [ordered]@{
    prfMiniLN3d3v = $mapSource
    prf_favela_realista = $favelaSource
    prf_core = $coreSource
  }
  if ($vehicleResource -eq 'prf_equinox_replace') { $sources.Add($vehicleResource,$vehicleSource) }
  foreach ($name in $sources.Keys) {
    $destination = [IO.Path]::Combine($resources,$name)
    if ([IO.Directory]::Exists($destination)) {
      [IO.Directory]::Move($destination,[IO.Path]::Combine($backup,$name))
      $saved += $name
    }
    $created += $name
    Copy-Tree $sources[$name] $destination
  }
  $newline = if ($oldCfg.Contains("`r`n")) { "`r`n" } else { "`n" }
  $next = [regex]::Replace($oldCfg,'(?ms)^# PRF TEST UPDATE START\r?\n.*?^# PRF TEST UPDATE END\r?\n?', '')
  foreach ($name in (@($sources.Keys) + @('prf_equinox_replace','prf_trailblazer'))) {
    $pattern = '(?im)^[ \t]*(?:ensure|start)[ \t]+'+[regex]::Escape($name)+'[ \t]*(?:#.*)?(?:\r?\n|$)'
    $next = [regex]::Replace($next,$pattern,'')
  }
  $stopOther = ''
  if ([IO.Directory]::Exists([IO.Path]::Combine($resources,$otherVehicle))) {
    $stopOther = 'stop ' + $otherVehicle + $newline
  }
  $next = $next.TrimEnd([char[]]@("`r","`n")) + $newline +
    '# PRF TEST UPDATE START' + $newline +
    $stopOther + 'ensure prfMiniLN3d3v' + $newline +
    'ensure ' + $vehicleResource + $newline + 'ensure prf_favela_realista' + $newline +
    'ensure prf_core' + $newline + '# PRF TEST UPDATE END' + $newline
  [IO.File]::WriteAllText($cfg,$next,[Text.UTF8Encoding]::new($false))
  Write-Host 'Atualizacao instalada. Inicie o servidor no txAdmin e reconecte ao FiveM.'
  Write-Host 'T: servico | viatura | abordar | documento | revistar | ajuda'
  Write-Host 'Z: mirar | T: reforco 3 | desce do carro | deita no chao | liberarcarro'
  Write-Host 'Prisao de NPC: prender | entrar no carro | base | registrarprisao | prisoes'
  Write-Host "Viatura PRF instalada/iniciada: $vehicleResource | F9: primeira opcao PRF"
  Write-Host "Backup fora de resources: $backup"
  Write-Host 'A permissao ACE individual e os demais recursos foram preservados.'
} catch {
  foreach ($name in $created) {
    $destination = [IO.Path]::Combine($resources,$name)
    if ([IO.Directory]::Exists($destination)) { [IO.Directory]::Delete($destination,$true) }
  }
  foreach ($name in $saved) {
    [IO.Directory]::Move([IO.Path]::Combine($backup,$name),[IO.Path]::Combine($resources,$name))
  }
  if ([IO.File]::Exists([IO.Path]::Combine($backup,'server.cfg'))) {
    [IO.File]::Copy([IO.Path]::Combine($backup,'server.cfg'),$cfg,$true)
  }
  throw
} finally {
  if ([IO.Directory]::Exists($temp)) { [IO.Directory]::Delete($temp,$true) }
}
