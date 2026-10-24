@echo off
rem 自動起動の登録と Chrome の設定を解除する（ファイルは残る）。常駐自体はトレイのアイコン右クリック→終了 で止める
cd /d "%~dp0"
del "%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\さなくり会計印刷.lnk" >nul 2>&1
schtasks /delete /tn SanakuriWatcher /f >nul 2>&1
reg delete "HKCU\SOFTWARE\Policies\Google\Chrome\AutomaticDownloadsAllowedForUrls" /f >nul 2>&1
echo 解除しました（タスク登録が残る場合は、このファイルを右クリック→管理者として実行）。
echo トレイのアイコンは右クリック→終了 で止めてください。
pause
