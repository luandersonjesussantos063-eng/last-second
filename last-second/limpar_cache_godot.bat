@echo off
setlocal
cd /d "%~dp0"

echo ==========================================
echo Last Second - Limpeza de cache do Godot
echo ==========================================
echo.

if exist ".godot" (
  echo Fechando possiveis processos do Godot...
  taskkill /IM Godot_v4.7.2-stable_win64.exe /F >nul 2>&1
  taskkill /IM godot.exe /F >nul 2>&1

  echo Apagando a pasta .godot...
  rmdir /S /Q ".godot"

  if exist ".godot" (
    echo.
    echo ERRO: nao foi possivel apagar a pasta .godot.
    echo Feche o Godot completamente e execute este arquivo novamente.
  ) else (
    echo.
    echo Cache apagado com sucesso.
    echo Agora abra o project.godot novamente no Godot.
  )
) else (
  echo A pasta .godot nao existe neste projeto.
  echo O cache ja esta limpo.
)

echo.
pause
endlocal
