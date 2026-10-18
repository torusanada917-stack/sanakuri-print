# watcher を起動する（すでに動いていれば二重起動せず何もしない）
$Base = Split-Path -Parent $MyInvocation.MyCommand.Path
Start-Process 'wscript.exe' -ArgumentList ('"' + (Join-Path $Base 'watcher.vbs') + '"')
Add-Content -Path (Join-Path $Base 'setup_log.txt') -Value ((Get-Date -Format 'HH:mm:ss') + ' start watcher requested') -Encoding UTF8
