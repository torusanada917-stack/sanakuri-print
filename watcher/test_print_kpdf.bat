@echo off
cd /d "%~dp0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$dl=(New-Object -ComObject Shell.Application).NameSpace('shell:Downloads').Self.Path; $n='sanakuri_kaikei_test_'+(Get-Date -Format 'yyyyMMdd_HHmmss')+'.kpdf'; Copy-Item '%~dp0test_a5.pdf' (Join-Path $dl $n); Add-Content '%~dp0setup_log.txt' ((Get-Date -Format 'HH:mm:ss')+' test kpdf -> '+(Join-Path $dl $n)); Start-Sleep 2"
