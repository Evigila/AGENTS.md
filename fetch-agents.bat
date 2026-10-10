@echo off
setlocal DisableDelayedExpansion
pushd "%~dp0" || exit /b 1
set "AGENTS_REPO=https://github.com/Evigila/AGENTS.md.git"
set "AGENTS_SHELL=powershell.exe"
where pwsh.exe >nul 2>&1
if not errorlevel 1 set "AGENTS_SHELL=pwsh.exe"
where git.exe >nul 2>&1
if errorlevel 1 goto missing_git
where %AGENTS_SHELL% >nul 2>&1
if errorlevel 1 goto missing_shell
if exist "scripts\fetch-agents.ps1" goto update

:choose_temp
set "AGENTS_BOOTSTRAP=%TEMP%\agents-framework-%RANDOM%-%RANDOM%"
if exist "%AGENTS_BOOTSTRAP%" goto choose_temp
git clone --quiet --depth 1 --branch main "%AGENTS_REPO%" "%AGENTS_BOOTSTRAP%"
if errorlevel 1 goto bootstrap_failed
rem Parse the finishing block before the installer can replace this launcher.
(
    "%AGENTS_SHELL%" -NoProfile -ExecutionPolicy Bypass -File "%AGENTS_BOOTSTRAP%\scripts\fetch-agents.ps1" -ProjectRoot "%~dp0." %*
    call set "AGENTS_RESULT=%%ERRORLEVEL%%"
    rmdir /s /q "%AGENTS_BOOTSTRAP%"
    popd
    call exit /b %%AGENTS_RESULT%%
)

:update
(
    "%AGENTS_SHELL%" -NoProfile -ExecutionPolicy Bypass -File "scripts\fetch-agents.ps1" -ProjectRoot "%~dp0." %*
    call set "AGENTS_RESULT=%%ERRORLEVEL%%"
    popd
    call exit /b %%AGENTS_RESULT%%
)

:bootstrap_failed
if exist "%AGENTS_BOOTSTRAP%" rmdir /s /q "%AGENTS_BOOTSTRAP%"
set "AGENTS_RESULT=1"
goto done

:missing_git
echo [Agents] Git for Windows is required.
set "AGENTS_RESULT=1"
goto done

:missing_shell
echo [Agents] Windows PowerShell 5.1 or PowerShell 7 is required.
set "AGENTS_RESULT=1"

:done
popd
exit /b %AGENTS_RESULT%
