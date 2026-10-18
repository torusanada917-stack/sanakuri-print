@echo off
rem 今すぐ更新を確認して、更新があれば常駐を再起動する（通常は自動なので不要）
cd /d "%~dp0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$r=@(& '%~dp0update.ps1' -Base '%~dp0.' ); if ($r[-1] -eq $true) { Write-Host '更新しました。トレイのアイコン右クリック→終了 のあと start_watcher.bat で再起動してください（常駐側も6時間以内に自動で再起動します）' } else { Write-Host '更新はありません（詳細 log.txt）' }"
pause
