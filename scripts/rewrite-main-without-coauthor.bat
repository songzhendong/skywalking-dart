@echo off
REM Strip Cursor Co-authored-by from HEAD using git.exe (not Cursor-wrapped "git commit").
cd /d "%~dp0.."
set GIT_EXE=C:\Program Files\Git\cmd\git.exe
if not exist "%GIT_EXE%" set GIT_EXE=git
for /f %%i in ('"%GIT_EXE%" write-tree') do set TREE=%%i
"%GIT_EXE%" commit-tree %TREE% -F "%~dp0commit-msg-native-full.txt" > "%TEMP%\swd-new-commit.txt"
if errorlevel 1 exit /b 1
set /p COMMIT=<"%TEMP%\swd-new-commit.txt"
"%GIT_EXE%" reset --hard %COMMIT%
echo New HEAD:
"%GIT_EXE%" log -1 --format=%%B
