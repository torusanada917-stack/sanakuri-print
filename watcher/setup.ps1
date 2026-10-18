# さなくり 会計印刷 セットアップ（setup.bat / setup_auto.bat から呼ばれる）
param([switch]$Auto)
$ErrorActionPreference = 'Continue'
$Base = Split-Path -Parent $MyInvocation.MyCommand.Path
$log = Join-Path $Base 'setup_log.txt'
function L($m){ Write-Host $m; Add-Content -Path $log -Value ((Get-Date -Format 'HH:mm:ss') + ' ' + $m) -Encoding UTF8 }
L "=== さなくり 会計印刷 セットアップ ($Base) ==="

L "[1/4] フォルダ作成"
New-Item -ItemType Directory -Force -Path (Join-Path $Base 'printed'), (Join-Path $Base 'failed') | Out-Null

L "[2/4] Chrome: digikar.jp / console.digikar-smart.jp からの自動ダウンロードを許可"
New-Item -Path 'HKCU:\SOFTWARE\Policies\Google\Chrome\AutomaticDownloadsAllowedForUrls' -Force | Out-Null
Set-ItemProperty -Path 'HKCU:\SOFTWARE\Policies\Google\Chrome\AutomaticDownloadsAllowedForUrls' -Name '1' -Value 'https://digikar.jp'
Set-ItemProperty -Path 'HKCU:\SOFTWARE\Policies\Google\Chrome\AutomaticDownloadsAllowedForUrls' -Name '2' -Value 'https://console.digikar-smart.jp'

L "[3/4] スタートアップに登録"
$lnk = Join-Path ([Environment]::GetFolderPath('Startup')) 'さなくり会計印刷.lnk'
$s = (New-Object -ComObject WScript.Shell).CreateShortcut($lnk)
$s.TargetPath = 'wscript.exe'
$s.Arguments = '"' + (Join-Path $Base 'watcher.vbs') + '"'
$s.WorkingDirectory = $Base
$s.Save()
L ("  -> " + $lnk)

L "[4/4] 監視を起動"
if (-not (Test-Path (Join-Path $Base 'SumatraPDF.exe'))) {
  L "!! SumatraPDF.exe がありません。README.txt 手順2 を行ってから setup.bat を再実行してください。"
  if (-not $Auto) { Start-Process 'https://www.sumatrapdfreader.org/download-free-pdf-viewer'; Read-Host "Enter で閉じる" }
  exit 1
}
Start-Process 'wscript.exe' -ArgumentList ('"' + (Join-Path $Base 'watcher.vbs') + '"')
L "完了。タスクトレイにアイコンが出ていれば稼働中です。"
if (-not $Auto) { Read-Host "Enter で閉じる" } else { Start-Sleep 3 }
