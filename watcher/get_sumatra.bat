@echo off
cd /d "%~dp0"
wscript "%~dp0elevate.vbs" "%~dp0get_sumatra.ps1"
