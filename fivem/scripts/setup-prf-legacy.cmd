@echo off
setlocal EnableExtensions

rem Instalador PRF RP Legacy para o perfil txAdmin que voce ja criou.
rem Nao instala FXServer, nao apaga outros resources e nao autoriza todos.
set "SERVERDATA=C:\txData\FiveMBasicServerCFXDefault_F3288B.base"
set "SCRIPT=%~dp0install-prf.ps1"

if not exist "%SCRIPT%" (
  echo [PRF RP Legacy] O arquivo install-prf.ps1 precisa ficar nesta mesma pasta.
  pause
  exit /b 1
)
if not exist "%SERVERDATA%\server.cfg" (
  echo [PRF RP Legacy] Nao encontrei server.cfg no perfil esperado:
  echo %SERVERDATA%
  echo Confira a pasta de dados no txAdmin e ajuste SERVERDATA neste arquivo.
  echo Nada foi copiado nem alterado.
  pause
  exit /b 1
)

echo [PRF RP Legacy] Copiando o prf_core para o servidor Legacy existente.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT%" -ServerDataPath "%SERVERDATA%"
if errorlevel 1 (
  echo [PRF RP Legacy] Instalacao interrompida. Confira a mensagem acima.
  pause
  exit /b 1
)

echo.
echo [PRF RP Legacy] PRONTO. No Live Console do txAdmin execute:
echo   refresh
echo Depois pressione Enter e digite em uma NOVA linha:
echo   ensure prf_core
echo.
echo A permissao PRF e configurada individualmente no server.cfg.
pause
exit /b 0
