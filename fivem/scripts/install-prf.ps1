# Instalador local do PRF RP para servidor ja criado pelo txAdmin.
# Exemplo: powershell -ExecutionPolicy Bypass -File .\fivem\scripts\install-prf.ps1 -ServerDataPath "C:\txData\FiveMBasicServerCFXDefault_F3288B.base"
[CmdletBinding()]
param(
  [Parameter(Mandatory = $true)]
  [ValidateNotNullOrEmpty()]
  [string]$ServerDataPath,
  [switch]$LocalTestEveryone
)
$ErrorActionPreference = 'Stop'

$serverFolder = [System.IO.Path]::GetFullPath($ServerDataPath)
$cfg = [System.IO.Path]::Combine($serverFolder, 'server.cfg')
if (-not [System.IO.File]::Exists($cfg)) {
  throw "server.cfg nao encontrado em $serverFolder . Primeiro crie o servidor com txAdmin."
}

$src = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine(
  $PSScriptRoot, '..', 'resources', '[prf]', 'prf_core'
))
if (-not [System.IO.File]::Exists([System.IO.Path]::Combine($src, 'fxmanifest.lua'))) {
  throw "Pacote prf_core nao encontrado em $src"
}

$dst = [System.IO.Path]::Combine($serverFolder, 'resources', '[prf]', 'prf_core')
[System.IO.Directory]::CreateDirectory($dst) | Out-Null

# Copia apenas arquivos esperados. Nao altera nem apaga outros resources.
$names = @('fxmanifest.lua', 'config.lua', 'client.lua', 'base_client.lua', 'keys_client.lua', 'squad_client.lua', 'server.lua')
foreach ($name in $names) {
  if (-not [System.IO.File]::Exists([System.IO.Path]::Combine($src, $name))) {
    throw "Arquivo obrigatório ausente: $name"
  }
}
foreach ($name in $names) {
  [System.IO.File]::Copy(
    [System.IO.Path]::Combine($src, $name),
    [System.IO.Path]::Combine($dst, $name),
    $true
  )
}

$assetInstaller = [System.IO.Path]::Combine($PSScriptRoot, 'install-prf-assets.ps1')
if (-not [System.IO.File]::Exists($assetInstaller)) {
  throw 'Pacote incompleto: falta fivem/scripts/install-prf-assets.ps1. Extraia o pacote completo antes de instalar.'
}
& $assetInstaller -ServerDataPath $serverFolder

$contents = [System.IO.File]::ReadAllText($cfg)
$changes = @()
if ($contents -notmatch '(?im)^\s*ensure\s+prf_core\s*$') {
  $changes += 'ensure prf_core'
}
if ($LocalTestEveryone -and $contents -notmatch '(?im)^\s*add_ace\s+builtin\.everyone\s+prfrp\.officer\s+allow\s*$') {
  $changes += 'add_ace builtin.everyone prfrp.officer allow'
  Write-Warning 'Modo livre habilitado: QUALQUER JOGADOR podera entrar em servico. Use SOMENTE em servidor local privado.'
}
if ($changes.Count -gt 0) {
  $backup = "$cfg.bak-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
  [System.IO.File]::Copy($cfg, $backup, $true)
  [System.IO.File]::AppendAllText(
    $cfg,
    [Environment]::NewLine + '# PRF RP - Nova Byte' +
      [Environment]::NewLine + ($changes -join [Environment]::NewLine) +
      [Environment]::NewLine,
    [System.Text.Encoding]::UTF8
  )
  Write-Host "Configuracao atualizada; backup: $backup"
}

Write-Host "PRF RP instalado em $dst"
Write-Host 'Reinicie o servidor no txAdmin para carregar o core e os mods instalados.'
if (-not $LocalTestEveryone -and $contents -notmatch 'prfrp\.officer') {
  Write-Warning 'Antes de usar, adicione no server.cfg: add_ace identifier.fivem:SEU_ID prfrp.officer allow'
  Write-Warning 'Nao envie seu identificador pessoal ou chave cfxk_ em chats ou commits.'
}
