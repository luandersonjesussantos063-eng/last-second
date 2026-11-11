@echo off
setlocal EnableExtensions
set "SCRIPT=%~dp0install-prf-assets.ps1"
if not exist "%SCRIPT%" (
  echo Instalador nao encontrado: %SCRIPT%
  pause
  exit /b 1
)
echo Instalando PRF MAP e Equinox do repositorio ou da pasta Downloads...
echo Nao modifica o GTA V original e nao baixa arquivos de terceiros.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT%"
if errorlevel 1 (
  echo Instalacao interrompida. Confira a mensagem acima.
  pause
  exit /b 1
)
echo Concluido. Va ao txAdmin para iniciar os recursos.
pause
