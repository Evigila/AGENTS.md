@echo off
setlocal DisableDelayedExpansion
set "AGENTS_INTERACTIVE=1"
if /i "%~1"=="-NonInteractive" set "AGENTS_INTERACTIVE=0"
set "AGENTS_OPERATION="
set "AGENTS_PUSHED=0"
set "AGENTS_SHELL_READY=0"
set "AGENTS_REPO=https://github.com/Evigila/AGENTS.md.git"
set "AGENTS_PROJECT_ROOT=%~dp0."
set "AGENTS_BOOTSTRAP_SOURCE="
set "AGENTS_SHELL=powershell.exe"
where pwsh.exe >nul 2>&1
if not errorlevel 1 set "AGENTS_SHELL=pwsh.exe"
where %AGENTS_SHELL% >nul 2>&1
if errorlevel 1 goto missing_shell
set "AGENTS_SHELL_READY=1"
pushd "%~dp0"
if errorlevel 1 goto missing_directory
set "AGENTS_PUSHED=1"
where git.exe >nul 2>&1
if errorlevel 1 goto missing_git
if "%AGENTS_INTERACTIVE%"=="0" goto choose_temp
if not "%~1"=="" goto confirm_options
"%AGENTS_SHELL%" -NoProfile -Command "[Console]::WriteLine('1. Update (default)'); [Console]::WriteLine('2. Check'); [Console]::WriteLine('3. Force'); [Console]::WriteLine('0. Exit'); while($true){[Console]::WriteLine('Select [1]:'); $v=[Console]::ReadLine(); if($null -eq $v){exit 4}; switch($v.Trim()){''{exit 11} '1'{exit 11} '2'{exit 12} '3'{exit 13} '0'{exit 0} default{[Console]::WriteLine('Invalid selection. Enter 1, 2, 3, or 0.')}}}"
set "AGENTS_SELECTION=%ERRORLEVEL%"
if "%AGENTS_SELECTION%"=="13" goto select_force
if "%AGENTS_SELECTION%"=="12" goto select_check
if "%AGENTS_SELECTION%"=="11" goto choose_temp
if "%AGENTS_SELECTION%"=="0" goto cancelled
if "%AGENTS_SELECTION%"=="4" goto cancelled
echo [Agents] Cannot read the menu selection.
set "AGENTS_RESULT=1"
goto done

:select_force
set "AGENTS_OPERATION=-Force"
goto choose_temp

:select_check
set "AGENTS_OPERATION=-Check"
goto choose_temp

:confirm_options
"%AGENTS_SHELL%" -NoProfile -Command "while($true){[Console]::WriteLine('Press Enter to run the supplied options, or type 0 to cancel:'); $v=[Console]::ReadLine(); if($null -eq $v){exit 4}; if($v.Trim() -eq '0'){exit 0}; if($v.Trim() -eq ''){exit 11}; [Console]::WriteLine('Invalid input. Press Enter or type 0.')}"
set "AGENTS_SELECTION=%ERRORLEVEL%"
if "%AGENTS_SELECTION%"=="11" goto choose_temp
if "%AGENTS_SELECTION%"=="0" goto cancelled
if "%AGENTS_SELECTION%"=="4" goto cancelled
echo [Agents] Cannot read the supplied-options confirmation.
set "AGENTS_RESULT=1"
goto done

