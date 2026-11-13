@echo off
setlocal EnableExtensions
set "SERVERDATA=C:\txData\FiveMBasicServerCFXDefault_F3288B.base"
echo [PRF] Atualizacao de teste da base, favela e operacoes.
echo Pare o servidor no txAdmin antes de continuar.
pause
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0install-prf-update.ps1" -ServerDataPath "%SERVERDATA%"
if errorlevel 1 (
  echo [PRF] Instalacao interrompida. Confira a mensagem acima.
  pause
  exit /b 1
)
echo [PRF] Inicie o servidor no txAdmin e reabra o FiveM.
pause
