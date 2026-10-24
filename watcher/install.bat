@echo off
rem さなくり 無音印刷  新しいPCへの導入。ダブルクリックするだけ（C:\sanakuri に入ります）
set BASE=C:\sanakuri
set RAW=https://raw.githubusercontent.com/torusanada917-stack/sanakuri-print/main/watcher
if not exist "%BASE%" mkdir "%BASE%"
curl.exe -sSL -o "%BASE%\install.ps1" "%RAW%/install.ps1"
curl.exe -sSL -o "%BASE%\elevate.vbs" "%RAW%/elevate.vbs"
if not exist "%BASE%\install.ps1" (
  echo ダウンロードに失敗しました。インターネット接続を確認してください。
  pause
  exit /b 1
)
echo 「このアプリがデバイスに変更を加えることを許可しますか」が出たら「はい」を押してください。
wscript "%BASE%\elevate.vbs" "%BASE%\install.ps1"
