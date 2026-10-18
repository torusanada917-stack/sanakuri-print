@echo off
cd /d "%~dp0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Remove-Item -LiteralPath ([Environment]::GetFolderPath('Startup') + '\さなくり会計印刷.lnk') -ErrorAction SilentlyContinue; Remove-Item -Path 'HKCU:\SOFTWARE\Policies\Google\Chrome\AutomaticDownloadsAllowedForUrls' -Recurse -ErrorAction SilentlyContinue; Write-Host 'スタートアップ登録と Chrome の設定を削除しました。トレイのアイコンは右クリック→終了 で止めてください。'; Read-Host 'Enter で閉じる'"
