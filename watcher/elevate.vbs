' PowerShell スクリプトを「管理者として実行」する（UAC の確認「はい/いいえ」が出ます）
' 使い方: wscript elevate.vbs <スクリプト.ps1> [引数...]
Set sh = CreateObject("Shell.Application")
Set a = WScript.Arguments
If a.Count < 1 Then
  MsgBox "使い方: elevate.vbs <スクリプト.ps1> [引数...]", 48, "さなくり無音印刷"
  WScript.Quit 1
End If
args = "-NoProfile -ExecutionPolicy Bypass -NoExit -File """ & a(0) & """"
For i = 1 To a.Count - 1
  args = args & " " & a(i)
Next
sh.ShellExecute "powershell.exe", args, "", "runas", 1
