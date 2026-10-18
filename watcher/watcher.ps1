# ============================================================
#  さなくり 無音印刷 watcher  v1.5  (2026-10-19)
#  ダウンロードフォルダに sanakuri_kaikei_*.pdf / *.kpdf が来たら
#  SumatraPDF で A5 印刷し、printed\ へ移動する。
#  タスクトレイに常駐（右クリックで終了・ログ表示）。
#  設定は同じフォルダの config.txt。
# ============================================================
$ErrorActionPreference = 'Stop'
$Base = Split-Path -Parent $MyInvocation.MyCommand.Path
$WatcherVersion = '1.5'

# ---- 二重起動防止 ----
$mutex = New-Object System.Threading.Mutex($false, 'Local\SanakuriKaikeiWatcher')
if (-not $mutex.WaitOne(0)) { exit }

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# ---- 設定読込 ----
$cfg = @{ PRINTER=''; PAPER='A5'; PAPERKIND=''; BIN=''; SCALE='shrink'; DOWNLOADS=''; PREFIX='sanakuri_kaikei_'; KEEP_DAYS='60'; SUMATRA='';
          UPDATE_SOURCE='https://raw.githubusercontent.com/torusanada917-stack/sanakuri-print/main/watcher/'; UPDATE_HOURS='6' }
$cfgPath = Join-Path $Base 'config.txt'
if (Test-Path $cfgPath) {
  Get-Content $cfgPath -Encoding UTF8 | ForEach-Object {
    if ($_ -match '^\s*([A-Za-z_]+)\s*=\s*(.*?)\s*$') { $cfg[$matches[1].ToUpper()] = $matches[2] }
  }
}
function Log($msg) {
  $line = (Get-Date -Format 'yyyy-MM-dd HH:mm:ss') + '  ' + $msg
  Add-Content -Path (Join-Path $Base 'log.txt') -Value $line -Encoding UTF8
}

# ---- 自動更新（GitHub または 共有フォルダ）----
$script:restartRequested = $false
function Run-Update() {
  $src = $cfg.UPDATE_SOURCE
  if (-not $src -or $src -match '^(off|none|0)$') { return $false }
  $up = Join-Path $Base 'update.ps1'
  if (-not (Test-Path $up)) { return $false }
  try {
    $r = @(& $up -Base $Base -Source $src)
    return ($r.Count -gt 0 -and $r[-1] -eq $true)
  } catch { Log ("更新チェック失敗: " + $_.Exception.Message); return $false }
}
function Restart-Self() {
  try { $mutex.ReleaseMutex() | Out-Null } catch {}
  try { $mutex.Dispose() } catch {}
  Start-Process 'wscript.exe' -ArgumentList ('"' + (Join-Path $Base 'watcher.vbs') + '"')
}
if (Run-Update) { Log "更新を適用したので再起動します"; Restart-Self; exit }
$updHours = 6; try { $updHours = [double]$cfg.UPDATE_HOURS } catch {}
if ($updHours -le 0) { $updHours = 6 }
$script:nextUpdateCheck = (Get-Date).AddMinutes(10)   # 起動直後はネットワーク未接続の事があるので10分後にもう一度、以後 UPDATE_HOURS ごと

# ---- パス解決 ----
$Downloads = $cfg.DOWNLOADS
if (-not $Downloads) {
  try { $Downloads = (New-Object -ComObject Shell.Application).NameSpace('shell:Downloads').Self.Path } catch {}
  if (-not $Downloads) { $Downloads = Join-Path $env:USERPROFILE 'Downloads' }
}
$Sumatra = $cfg.SUMATRA
if (-not $Sumatra) { $Sumatra = Join-Path $Base 'SumatraPDF.exe' }
$PrintedDir = Join-Path $Base 'printed'
$FailedDir  = Join-Path $Base 'failed'
New-Item -ItemType Directory -Force -Path $PrintedDir, $FailedDir | Out-Null

