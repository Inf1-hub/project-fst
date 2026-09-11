@echo off
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0tools\godot.ps1" run
if errorlevel 1 pause
