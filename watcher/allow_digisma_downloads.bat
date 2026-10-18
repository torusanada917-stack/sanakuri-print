@echo off
reg add "HKCU\SOFTWARE\Policies\Google\Chrome\AutomaticDownloadsAllowedForUrls" /v 2 /t REG_SZ /d "https://console.digikar-smart.jp" /f
reg add "HKCU\SOFTWARE\Policies\Google\Chrome\AutomaticDownloadsAllowedForUrls" /v 1 /t REG_SZ /d "https://digikar.jp" /f
echo done >> "%~dp0setup_log.txt"
