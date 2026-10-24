# ============================================================
#  さなくり 無音印刷 セットアップ v1.6（setup.bat / setup_auto.bat / install.ps1 から呼ばれる）
#  ・管理者として実行されていれば タスク スケジューラ（ログオン時・最上位の特権）に登録する
#      → 受付PCのように「一般権限では PowerShell 禁止」のPCでも常駐が動く
#  ・管理者でなければ 従来どおり スタートアップのショートカットで登録する（診察室PC方式）
# ============================================================
param([switch]$Auto)
$ErrorActionPreference = 'Continue'
$Base = Split-Path -Parent $MyInvocation.MyCommand.Path
$log = Join-Path $Base 'setup_log.txt'
$TaskName = 'SanakuriWatcher'
function L($m){ Write-Host $m; Add-Content -Path $log -Value ((Get-Date -Format 'HH:mm:ss') + ' ' + $m) -Encoding UTF8 }
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
L "=== さなくり 無音印刷 セットアップ v1.6 ($Base)  管理者=$isAdmin ==="

L "[1/4] フォルダ作成・設定ファイル"
New-Item -ItemType Directory -Force -Path (Join-Path $Base 'printed'), (Join-Path $Base 'failed') | Out-Null
if (-not (Test-Path (Join-Path $Base 'config.txt')) -and (Test-Path (Join-Path $Base 'config.default.txt'))) {
  Copy-Item (Join-Path $Base 'config.default.txt') (Join-Path $Base 'config.txt'); L "  -> config.txt を作成（ひな形から）"
}

L "[2/4] Chrome: digikar.jp / console.digikar-smart.jp からの自動ダウンロードを許可"
New-Item -Path 'HKCU:\SOFTWARE\Policies\Google\Chrome\AutomaticDownloadsAllowedForUrls' -Force | Out-Null
Set-ItemProperty -Path 'HKCU:\SOFTWARE\Policies\Google\Chrome\AutomaticDownloadsAllowedForUrls' -Name '1' -Value 'https://digikar.jp'
Set-ItemProperty -Path 'HKCU:\SOFTWARE\Policies\Google\Chrome\AutomaticDownloadsAllowedForUrls' -Name '2' -Value 'https://console.digikar-smart.jp'

L "[3/4] 自動起動の登録"
$lnk = Join-Path ([Environment]::GetFolderPath('Startup')) 'さなくり会計印刷.lnk'
$vbs = Join-Path $Base 'watcher.vbs'
$registeredTask = $false
if ($isAdmin) {
  try {
    $user      = "$env:USERDOMAIN\$env:USERNAME"
    $action    = New-ScheduledTaskAction -Execute 'wscript.exe' -Argument ('"' + $vbs + '"') -WorkingDirectory $Base
    $trigger   = New-ScheduledTaskTrigger -AtLogOn -User $user
    $principal = New-ScheduledTaskPrincipal -UserId $user -LogonType Interactive -RunLevel Highest
    $settings  = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -MultipleInstances Parallel
    Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Description 'さなくり 無音印刷 常駐（ログオン時に起動・最上位の特権）' -Force | Out-Null
    try { $t = Get-ScheduledTask -TaskName $TaskName; $t.Settings.ExecutionTimeLimit = 'PT0S'; Set-ScheduledTask -InputObject $t | Out-Null } catch { L ("  (実行時間制限の解除に失敗: " + $_.Exception.Message + ")") }
    $registeredTask = $true
    L "  -> タスク スケジューラ '$TaskName'（$user のログオン時・最上位の特権）に登録"
    if (Test-Path $lnk) { Remove-Item $lnk -Force -ErrorAction SilentlyContinue; L "  -> 旧スタートアップのショートカットを削除" }
  } catch { L ("  !! タスク登録に失敗: " + $_.Exception.Message + " → スタートアップで登録します") }
}
if (-not $registeredTask) {
  $s = (New-Object -ComObject WScript.Shell).CreateShortcut($lnk)
  $s.TargetPath = 'wscript.exe'
  $s.Arguments = '"' + $vbs + '"'
  $s.WorkingDirectory = $Base
  $s.Save()
  L ("  -> スタートアップ " + $lnk)
  if (-not $isAdmin) { L "  (注) 一般権限で PowerShell が禁止されているPCでは、PowerShell を「管理者として実行」で開いて setup.ps1 をやり直してください" }
}

L "[4/4] 常駐を起動"
if (-not (Test-Path (Join-Path $Base 'SumatraPDF.exe'))) {
  L "!! SumatraPDF.exe がありません。get_sumatra.bat を実行してから setup をもう一度行ってください。"
  if (-not $Auto) { Read-Host "Enter で閉じる" }
  exit 1
}
if ($registeredTask) { Start-ScheduledTask -TaskName $TaskName } else { Start-Process 'wscript.exe' -ArgumentList ('"' + $vbs + '"') }
Start-Sleep 3
L "完了。タスクトレイ（画面右下 ^）にオレンジのアイコンが出ていれば稼働中です。"
if (-not $Auto) { Read-Host "Enter で閉じる" }
