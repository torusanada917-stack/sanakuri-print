# SumatraPDF 3.6.1 (64-bit portable) を公式サイトから取得して C:\sanakuri\SumatraPDF.exe に置く
$ErrorActionPreference = 'Stop'
$Base = Split-Path -Parent $MyInvocation.MyCommand.Path
$log = Join-Path $Base 'setup_log.txt'
function L($m){ Add-Content -Path $log -Value ((Get-Date -Format 'HH:mm:ss') + ' ' + $m) -Encoding UTF8 }
try {
  [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
  $zip = Join-Path $env:TEMP 'SumatraPDF-3.6.1-64.zip'
  $dir = Join-Path $env:TEMP 'sumatra_extract'
  L 'download start'
  Invoke-WebRequest -Uri 'https://www.sumatrapdfreader.org/dl/rel/3.6.1/SumatraPDF-3.6.1-64.zip' -OutFile $zip -UseBasicParsing
  L ('downloaded ' + (Get-Item $zip).Length + ' bytes')
  if (Test-Path $dir) { Remove-Item $dir -Recurse -Force }
  Expand-Archive -Path $zip -DestinationPath $dir -Force
  $exe = Get-ChildItem $dir -Recurse -Filter '*.exe' | Select-Object -First 1
  if (-not $exe) { throw 'exe not found in zip' }
  Copy-Item $exe.FullName (Join-Path $Base 'SumatraPDF.exe') -Force
  Unblock-File (Join-Path $Base 'SumatraPDF.exe')
  L ('OK SumatraPDF.exe placed: ' + (Get-Item (Join-Path $Base 'SumatraPDF.exe')).Length + ' bytes (from ' + $exe.Name + ')')
} catch {
  L ('ERROR ' + $_.Exception.Message)
}
