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
$names = @('fxmanifest.lua', 'config.lua', 'operations_config.lua', 'client.lua', 'base_client.lua', 'keys_client.lua', 'squad_client.lua', 'operations_client.lua', 'server.lua', 'operations_server.lua', 'people_client.lua', 'people_server.lua', 'commands_client.lua', 'commands_server.lua', 'backup_client.lua', 'backup_server.lua', 'traffic_client.lua', 'copom_config.lua','copom_client.lua','copom_server.lua','gameplay_config.lua', 'base_stream_client.lua', 'progress_server.lua', 'inventory_client.lua', 'inventory_server.lua', 'tablet_client.lua', 'services_client.lua', 'services_server.lua', 'blitz_client.lua', 'blitz_server.lua', 'html/index.html', 'html/style.css', 'html/app.js')
foreach ($name in $names) {
  if (-not [System.IO.File]::Exists([System.IO.Path]::Combine($src, $name))) {
    throw "Arquivo obrigatório ausente: $name"
  }
}
foreach ($name in $names) {
  [System.IO.Directory]::CreateDirectory([System.IO.Path]::GetDirectoryName([System.IO.Path]::Combine($dst, $name))) | Out-Null
  [System.IO.File]::Copy(
    [System.IO.Path]::Combine($src, $name),
    [System.IO.Path]::Combine($dst, $name),
    $true
  )
}

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
Write-Host 'No Live Console do txAdmin digite refresh; depois, EM OUTRA LINHA, digite ensure prf_core.'
if (-not $LocalTestEveryone -and $contents -notmatch 'prfrp\.officer') {
  Write-Warning 'Antes de usar, adicione no server.cfg: add_ace identifier.fivem:SEU_ID prfrp.officer allow'
  Write-Warning 'Nao envie seu identificador pessoal ou chave cfxk_ em chats ou commits.'
}
