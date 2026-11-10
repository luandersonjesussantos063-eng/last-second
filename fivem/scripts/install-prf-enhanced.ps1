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
$names = @('fxmanifest.lua', 'config.lua', 'client.lua', 'server.lua')

foreach ($name in $names) {
  $sourceFile = [System.IO.Path]::Combine($source, $name)
  if (-not [System.IO.File]::Exists($sourceFile)) {
    throw "Falta o arquivo original: $sourceFile"
  }
}
[System.IO.Directory]::CreateDirectory($target) | Out-Null
foreach ($name in $names) {
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
