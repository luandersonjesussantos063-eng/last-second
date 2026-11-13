# Instala o recurso PRF RP no perfil de dados do Cfx Server Enhanced.
# Nao altera o FXServer Legacy e nunca copia chaves.
[CmdletBinding()]
param(
  [Parameter(Mandatory = $true)]
  [ValidateNotNullOrEmpty()]
  [string]$ServerDataPath
)
$ErrorActionPreference = 'Stop'

$dataRoot = [System.IO.Path]::GetFullPath($ServerDataPath)
$cfg = [System.IO.Path]::Combine($dataRoot, 'server.cfg')
if (-not [System.IO.File]::Exists($cfg)) {
  throw "server.cfg ausente em $dataRoot. Primeiro conclua o assistente txAdmin do Cfx Server Enhanced."
}
$source = [System.IO.Path]::GetFullPath(
  [System.IO.Path]::Combine($PSScriptRoot, '..', 'resources', '[prf]', 'prf_core')
)
$target = [System.IO.Path]::Combine($dataRoot, 'resources', '[prf]', 'prf_core')
$names = @('fxmanifest.lua', 'config.lua', 'operations_config.lua', 'client.lua', 'base_client.lua', 'keys_client.lua', 'squad_client.lua', 'operations_client.lua', 'server.lua', 'operations_server.lua', 'people_client.lua', 'people_server.lua', 'commands_client.lua', 'commands_server.lua', 'backup_client.lua', 'backup_server.lua', 'traffic_client.lua', 'gameplay_config.lua', 'base_stream_client.lua', 'progress_server.lua', 'inventory_client.lua', 'inventory_server.lua', 'tablet_client.lua', 'services_client.lua', 'services_server.lua', 'blitz_client.lua', 'blitz_server.lua', 'html/index.html', 'html/style.css', 'html/app.js')

foreach ($name in $names) {
  $sourceFile = [System.IO.Path]::Combine($source, $name)
  if (-not [System.IO.File]::Exists($sourceFile)) {
    throw "Falta o arquivo original: $sourceFile"
  }
}
[System.IO.Directory]::CreateDirectory($target) | Out-Null
foreach ($name in $names) {
  [System.IO.Directory]::CreateDirectory([System.IO.Path]::GetDirectoryName([System.IO.Path]::Combine($target, $name))) | Out-Null
  [System.IO.File]::Copy(
    [System.IO.Path]::Combine($source, $name),
    [System.IO.Path]::Combine($target, $name),
    $true
  )
}

$contents = [System.IO.File]::ReadAllText($cfg)
if ($contents -notmatch '(?im)^\s*ensure\s+prf_core\s*(?:#.*)?$') {
  $backup = "$cfg.bak-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
  [System.IO.File]::Copy($cfg, $backup, $true)
  [System.IO.File]::AppendAllText(
    $cfg,
    [Environment]::NewLine + '# PRF RP - Nova Byte (Cfx Enhanced)' +
      [Environment]::NewLine + 'ensure prf_core' + [Environment]::NewLine,
    [System.Text.Encoding]::UTF8
  )
  Write-Host "Backup de server.cfg criado: $backup"
}

Write-Host "PRF RP instalado: $target"
Write-Host 'Reinicie o Enhanced no txAdmin ou execute refresh e ensure prf_core, em linhas separadas.'
if ($contents -notmatch '(?im)^\s*add_ace\s+identifier\.(?:fivem|license):[^\s]+\s+prfrp\.officer\s+allow\s*$') {
  Write-Warning 'IMPORTANTE: sem o ACE individual o jogador nao consegue entrar em servico.'
  Write-Host 'Configure LOCALMENTE no server.cfg: add_ace identifier.fivem:SEU_ID prfrp.officer allow'
  Write-Host 'Nunca publique seu identificador, PIN ou chave do Cfx Portal no GitHub.'
}
