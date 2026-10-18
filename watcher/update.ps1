# ============================================================
#  さなくり 無音印刷  自動更新  v1.5
#  watcher.ps1 / install.ps1 から呼ばれる。更新元（GitHub または共有フォルダ）の
#  VERSION.txt がローカルより新しければ manifest.txt のファイルを取得して置き換える。
#  config.txt / SumatraPDF.exe / log / printed / failed は触らない。
#  戻り値: $true = 更新した,  $false = 更新なし または 失敗（log.txt に理由）
# ============================================================
param(
  [string]$Base = (Split-Path -Parent $MyInvocation.MyCommand.Path),
  [string]$Source = 'https://raw.githubusercontent.com/torusanada917-stack/sanakuri-print/main/watcher/',
  [switch]$Force
)
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 } catch {}
function ULog($m) { try { Add-Content -Path (Join-Path $Base 'log.txt') -Value ((Get-Date -Format 'yyyy-MM-dd HH:mm:ss') + '  [更新] ' + $m) -Encoding UTF8 } catch {} }
function V($s) { try { return [version]$s.Trim() } catch { return [version]'0.0' } }

$isUrl = ($Source -match '^https?://')
if ($isUrl -and -not $Source.EndsWith('/')) { $Source += '/' }
function Fetch-Text([string]$name) {
  if ($isUrl) { return (Invoke-WebRequest -Uri ($Source + $name + '?t=' + [DateTimeOffset]::Now.ToUnixTimeSeconds()) -UseBasicParsing -TimeoutSec 15).Content }
  return (Get-Content -Path (Join-Path $Source $name) -Raw -Encoding UTF8)
}
function Fetch-File([string]$name, [string]$dest) {
  if ($isUrl) { Invoke-WebRequest -Uri ($Source + $name + '?t=' + [DateTimeOffset]::Now.ToUnixTimeSeconds()) -OutFile $dest -UseBasicParsing -TimeoutSec 60 }
  else { Copy-Item -Path (Join-Path $Source $name) -Destination $dest -Force }
  try { Unblock-File -Path $dest -ErrorAction SilentlyContinue } catch {}
}

try {
  if (-not $isUrl -and -not (Test-Path $Source)) { ULog "更新元に到達できません: $Source"; return $false }
  $vp = Join-Path $Base 'VERSION.txt'
  $localV = '0.0'
  if (Test-Path $vp) { $localV = (Get-Content $vp -Raw).Trim() }
  $remoteV = (Fetch-Text 'VERSION.txt').Trim()
  if (-not $Force -and ((V $remoteV) -le (V $localV))) { return $false }

  $files = @((Fetch-Text 'manifest.txt') -split "`r?`n" | ForEach-Object { $_.Trim() } | Where-Object { $_ -and -not $_.StartsWith('#') })
  if ($files.Count -lt 3) { ULog "manifest.txt が不正です"; return $false }

  $tmp = Join-Path $Base '_update'
  if (Test-Path $tmp) { Remove-Item $tmp -Recurse -Force }
  New-Item -ItemType Directory -Path $tmp | Out-Null
  foreach ($f in $files) { Fetch-File $f (Join-Path $tmp $f) }     # 全部取れてから置き換える（途中失敗なら何も変えない）

  foreach ($f in $files) {
    Copy-Item -Path (Join-Path $tmp $f) -Destination (Join-Path $Base $f) -Force
  }
  if (-not (Test-Path (Join-Path $Base 'config.txt')) -and (Test-Path (Join-Path $Base 'config.default.txt'))) {
    Copy-Item -Path (Join-Path $Base 'config.default.txt') -Destination (Join-Path $Base 'config.txt')
  }
  Set-Content -Path $vp -Value $remoteV -Encoding ASCII
  Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue
  ULog "更新 $localV → $remoteV （$($files.Count) ファイル, 元=$Source）"
  return $true
} catch {
  ULog ("失敗: " + $_.Exception.Message)
  return $false
}
