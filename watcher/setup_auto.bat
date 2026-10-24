@echo off
cd /d "%~dp0"
wscript "%~dp0elevate.vbs" "%~dp0setup.ps1" -Auto
