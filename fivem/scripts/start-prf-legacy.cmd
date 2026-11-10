@echo off
setlocal EnableExtensions

rem PRF RP Legacy: inicia o MESMO FXServer que o usuario ja instalou.
rem GTA V Enhanced nao e necessario. Nao altere a instalacao do Enhanced.
set "SERVER_BIN=C:\FXServer"
if not exist "%SERVER_BIN%\FXServer.exe" (
  echo [PRF RP Legacy] Arquivo FXServer.exe nao encontrado em %SERVER_BIN%.
  echo Verifique onde extraiu o servidor Legacy e atualize SERVER_BIN neste .cmd.
  pause
  exit /b 1
)

echo [PRF RP Legacy] Iniciando o FXServer existente...
echo [PRF RP Legacy] txAdmin geralmente em http://localhost:40120
echo [PRF RP Legacy] Nao inicie o Enhanced simultaneamente na porta de jogo 30120.
cd /d "%SERVER_BIN%"
"%SERVER_BIN%\FXServer.exe"
exit /b %errorlevel%
