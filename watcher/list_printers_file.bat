@echo off
rem プリンター一覧を printers.txt に書き出してメモ帳で開く（config.txt の PRINTER= に使う名前の確認用）
cd /d "%~dp0"
set "OUT=%~dp0printers.txt"
echo === プリンター一覧 === > "%OUT%"
if exist "%WINDIR%\System32\Printing_Admin_Scripts\ja-JP\prnmngr.vbs" (
  cscript //nologo "%WINDIR%\System32\Printing_Admin_Scripts\ja-JP\prnmngr.vbs" -l >> "%OUT%" 2>&1
) else if exist "%WINDIR%\System32\Printing_Admin_Scripts\en-US\prnmngr.vbs" (
  cscript //nologo "%WINDIR%\System32\Printing_Admin_Scripts\en-US\prnmngr.vbs" -l >> "%OUT%" 2>&1
)
echo. >> "%OUT%"
echo === （参考）登録されているプリンター名 === >> "%OUT%"
reg query "HKCU\Software\Microsoft\Windows NT\CurrentVersion\Devices" >> "%OUT%" 2>&1
start "" notepad.exe "%OUT%"