if (-not (Test-Path $Sumatra)) {
  [System.Windows.Forms.MessageBox]::Show("SumatraPDF.exe が見つかりません:`n$Sumatra`n`nREADME.txt の手順で SumatraPDF（ポータブル版）を置いてください。", "さなくり会計印刷", 'OK', 'Error') | Out-Null
  exit 1
}
if (-not (Test-Path $Downloads)) {
  [System.Windows.Forms.MessageBox]::Show("ダウンロードフォルダが見つかりません:`n$Downloads", "さなくり会計印刷", 'OK', 'Error') | Out-Null
  exit 1
}

# ---- トレイアイコン ----
$tray = New-Object System.Windows.Forms.NotifyIcon
try { $tray.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon($Sumatra) } catch { $tray.Icon = [System.Drawing.SystemIcons]::Application }
$printerLabel = if ($cfg.PRINTER) { $cfg.PRINTER } else { '通常使うプリンター' }
$tray.Text = ('さなくり無音印刷 v' + $WatcherVersion + ' 稼働中')
$menu = New-Object System.Windows.Forms.ContextMenuStrip
$mi = $menu.Items.Add("さなくり無音印刷 v$WatcherVersion"); $mi.Enabled = $false
$mi = $menu.Items.Add("監視中: $Downloads"); $mi.Enabled = $false
$mi = $menu.Items.Add("プリンター: $printerLabel / 用紙: $($cfg.PAPER)"); $mi.Enabled = $false
$menu.Items.Add('-') | Out-Null
$menu.Items.Add('印刷済みフォルダを開く', $null, { Start-Process explorer.exe $PrintedDir }) | Out-Null
$menu.Items.Add('ログを開く', $null, { Start-Process notepad.exe (Join-Path $Base 'log.txt') }) | Out-Null
$menu.Items.Add('設定(config.txt)を開く', $null, { Start-Process notepad.exe $cfgPath }) | Out-Null
$menu.Items.Add('今すぐ更新を確認', $null, {
  if (Run-Update) { $script:restartRequested = $true; $script:timer.Stop(); $tray.Visible = $false; [System.Windows.Forms.Application]::Exit() }
  else { Notify 'さなくり無音印刷' ('更新はありません（v' + $WatcherVersion + '）。詳細は log.txt') 'Info' }
}) | Out-Null
$menu.Items.Add('-') | Out-Null
$menu.Items.Add('終了', $null, { $script:timer.Stop(); $tray.Visible = $false; [System.Windows.Forms.Application]::Exit() }) | Out-Null
$tray.ContextMenuStrip = $menu
$tray.Visible = $true

function Notify($title, $text, $icon = 'Info') {
  try { $tray.ShowBalloonTip(4000, $title, $text, $icon) } catch {}
}

# ---- 印刷 ----
function Is-Ready([string]$path) {
  if (Test-Path ($path + '.crdownload')) { return $false }
  try {
    $fs = [System.IO.File]::Open($path, 'Open', 'Read', 'None'); $fs.Close(); return $true
  } catch { return $false }
}
function Print-File([string]$path) {
  $settings = @("paper=$($cfg.PAPER)")
  # 用紙を Windows の番号(DMPAPER_*)でも指定（名前がドライバーに通らない場合の保険。A4=9 A5=11 B5=13 letter=1）
  $kind = $cfg.PAPERKIND
  if (-not $kind) { $kind = @{ 'A4'='9'; 'A5'='11'; 'B5'='13'; 'LETTER'='1'; 'A3'='8'; 'B4'='12' }[$cfg.PAPER.ToUpper()] }
  if ($kind) { $settings += "paperkind=$kind" }
  if ($cfg.BIN)   { $settings += "bin=$($cfg.BIN)" }
  if ($cfg.SCALE) { $settings += $cfg.SCALE }
  $argList = @()
  if ($cfg.PRINTER) { $argList += @('-print-to', ('"' + $cfg.PRINTER + '"')) } else { $argList += '-print-to-default' }
  $argList += @('-print-settings', ('"' + ($settings -join ',') + '"'), '-silent', ('"' + $path + '"'))
  $p = Start-Process -FilePath $Sumatra -ArgumentList $argList -WindowStyle Hidden -PassThru
  if (-not $p.WaitForExit(90000)) { try { $p.Kill() } catch {}; Log "印刷タイムアウト(90秒) → 強制終了"; return 999 }
  return $p.ExitCode
}

