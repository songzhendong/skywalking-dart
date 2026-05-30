@echo off
cd /d "%~dp0.."
git reset --hard eec85b3
git push -f origin main
exit /b %ERRORLEVEL%
