@echo off
rem さなくり 無音印刷  新しいPCへの導入。ダブルクリックするだけ（C:\sanakuri に入ります）
set BASE=C:\sanakuri
if not exist "%BASE%" mkdir "%BASE%"
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "[Net.ServicePointManager]::SecurityProtocol='Tls12'; Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/torusanada917-stack/sanakuri-print/main/watcher/install.ps1' -OutFile '%BASE%\install.ps1' -UseBasicParsing"
if not exist "%BASE%\install.ps1" (
  echo install.ps1 のダウンロードに失敗しました。インターネット接続を確認してください。
  pause
  exit /b 1
)
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%BASE%\install.ps1"
pause
