@echo off
cd /d "%~dp0functions"
if not exist node_modules (
  call npm install --no-audit --no-fund
  if errorlevel 1 exit /b 1
)
echo Lab 7: keep this window open to send registration push notifications.
call npm start
pause
