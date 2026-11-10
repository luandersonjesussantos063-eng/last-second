@echo off
setlocal EnableExtensions
REM Servidor Enhanced separado do FXServer Legacy (nao misture os arquivos).
set "SERVER_BIN=C:\CfxServerEnhanced"
set "TXDATA=C:\txDataEnhanced"

if not exist "%SERVER_BIN%\cfx-server.exe" (
  echo [PRF RP] cfx-server.exe nao encontrado em "%SERVER_BIN%".
  echo Baixe a plataforma "FiveM for GTAV Enhanced" do site oficial,
  echo extraia em C:\CfxServerEnhanced e execute este arquivo novamente.
  pause
  exit /b 1
)

if not exist "%TXDATA%" mkdir "%TXDATA%"
echo [PRF RP] Iniciando servidor Cfx Enhanced com dados isolados em "%TXDATA%".
echo [PRF RP] Painel administrativo: http://localhost:40121
echo [PRF RP] Se o servidor Legacy estiver online na porta 30120, pare-o antes de iniciar o Enhanced.
cd /d "%SERVER_BIN%"
"%SERVER_BIN%\cfx-server.exe" +set txDataPath "%TXDATA%" +set txAdminPort 40121
exit /b %errorlevel%
