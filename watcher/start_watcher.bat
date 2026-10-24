@echo off
rem 常駐を起動する（すでに動いていれば二重起動せず何もしない）
cd /d "%~dp0"
schtasks /query /tn SanakuriWatcher >nul 2>&1
if %errorlevel%==0 (
  schtasks /run /tn SanakuriWatcher >nul
) else (
  start "" wscript.exe "%~dp0watcher.vbs"
)
echo 起動を指示しました。画面右下のトレイ（^）にオレンジのアイコンが出れば稼働中です。
timeout /t 3 >nul