$script:busy = $false
$script:lastCleanup = [DateTime]::MinValue
$script:printedNames = @{}   # 印刷済みだが移動待ちのファイル（二重印刷防止）
function Move-WithRetry([string]$src, [string]$dst) {
  for ($i = 0; $i -lt 30; $i++) {
    try { Move-Item -Path $src -Destination $dst -Force -ErrorAction Stop; return $true } catch { Start-Sleep -Milliseconds 500 }
  }
  return $false
}
function Scan() {
  if ($script:busy) { return }
  $script:busy = $true
  try {
    $files = @(Get-ChildItem -Path $Downloads -Filter ($cfg.PREFIX + '*') -File -ErrorAction SilentlyContinue |
             Where-Object { $_.Extension -in '.pdf', '.kpdf' } | Sort-Object LastWriteTime)
    foreach ($f in $files) {
      $monthDir = Join-Path $PrintedDir (Get-Date -Format 'yyyy-MM')
      New-Item -ItemType Directory -Force -Path $monthDir | Out-Null
      if ($script:printedNames.ContainsKey($f.Name)) {
        # 印刷済み・移動だけ残っている
        if (Move-WithRetry $f.FullName (Join-Path $monthDir $f.Name)) { $script:printedNames.Remove($f.Name); Log "移動OK  $($f.Name)" }
        continue
      }
      if (-not (Is-Ready $f.FullName)) { continue }
      if ($f.Length -lt 100) { continue }
      Start-Sleep -Milliseconds 300
      if ($f.Length -ne (Get-Item $f.FullName).Length) { continue }   # まだ書き込み中
      $code = Print-File $f.FullName
      if ($code -eq 0) {
        $script:printedNames[$f.Name] = $true
        Log "印刷OK  $($f.Name)"
        if (Move-WithRetry $f.FullName (Join-Path $monthDir $f.Name)) { $script:printedNames.Remove($f.Name) }
        else { Log "移動待ち（ファイルが使用中）  $($f.Name)" }
      } else {
        Log "印刷失敗(code=$code)  $($f.Name)"
        if (-not (Move-WithRetry $f.FullName (Join-Path $FailedDir $f.Name))) { $script:printedNames[$f.Name] = $true }
        Notify '会計印刷に失敗しました' "$($f.Name)`nfailed フォルダに移動しました。プリンターの電源・用紙を確認してください。" 'Error'
      }
    }
    # 定期的に更新を確認（印刷待ちが無い時だけ）。更新があれば再起動
    if ($files.Count -eq 0 -and (Get-Date) -gt $script:nextUpdateCheck) {
      $script:nextUpdateCheck = (Get-Date).AddHours($updHours)
      if (Run-Update) { $script:restartRequested = $true; $script:timer.Stop(); $tray.Visible = $false; [System.Windows.Forms.Application]::Exit(); return }
    }
    # 1日1回、古い printed を削除
    if ((Get-Date) - $script:lastCleanup -gt [TimeSpan]::FromHours(24)) {
      $script:lastCleanup = Get-Date
      $keep = [int]$cfg.KEEP_DAYS
      if ($keep -gt 0) {
        Get-ChildItem -Path $PrintedDir -Recurse -File -ErrorAction SilentlyContinue |
          Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-$keep) } |
          Remove-Item -Force -ErrorAction SilentlyContinue
      }
    }
  } catch {
    Log ("エラー: " + $_.Exception.Message)
  } finally { $script:busy = $false }
}

Log "起動 v$WatcherVersion  監視=$Downloads  printer=$printerLabel  paper=$($cfg.PAPER)"
$script:timer = New-Object System.Windows.Forms.Timer
$script:timer.Interval = 1000
$script:timer.Add_Tick({ Scan })
$script:timer.Start()
Scan
[System.Windows.Forms.Application]::Run()
$tray.Dispose()
if ($script:restartRequested) { Log "更新を適用したので再起動します"; Restart-Self; exit }
$mutex.ReleaseMutex() | Out-Null