:choose_temp
set "AGENTS_BOOTSTRAP=%TEMP%\agents-framework-%RANDOM%-%RANDOM%"
if exist "%AGENTS_BOOTSTRAP%" goto choose_temp
git clone --quiet --depth 1 --branch main "%AGENTS_REPO%" "%AGENTS_BOOTSTRAP%"
if errorlevel 1 goto bootstrap_failed
set "AGENTS_BOOTSTRAP_SOURCE=%AGENTS_BOOTSTRAP%"
rem Verify both executable entry points before trusting the downloaded controller.
"%AGENTS_SHELL%" -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; $u=New-Object Text.UTF8Encoding($false,$true); $r=$env:AGENTS_BOOTSTRAP_SOURCE; $m=[IO.File]::ReadAllText((Join-Path $r 'AGENTS.framework.json'),$u) | ConvertFrom-Json; if($m.schemaVersion -ne 1 -or $m.launcherProtocolVersion -ne 1){throw 'Unsupported central launcher protocol.'}; foreach($p in @('fetch-agents.bat','scripts/fetch-agents.ps1')){$e=@($m.files | Where-Object {$_.target -eq $p}); if($e.Count -ne 1 -or $e[0].source -ne $p -or $e[0].mode -ne 'managed' -or $e[0].sha256 -notmatch '^[0-9a-f]{64}$'){throw 'Invalid bootstrap executable entry.'}; $t=git -C $r ls-tree HEAD -- $p; if($LASTEXITCODE -ne 0 -or $t -notmatch '^100(644|755) blob '){throw 'Bootstrap executable is not a regular Git file.'}; $b=$u.GetBytes([IO.File]::ReadAllText((Join-Path $r $p),$u).TrimStart([char]0xFEFF).Replace([string]([char]13)+[char]10,[string][char]10)); $s=[Security.Cryptography.SHA256]::Create(); try{$h=([BitConverter]::ToString($s.ComputeHash($b))).Replace('-','').ToLowerInvariant()}finally{$s.Dispose()}; if($h -ne $e[0].sha256){throw 'Bootstrap executable hash mismatch.'}}"
if errorlevel 1 goto bootstrap_failed
rem Parse the finishing block before the installer can replace this launcher.
(
    "%AGENTS_SHELL%" -NoProfile -ExecutionPolicy Bypass -File "%AGENTS_BOOTSTRAP%\scripts\fetch-agents.ps1" %* %AGENTS_OPERATION%
    call set "AGENTS_RESULT=%%ERRORLEVEL%%"
    "%AGENTS_SHELL%" -NoProfile -Command "$p=[IO.Path]::GetFullPath($env:AGENTS_BOOTSTRAP); $t=[IO.Path]::GetFullPath($env:TEMP).TrimEnd([char]92,[char]47); if([IO.Path]::GetDirectoryName($p) -ne $t -or [IO.Path]::GetFileName($p) -notmatch '^agents-framework-[0-9]+-[0-9]+$'){throw 'Invalid bootstrap cleanup path.'}; Remove-Item -LiteralPath $p -Recurse -Force"
    popd
    if "%AGENTS_INTERACTIVE%"=="1" "%AGENTS_SHELL%" -NoProfile -Command "[Console]::WriteLine('Press Enter to close...'); [void][Console]::ReadLine()"
    call exit /b %%AGENTS_RESULT%%
)

:bootstrap_failed
if exist "%AGENTS_BOOTSTRAP%" "%AGENTS_SHELL%" -NoProfile -Command "$p=[IO.Path]::GetFullPath($env:AGENTS_BOOTSTRAP); $t=[IO.Path]::GetFullPath($env:TEMP).TrimEnd([char]92,[char]47); if([IO.Path]::GetDirectoryName($p) -ne $t -or [IO.Path]::GetFileName($p) -notmatch '^agents-framework-[0-9]+-[0-9]+$'){throw 'Invalid bootstrap cleanup path.'}; Remove-Item -LiteralPath $p -Recurse -Force"
set "AGENTS_RESULT=1"
goto done

:missing_git
echo [Agents] Git for Windows is required.
set "AGENTS_RESULT=1"
goto done

:missing_shell
echo [Agents] Windows PowerShell 5.1 or PowerShell 7 is required.
set "AGENTS_RESULT=1"
goto done

:missing_directory
echo [Agents] Cannot open the launcher directory.
set "AGENTS_RESULT=1"
goto done

:cancelled
echo [Agents] Operation cancelled.
set "AGENTS_RESULT=0"

:done
if "%AGENTS_PUSHED%"=="1" popd
if "%AGENTS_INTERACTIVE%"=="1" (
    if "%AGENTS_SHELL_READY%"=="1" (
        "%AGENTS_SHELL%" -NoProfile -Command "[Console]::WriteLine('Press Enter to close...'); [void][Console]::ReadLine()"
    ) else (
        pause
    )
)
exit /b %AGENTS_RESULT%
