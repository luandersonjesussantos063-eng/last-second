@echo off
setlocal EnableExtensions
echo Instalando farda PRF para o FiveM Legacy...
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0install-prf-skin.ps1"
if errorlevel 1 (
  echo Falha: verifique o ZIP/RAR em Downloads.
  pause
  exit /b 1
)
echo Instalacao concluida. Execute refresh, ensure prf_skin_replace e restart prf_core no txAdmin.
pause
