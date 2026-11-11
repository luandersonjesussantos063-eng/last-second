# Instala recursos de terceiros que o usuario ja baixou localmente; nada e republicado no GitHub.
[CmdletBinding()]
param(
  [string]$ServerDataPath = 'C:\txData\FiveMBasicServerCFXDefault_F3288B.base',
  [string]$MapZip = '',
  [string]$EquinoxRar = ''
)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression.FileSystem

function Find-Archive([string]$pattern,[string]$chosen) {
  if ($chosen) {
    if (-not [IO.File]::Exists($chosen)) { throw "Arquivo nao encontrado: $chosen" }
    return [IO.Path]::GetFullPath($chosen)
  }
  $downloads = Join-Path $env:USERPROFILE 'Downloads'
  if (-not (Test-Path -LiteralPath $downloads)) { return $null }
  $matches = @(Get-ChildItem -LiteralPath $downloads -File |
    Where-Object { $_.Name -like $pattern } | Sort-Object LastWriteTime -Descending)
  if ($matches.Count -gt 0) { return $matches[0].FullName }
  return $null
}
function Expand-Rar([string]$rarPath,[string]$folder) {
  New-Item -ItemType Directory -Path $folder -Force | Out-Null
  $tar = Get-Command 'tar.exe' -ErrorAction SilentlyContinue
  if ($tar) {
    & $tar.Source '-xf' $rarPath '-C' $folder
    if ($LASTEXITCODE -eq 0) { return }
    Write-Warning 'tar.exe nao leu o RAR; tentando 7-Zip.'
  }
  foreach ($exe in @('C:\Program Files\7-Zip\7z.exe','C:\Program Files (x86)\7-Zip\7z.exe')) {
    if ([IO.File]::Exists($exe)) {
      & $exe 'x' '-y' "-o$folder" $rarPath | Out-Null
      if ($LASTEXITCODE -eq 0) { return }
    }
  }
  throw 'Falha ao extrair o RAR. Instale 7-Zip ou extraia os arquivos manualmente.'
}
function Backup-Resource([string]$folder) {
  if (Test-Path -LiteralPath $folder) {
    $backup = "$folder.bak-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    Move-Item -LiteralPath $folder -Destination $backup
    Write-Host "Backup do recurso anterior: $backup"
  }
}
$server = [IO.Path]::GetFullPath($ServerDataPath)
$cfg = [IO.Path]::Combine($server,'server.cfg')
if (-not [IO.File]::Exists($cfg)) { throw "server.cfg nao encontrado em $server" }
$map = Find-Archive '*PRF-MAP*.zip' $MapZip
$car = Find-Archive '*Equinox*PRF*.rar' $EquinoxRar
if (-not $map -and -not $car) {
  throw 'Coloque o PRF-MAP*.zip e Equinox*PRF*.rar na pasta Downloads (sem renomear), ou informe -MapZip/-EquinoxRar.'
}
Write-Host "Servidor: $server"
if ($map) { Write-Host "Mapa: $map" }
if ($car) { Write-Host "Equinox: $car" }
$root = Join-Path ([IO.Path]::GetTempPath()) ('prf-assets-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $root -Force | Out-Null
$resources = [IO.Path]::Combine($server,'resources','[prf]')
[IO.Directory]::CreateDirectory($resources) | Out-Null
$installed = @()
try {
  if ($map) {
    $temp = Join-Path $root 'map'
    [IO.Compression.ZipFile]::ExtractToDirectory($map,$temp)
    $source = Join-Path $temp 'prfMiniLN3d3v'
    $manifest = Join-Path $source 'fxmanifest.lua'
    if (-not (Test-Path -LiteralPath $manifest) -or
      -not (Test-Path -LiteralPath (Join-Path $source 'stream'))) {
      throw 'Mapa ZIP invalido: pasta prfMiniLN3d3v com fxmanifest.lua/stream nao encontrada.'
    }
    $types = @(Get-ChildItem -LiteralPath (Join-Path $source 'stream') -File -Filter '*.ytyp')
    if ($types.Count -eq 0) { throw 'Mapa sem arquivos .ytyp.' }
    $content = [IO.File]::ReadAllText($manifest)
    # Mantem dependencia /assetpacks do autor; apenas registra tipos do mapa.
    foreach ($type in $types) {
      $line = "data_file 'DLC_ITYP_REQUEST' 'stream/$($type.Name)'"
      if (-not $content.Contains($line)) { $content += [Environment]::NewLine + $line }
    }
    [IO.File]::WriteAllText($manifest,$content + [Environment]::NewLine,[Text.Encoding]::UTF8)
    $dest = [IO.Path]::Combine($resources,'prfMiniLN3d3v')
    Backup-Resource $dest
    Copy-Item -LiteralPath $source -Destination $dest -Recurse
    $installed += 'prfMiniLN3d3v'
  }
  if ($car) {
    $temp = Join-Path $root 'equinox'
    Expand-Rar $car $temp
    $names = @('police.yft','police_hi.yft','police.ytd','police+hi.ytd')
    $sources = @{}
    foreach ($name in $names) {
      $match = @(Get-ChildItem -LiteralPath $temp -Recurse -File |
        Where-Object { $_.Name -ieq $name })
      if ($match.Count -eq 0) { throw "RAR Equinox incompleto: falta $name" }
      $sources[$name] = $match[0].FullName
    }
    $dest = [IO.Path]::Combine($resources,'prf_equinox_replace')
    Backup-Resource $dest
    $stream = Join-Path $dest 'stream'
    [IO.Directory]::CreateDirectory($stream) | Out-Null
    foreach ($name in $names) {
      [IO.File]::Copy($sources[$name],[IO.Path]::Combine($stream,$name),$true)
    }
    $vehicleManifest = @'
fx_version 'cerulean'
game 'gta5'
author 'Martinelli / Alessandro da Fonseca; integracao local Nova Byte'
description 'Chevrolet Equinox PRF: substitui modelo police original'
version '1.0.0'
'@
    [IO.File]::WriteAllText([IO.Path]::Combine($dest,'fxmanifest.lua'),
      $vehicleManifest,[Text.Encoding]::UTF8)
    $installed += 'prf_equinox_replace'
  }
  if ($installed.Count) {
    $old = [IO.File]::ReadAllText($cfg)
    $next = $old
    foreach ($res in $installed) {
      if ($next -notmatch "(?im)^\s*ensure\s+$([regex]::Escape($res))\s*(?:#.*)?$") {
        $next += [Environment]::NewLine + "ensure $res" + [Environment]::NewLine
      }
    }
    if ($next -ne $old) {
      $backup = "$cfg.bak-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
      [IO.File]::Copy($cfg,$backup,$true)
      [IO.File]::WriteAllText($cfg,$next,[Text.Encoding]::UTF8)
      Write-Host "Backup do server.cfg: $backup"
    }
  }
  Write-Host 'Recursos instalados:' -ForegroundColor Green
  foreach ($res in $installed) { Write-Host "  - $res" }
  Write-Host 'No txAdmin, execute refresh e depois ensure dos recursos instalados.'
  Write-Warning 'Mapa original declara dependency /assetpacks. Se nao iniciar, verifique entitlement e artefatos no Cfx Portal; nao remova essa dependencia.'
  Write-Warning 'Equinox e replace do GTA police, nao um carro addon independente: afeta todos police do GTA.'
  Write-Host 'Reconecte ao FiveM para o mapa e o carro atualizarem.'
} finally {
  if (Test-Path -LiteralPath $root) {
    Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue
  }
}
