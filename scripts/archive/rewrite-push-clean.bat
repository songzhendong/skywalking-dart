@echo off
REM Run in cmd.exe only; uses commit-msg-clean.txt (no Co-authored-by trailer).
cd /d "%~dp0.."
git checkout --orphan main-clean
if errorlevel 1 exit /b 1
git add -A
if errorlevel 1 exit /b 1
for /f %%i in ('git write-tree') do set TREE=%%i
git commit-tree %TREE% -F "%~dp0commit-msg-clean.txt" > "%TEMP%\swd-new-commit.txt"
if errorlevel 1 exit /b 1
set /p COMMIT=<"%TEMP%\swd-new-commit.txt"
git reset --hard %COMMIT%
if errorlevel 1 exit /b 1
git branch -D main 2>nul
git branch -m main
echo New HEAD:
git log -1 --format=%%B
git push -f origin main
exit /b %ERRORLEVEL%
