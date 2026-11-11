# Instala somente os dois recursos opcionais preparados a partir dos arquivos enviados.
# Recompoe os modelos divididos no GitHub e confere os hashes antes de copiar.
[CmdletBinding()]
param(
  [Parameter(Mandatory = $true)]
  [ValidateNotNullOrEmpty()]
  [string]$ServerDataPath
)
$ErrorActionPreference = 'Stop'

$dataFolder = [System.IO.Path]::GetFullPath($ServerDataPath)
$cfgPath = [System.IO.Path]::Combine($dataFolder, 'server.cfg')
if (-not [System.IO.File]::Exists($cfgPath)) {
  throw "server.cfg nao encontrado em $dataFolder"
}
$sourceFolder = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine(
  $PSScriptRoot, '..', 'resources', '[prf]'
))
$installed = @()

function Resolve-PrfResourcePath([string]$ResourceRoot, [string]$RelativePath) {
  if ([string]::IsNullOrWhiteSpace($RelativePath) -or
      [System.IO.Path]::IsPathRooted($RelativePath) -or
      $RelativePath -match '(^|[\\/])\.\.([\\/]|$)') {
    throw "Caminho invalido no manifesto do recurso: $RelativePath"
  }
  $root = [System.IO.Path]::GetFullPath($ResourceRoot).TrimEnd([char[]]@('\', '/')) + [System.IO.Path]::DirectorySeparatorChar
  $full = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($root, $RelativePath.Replace('/', [System.IO.Path]::DirectorySeparatorChar)))
  $comparison = if ([System.IO.Path]::DirectorySeparatorChar -eq '\') { [System.StringComparison]::OrdinalIgnoreCase } else { [System.StringComparison]::Ordinal }
  if (-not $full.StartsWith($root, $comparison)) { throw "Caminho fora do recurso: $RelativePath" }
  return $full
}

function Test-PrfBinary([string]$Path, [long]$ExpectedBytes, [string]$ExpectedHash) {
  if ($ExpectedBytes -le 0 -or $ExpectedHash -notmatch '^[a-fA-F0-9]{64}$') {
    throw 'Tamanho ou SHA256 invalido no manifesto do recurso.'
  }
  if (-not [System.IO.File]::Exists($Path) -or [System.IO.FileInfo]::new($Path).Length -ne $ExpectedBytes) { return $false }
  $inputFile = [System.IO.File]::OpenRead($Path)
  $sha = [System.Security.Cryptography.SHA256]::Create()
  try {
    $actual = [System.BitConverter]::ToString($sha.ComputeHash($inputFile)).Replace('-', '').ToLowerInvariant()
    return $actual -eq $ExpectedHash.ToLowerInvariant()
  } finally {
    $inputFile.Dispose()
    $sha.Dispose()
  }
}

function Join-PrfVehicleParts([string]$ResourceRoot, $Assembly) {
  if (-not $Assembly) { return }
  $outputs = @($Assembly.outputs)
  if ($outputs.Count -ne 2 -or $outputs -notcontains 'stream/police.yft' -or
      $outputs -notcontains 'stream/police_hi.yft' -or @($Assembly.parts).Count -lt 1) {
    throw 'Configuracao de montagem da Trailblazer invalida.'
  }
  $pending = @()
  $validSource = $null
  foreach ($relative in $outputs) {
    $path = Resolve-PrfResourcePath $ResourceRoot $relative
    if (Test-PrfBinary $path $Assembly.bytes $Assembly.sha256) {
      $validSource = $path
    } else {
      $pending += $path
    }
  }
  if ($pending.Count -eq 0) { return } # Originais integros sao preservados, inclusive datas.

  $streamFolder = [System.IO.Path]::GetDirectoryName($pending[0])
  [System.IO.Directory]::CreateDirectory($streamFolder) | Out-Null
  $joined = [System.IO.Path]::Combine($streamFolder, '.prf-assembly-' + [guid]::NewGuid().ToString('N') + '.tmp')
  $staged = @()
  try {
    $outputFile = [System.IO.File]::Open($joined, [System.IO.FileMode]::CreateNew, [System.IO.FileAccess]::Write, [System.IO.FileShare]::None)
    try {
      $sources = if ($validSource) { @($validSource) } else {
        @($Assembly.parts | ForEach-Object { Resolve-PrfResourcePath $ResourceRoot $_ })
      }
      foreach ($part in $sources) {
        if (-not [System.IO.File]::Exists($part)) { throw "Parte do modelo ausente: $part" }
        $inputFile = [System.IO.File]::OpenRead($part)
        try { $inputFile.CopyTo($outputFile, 131072) } finally { $inputFile.Dispose() }
      }
    } finally { $outputFile.Dispose() }
    if (-not (Test-PrfBinary $joined $Assembly.bytes $Assembly.sha256)) {
      throw 'Partes da Trailblazer corrompidas: tamanho ou SHA256 diferente do original. Nenhum recurso foi instalado.'
    }
    # Prepara e valida todos os arquivos antes de mover qualquer destino final.
    foreach ($target in $pending) {
      $temp = $target + '.prf-' + [guid]::NewGuid().ToString('N') + '.tmp'
      $staged += @{ Temp = $temp; Target = $target; Backup = $temp + '.old' }
      [System.IO.File]::Copy($joined, $temp, $false)
      if (-not (Test-PrfBinary $temp $Assembly.bytes $Assembly.sha256)) { throw 'Falha ao preparar o modelo recomposto.' }
    }
    foreach ($item in $staged) {
      if ([System.IO.File]::Exists($item.Target)) {
        [System.IO.File]::Replace($item.Temp, $item.Target, $item.Backup)
      } else {
        [System.IO.File]::Move($item.Temp, $item.Target)
      }
    }
    Write-Host 'Trailblazer: modelos recompostos e conferidos com SHA256.'
  } finally {
    if ([System.IO.File]::Exists($joined)) { [System.IO.File]::Delete($joined) }
    foreach ($item in $staged) {
      if ([System.IO.File]::Exists($item.Temp)) { [System.IO.File]::Delete($item.Temp) }
      if ([System.IO.File]::Exists($item.Backup)) { [System.IO.File]::Delete($item.Backup) }
    }
  }
}

function Test-PrfResourceFiles([string]$ResourceRoot, $Metadata) {
  if (-not $Metadata -or -not $Metadata.files -or @($Metadata.files).Count -eq 0) { return $false }
  foreach ($entry in $Metadata.files) {
    if ($entry.destination -notmatch '^stream/') { throw 'Arquivo de streaming fora da pasta esperada no manifesto.' }
    $path = Resolve-PrfResourcePath $ResourceRoot $entry.destination
    if (-not (Test-PrfBinary $path $entry.bytes $entry.sha256)) { return $false }
  }
  return $true
}

foreach ($resourceName in @('prf_trailblazer', 'prf_uniformes_wlukaas')) {
  $resourceSource = [System.IO.Path]::Combine($sourceFolder, $resourceName)
  $stream = [System.IO.Path]::Combine($resourceSource, 'stream')
  $manifest = [System.IO.Path]::Combine($resourceSource, 'fxmanifest.lua')
  $metadataPath = [System.IO.Path]::Combine($resourceSource, 'origem.json')
  $metadata = if ([System.IO.File]::Exists($metadataPath)) {
    [System.IO.File]::ReadAllText($metadataPath) | ConvertFrom-Json
  } else { $null }
  if ($resourceName -eq 'prf_trailblazer' -and $metadata) {
    Join-PrfVehicleParts $resourceSource $metadata.assembly
  }
  $complete = [System.IO.File]::Exists($manifest) -and
    [System.IO.Directory]::Exists($stream) -and (Test-PrfResourceFiles $resourceSource $metadata)
  if (-not $complete) {
    Write-Host "$resourceName ignorado: arquivos de streaming ausentes ou diferentes do manifesto. Extraia o ZIP completo ou importe os mods primeiro."
    continue
  }

  $destination = [System.IO.Path]::Combine($dataFolder, 'resources', '[prf]', $resourceName)
  [System.IO.Directory]::CreateDirectory($destination) | Out-Null
  foreach ($filePath in [System.IO.Directory]::GetFiles($resourceSource, '*', [System.IO.SearchOption]::AllDirectories)) {
    $relative = $filePath.Substring($resourceSource.Length).TrimStart([char[]]@('\', '/'))
    $target = [System.IO.Path]::Combine($destination, $relative)
    [System.IO.Directory]::CreateDirectory([System.IO.Path]::GetDirectoryName($target)) | Out-Null
    [System.IO.File]::Copy($filePath, $target, $true)
  }
  $installed += $resourceName
  Write-Host "$resourceName instalado em $destination"
}

if ($installed.Count -eq 0) { return }
$original = [System.IO.File]::ReadAllText($cfgPath)
$updated = $original
$newline = if ($updated.Contains("`r`n")) { "`r`n" } else { "`n" }
$pendingLines = @()
$corePattern = '(?im)^[ \t]*(?:ensure|start)[ \t]+prf_core[ \t]*(?:#.*)?\r?$'
foreach ($resourceName in $installed) {
  $resourcePattern = '(?im)^[ \t]*(?:ensure|start)[ \t]+' + [regex]::Escape($resourceName) + '[ \t]*(?:#.*)?(?:\r?\n|$)'
  $existing = [regex]::Match($updated, $resourcePattern)
  $core = [regex]::Match($updated, $corePattern)
  if ($existing.Success -and (-not $core.Success -or $existing.Index -lt $core.Index)) {
    continue
  }
  # Se havia uma linha depois de prf_core, reposiciona conservando seu comentario.
  if ($existing.Success) {
    $pendingLines += $existing.Value.TrimEnd([char[]]@("`r", "`n"))
    $updated = [regex]::Replace($updated, $resourcePattern, '')
  } else {
    $pendingLines += 'ensure ' + $resourceName
  }
}
if ($pendingLines.Count -gt 0) {
  $block = ($pendingLines -join $newline) + $newline
  $core = [regex]::Match($updated, $corePattern)
  if ($core.Success) {
    $updated = $updated.Insert($core.Index, $block)
  } else {
    if ($updated.Length -gt 0 -and -not $updated.EndsWith("`n")) { $updated += $newline }
    $updated += $block
  }
}
if ($updated -ne $original) {
  $backup = "$cfgPath.bak-assets-$(Get-Date -Format 'yyyyMMdd-HHmmss-fffffff')"
  [System.IO.File]::Copy($cfgPath, $backup, $false)
  [System.IO.File]::WriteAllText($cfgPath, $updated, [System.Text.UTF8Encoding]::new($false))
  Write-Host "Recursos PRF configurados antes de prf_core; backup: $backup"
}
