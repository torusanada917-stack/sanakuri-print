@echo off
cd /d "%~dp0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Get-CimInstance Win32_Printer | Select-Object Name,Default,WorkOffline,PrinterStatus,PortName,DriverName | Format-List | Out-File '%~dp0printers.txt' -Encoding UTF8"
