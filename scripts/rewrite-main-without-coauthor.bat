@echo off
REM Run in cmd.exe to rewrite HEAD without Co-authored-by trailer in commit message.
cd /d "%~dp0.."
for /f %%i in ('git write-tree') do set TREE=%%i
git commit-tree %TREE% -F "%~dp0commit-msg-clean.txt" > "%TEMP%\new-commit.txt"
set /p COMMIT=<"%TEMP%\new-commit.txt"
git reset --hard %COMMIT%
echo New HEAD: %COMMIT%
git log -1 --format=%%B
