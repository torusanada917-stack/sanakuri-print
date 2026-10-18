# ============================================================
#  さなくり 無音印刷  新しいPCへの導入（install.bat から呼ばれる）
#  1) GitHub から最新ファイル一式を C:\sanakuri に取得
#  2) SumatraPDF（無料・インストール不要）を取得
#  3) setup.ps1 -Auto（フォルダ作成・Chrome自動DL許可・スタートアップ登録・常駐起動）
#  Tampermonkey のスクリプト導入は手動（README 手順）
# ============================================================
param([string]$Base = 'C:\sanakuri')
$ErrorActionPreference = 'Continue'
$ProgressPreference = 'SilentlyContinue'
try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 } catch {}
$Source = 'https://raw.githubusercontent.com/torusanada917-stack/sanakuri-print/main/watcher/'
New-Item -ItemType Directory -Force -Path $Base | Out-Null
$log = Join-Path $Base 'setup_log.txt'
function L($m){ Write-Host $m; Add-Content -Path $log -Value ((Get-Date -Format 'HH:mm:ss') + ' ' + $m) -Encoding UTF8 }
L "=== さなくり 無音印刷 導入 ($Base) ==="

L "[1/3] GitHub からファイル一式を取得"
Invoke-WebRequest -Uri ($Source + 'update.ps1?t=' + [DateTimeOffset]::Now.ToUnixTimeSeconds()) -OutFile (Join-Path $Base 'update.ps1') -UseBasicParsing -TimeoutSec 60
$r = @(& (Join-Path $Base 'update.ps1') -Base $Base -Source $Source -Force)
if (-not ($r.Count -gt 0 -and $r[-1] -eq $true)) { L "!! 取得に失敗しました。インターネット接続を確認して install.bat をもう一度実行してください（詳細: log.txt）"; Read-Host 'Enter で閉じる'; exit 1 }
L ("  -> v" + (Get-Content (Join-Path $Base 'VERSION.txt') -Raw).Trim())

L "[2/3] SumatraPDF を取得"
if (-not (Test-Path (Join-Path $Base 'SumatraPDF.exe'))) {
  & (Join-Path $Base 'get_sumatra.ps1')
}
if (-not (Test-Path (Join-Path $Base 'SumatraPDF.exe'))) { L "!! SumatraPDF.exe を取得できませんでした（詳細: setup_log.txt）。get_sumatra.bat をもう一度実行してください"; Read-Host 'Enter で閉じる'; exit 1 }
L "  -> OK"

L "[3/3] セットアップ（Chrome設定・スタートアップ登録・常駐起動）"
& (Join-Path $Base 'setup.ps1') -Auto
Start-Sleep 2
L "完了。タスクトレイ（画面右下 ^）にオレンジのアイコンが出ていれば稼働中です。"
L "次は Chrome に Tampermonkey を入れて、以下のURLを開いてスクリプトをインストールしてください（README 手順5）"
L "  https://raw.githubusercontent.com/torusanada917-stack/sanakuri-print/main/sanakuri_kaikei.user.js"
L "  https://raw.githubusercontent.com/torusanada917-stack/sanakuri-print/main/sanakuri_digisma.user.js"
try { Start-Process 'https://github.com/torusanada917-stack/sanakuri-print#readme' } catch {}
