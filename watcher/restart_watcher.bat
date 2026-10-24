@echo off
rem 常駐を再起動する（config.txt を変えたあと等）。動いていなければ起動する
cd /d "%~dp0"
echo.> "%~dp0restart.flag"
timeout /t 3 >nul
call "%~dp0start_watcher.bat"
