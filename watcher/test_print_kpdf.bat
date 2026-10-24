@echo off
rem テスト印刷：テスト用PDFを「ダウンロード」フォルダに sanakuri_kaikei_test_*.kpdf として置く → 常駐が拾って印刷する
cd /d "%~dp0"
set "DL="
for /f "tokens=2*" %%a in ('reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" /v {374DE290-123F-4565-9164-39C4925E467B} 2^>nul') do set "DL=%%b"
if defined DL call set "DL=%DL%"
if not defined DL set "DL=%USERPROFILE%\Downloads"
set "NAME=sanakuri_kaikei_test_%RANDOM%%RANDOM%.kpdf"
copy /y "%~dp0test_a5.pdf" "%DL%\%NAME%" >nul
if errorlevel 1 (
  echo コピーに失敗しました: %DL%
  pause
  exit /b 1
)
echo テストPDFを置きました: %DL%\%NAME%
echo 常駐が動いていれば数秒でプリンターから出ます（記録は log.txt）
timeout /t 5 >nul
