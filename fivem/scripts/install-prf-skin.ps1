# Instala o skin PRF que o usuario enviou: modelo replace s_m_y_sheriff_01.
# O pacote original (Mr.KobraX) nao e redistribuido pelo repositorio.
[CmdletBinding()]
param(
  [string]$ServerDataPath = 'C:\txData\FiveMBasicServerCFXDefault_F3288B.base',
  [string]$SkinZip = '',
  [string]$SkinRar = '',
  [switch]$Optional
)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression.FileSystem

function Locate([string[]]$patterns, [string]$given) {
  if ($given) {
    if (-not [IO.File]::Exists($given)) { throw "Arquivo inexistente: $given" }
    return [IO.Path]::GetFullPath($given)
  }
  $downloads = Join-Path $env:USERPROFILE 'Downloads'
  if (-not (Test-Path -LiteralPath $downloads)) { return $null }
  foreach ($pattern in $patterns) {
    $files = @(Get-ChildItem -LiteralPath $downloads -File |
      Where-Object { $_.Name -like $pattern } |
      Sort-Object LastWriteTime -Descending)
    if ($files.Count) { return $files[0].FullName }
  }
  return $null
}

function ExtractRar([string]$rar, [string]$folder) {
  [IO.Directory]::CreateDirectory($folder) | Out-Null
  $tar = Get-Command tar.exe -ErrorAction SilentlyContinue
  if ($tar) {
    & $tar.Source '-xf' $rar '-C' $folder
    if ($LASTEXITCODE -eq 0) { return }
  }
  foreach ($exe in @('C:\Program Files\7-Zip\7z.exe',
                     'C:\Program Files (x86)\7-Zip\7z.exe')) {
    if ([IO.File]::Exists($exe)) {
      & $exe 'x' '-y' "-o$folder" $rar | Out-Null
      if ($LASTEXITCODE -eq 0) { return }
    }
  }
  throw 'Nao foi possivel extrair o arquivo RAR. Use o ZIP da farda fornecido ou instale 7-Zip.'
}

$zip = Locate @('*PRF*Farda*FiveM*.zip','*PRF*Skin*FiveM*.zip') $SkinZip
$rar = if (-not $zip) { Locate @('*GTA*Skin*PRF*.rar','*Skin*PRF*.rar') $SkinRar } else { $null }
if (-not $zip -and -not $rar) {
  if ($Optional) {
    Write-Host 'Farda PRF nao encontrada em Downloads; instalacao opcional ignorada.'
    return
  }
  throw 'Coloque PRF_Farda_FiveM_Legacy.zip ou GTA 5 Skin PRF.rar em Downloads.'
}
$server = [IO.Path]::GetFullPath($ServerDataPath)
$cfg = [IO.Path]::Combine($server,'server.cfg')
if (-not [IO.File]::Exists($cfg)) { throw "server.cfg nao encontrado em $server" }

$expected = @{
  's_m_y_sheriff_01.ydd' = '5000f044cfe80df218edcae5dc708d2fe667754c0f4229612f3ad5513dfb5b68'
  's_m_y_sheriff_01.ymt' = '56695b199c43d39c0becc01d53d018a84cca1c40a9fe1d6a97e7f62636286082'
  's_m_y_sheriff_01.ytd' = '02597c94952dc1fd9706e62481369bd23a4ed9779ce214ce36a0fa817afe21d8'
}
$staging = Join-Path ([IO.Path]::GetTempPath()) ('prf-skin-' + [guid]::NewGuid().ToString('N'))
[IO.Directory]::CreateDirectory($staging) | Out-Null
try {
  if ($zip) {
    [IO.Compression.ZipFile]::ExtractToDirectory($zip,$staging)
    $source = [IO.Path]::Combine($staging,'prf_skin_replace','stream')
    if (-not [IO.Directory]::Exists($source)) { throw 'ZIP sem pasta prf_skin_replace/stream.' }
  } else {
    ExtractRar $rar $staging
    $source = [IO.Path]::Combine($staging,'PRF')
    if (-not [IO.Directory]::Exists($source)) {
      throw 'RAR sem pasta PRF contendo s_m_y_sheriff_01.*.'
    }
  }
  foreach ($name in $expected.Keys) {
    $path = [IO.Path]::Combine($source,$name)
    if (-not [IO.File]::Exists($path)) { throw "Falta arquivo da farda: $name" }
    $actual = (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($actual -ne $expected[$name]) { throw "Hash invalido para $name. Arquivo diferente do recebido." }
  }
  $resources = [IO.Path]::Combine($server,'resources','[prf]')
  $dest = [IO.Path]::Combine($resources,'prf_skin_replace')
  [IO.Directory]::CreateDirectory($resources) | Out-Null
  if ([IO.Directory]::Exists($dest)) {
    $backup = "$dest.bak-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    Move-Item -LiteralPath $dest -Destination $backup
    Write-Host "Backup da farda anterior: $backup"
  }
  $stream = [IO.Path]::Combine($dest,'stream')
  [IO.Directory]::CreateDirectory($stream) | Out-Null
  foreach ($name in $expected.Keys) {
    [IO.File]::Copy([IO.Path]::Combine($source,$name),[IO.Path]::Combine($stream,$name),$true)
  }
  $manifest = @'
fx_version 'cerulean'
game 'gta5'
author 'Mr.KobraX (farda); integracao local Nova Byte'
description 'PRF Skin: replace local s_m_y_sheriff_01'
version '1.0.0'
'@
  [IO.File]::WriteAllText([IO.Path]::Combine($dest,'fxmanifest.lua'),$manifest,
    [Text.Encoding]::UTF8)
  $old = [IO.File]::ReadAllText($cfg)
  if ($old -notmatch '(?im)^\s*ensure\s+prf_skin_replace\s*(?:#.*)?$') {
    $backup = "$cfg.bak-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    [IO.File]::Copy($cfg,$backup,$true)
    $beforeCore = '(?im)^(\s*ensure\s+prf_core\b.*)$'
    $replace = 'ensure prf_skin_replace' + [Environment]::NewLine + '$1'
    if ([regex]::IsMatch($old,$beforeCore)) {
      $next = ([regex]::new($beforeCore)).Replace($old,$replace,1)
    } else {
      $next = $old + [Environment]::NewLine + 'ensure prf_skin_replace' +
        [Environment]::NewLine
    }
    [IO.File]::WriteAllText($cfg,$next,[Text.Encoding]::UTF8)
    Write-Host "Backup do server.cfg: $backup"
  }
  Write-Host 'Farda PRF instalada e hashes validados!' -ForegroundColor Green
  Write-Host "Resource: $dest"
  Write-Host 'txAdmin: refresh, ensure prf_skin_replace, restart prf_core.'
  Write-Warning 'REPLACE: esta farda tambem altera outros NPC xerifes s_m_y_sheriff_01 do GTA.'
} finally {
  if ([IO.Directory]::Exists($staging)) {
    Remove-Item -LiteralPath $staging -Recurse -Force -ErrorAction SilentlyContinue
  }
}
