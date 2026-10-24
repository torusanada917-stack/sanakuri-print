@echo off
rem 今すぐ更新を確認する（通常は自動なので不要。結果は log.txt）
cd /d "%~dp0"
echo.> "%~dp0update.flag"
echo 常駐に「今すぐ更新確認」を指示しました。更新があれば自動で再起動します（結果は log.txt）。
timeout /t 3 >nul
