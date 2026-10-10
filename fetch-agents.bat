@echo off
setlocal DisableDelayedExpansion
pushd "%~dp0" || exit /b 1
set "AGENTS_REPO=https://github.com/Evigila/AGENTS.md.git"
set "AGENTS_PROJECT_ROOT=%~dp0."
set "AGENTS_BOOTSTRAP_SOURCE="
set "AGENTS_SHELL=powershell.exe"
where pwsh.exe >nul 2>&1
if not errorlevel 1 set "AGENTS_SHELL=pwsh.exe"
where git.exe >nul 2>&1
if errorlevel 1 goto missing_git
where %AGENTS_SHELL% >nul 2>&1
if errorlevel 1 goto missing_shell
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
    "%AGENTS_SHELL%" -NoProfile -ExecutionPolicy Bypass -File "%AGENTS_BOOTSTRAP%\scripts\fetch-agents.ps1" %*
    call set "AGENTS_RESULT=%%ERRORLEVEL%%"
    "%AGENTS_SHELL%" -NoProfile -Command "$p=[IO.Path]::GetFullPath($env:AGENTS_BOOTSTRAP); $t=[IO.Path]::GetFullPath($env:TEMP).TrimEnd([char]92,[char]47); if([IO.Path]::GetDirectoryName($p) -ne $t -or [IO.Path]::GetFileName($p) -notmatch '^agents-framework-[0-9]+-[0-9]+$'){throw 'Invalid bootstrap cleanup path.'}; Remove-Item -LiteralPath $p -Recurse -Force"
    popd
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

:done
popd
exit /b %AGENTS_RESULT%
