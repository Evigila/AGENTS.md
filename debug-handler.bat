@echo off
setlocal DisableDelayedExpansion
set "DEBUG_INTERACTIVE=1"
if /i "%~1"=="-NonInteractive" set "DEBUG_INTERACTIVE=0"
set "DEBUG_PUSHED=0"
set "DEBUG_SHELL_READY=0"
set "DEBUG_RESULT=1"
set "DEBUG_SHELL=powershell.exe"
where pwsh.exe >nul 2>&1
if not errorlevel 1 set "DEBUG_SHELL=pwsh.exe"
where %DEBUG_SHELL% >nul 2>&1
if errorlevel 1 goto missing_shell
set "DEBUG_SHELL_READY=1"
pushd "%~dp0"
if errorlevel 1 goto missing_directory
set "DEBUG_PUSHED=1"
if /i "%~1"=="-NonInteractive" goto automatic
"%DEBUG_SHELL%" -NoProfile -Command "[Console]::WriteLine('1. Debug (default)'); [Console]::WriteLine('2. Clear database'); [Console]::WriteLine('3. Publish tag'); [Console]::WriteLine('4. Publish NuGet'); [Console]::WriteLine('0. Exit'); while($true){[Console]::WriteLine('Select [1]:'); $v=[Console]::ReadLine(); if($null -eq $v){exit 0}; switch($v.Trim()){''{exit 11} '1'{exit 11} '2'{exit 12} '3'{exit 13} '4'{exit 14} '0'{exit 0} default{[Console]::WriteLine('Invalid selection. Enter 1, 2, 3, 4, or 0.')}}}"
set "DEBUG_SELECTION=%ERRORLEVEL%"
if "%DEBUG_SELECTION%"=="11" goto select_debug
if "%DEBUG_SELECTION%"=="12" goto select_clear
if "%DEBUG_SELECTION%"=="13" goto select_tag
if "%DEBUG_SELECTION%"=="14" goto select_nuget
if "%DEBUG_SELECTION%"=="0" goto cancelled
echo [Debug] Cannot read the menu selection.
goto done

:automatic
set "DEBUG_INTERACTIVE=0"
set "DEBUG_SELECTION=%~2"
if "%DEBUG_SELECTION%"=="" set "DEBUG_SELECTION=1"

:select_operation
if "%DEBUG_SELECTION%"=="0" goto cancelled
if "%DEBUG_SELECTION%"=="1" goto select_debug
if "%DEBUG_SELECTION%"=="2" goto select_clear
if "%DEBUG_SELECTION%"=="3" goto select_tag
if "%DEBUG_SELECTION%"=="4" goto select_nuget
echo [Debug] Invalid operation. Use 1, 2, 3, 4, or 0.
goto done

:select_debug
set "DEBUG_OPERATION=debug"
goto run_operation
:select_clear
set "DEBUG_OPERATION=clear-database"
goto run_operation
:select_tag
set "DEBUG_OPERATION=publish-tag"
goto run_operation
:select_nuget
set "DEBUG_OPERATION=publish-nuget"

:run_operation
if exist "scripts\%DEBUG_OPERATION%.bat" goto run_batch
if exist "scripts\%DEBUG_OPERATION%.ps1" goto run_powershell
echo [Debug] Operation is not configured: scripts/%DEBUG_OPERATION%.bat or .ps1.
goto done

:run_batch
"%ComSpec%" /d /s /c ""scripts\%DEBUG_OPERATION%.bat""
set "DEBUG_RESULT=%ERRORLEVEL%"
goto done

:run_powershell
"%DEBUG_SHELL%" -NoProfile -ExecutionPolicy Bypass -File "scripts\%DEBUG_OPERATION%.ps1"
set "DEBUG_RESULT=%ERRORLEVEL%"
goto done

:missing_shell
echo [Debug] Windows PowerShell 5.1 or PowerShell 7 is required.
goto done
:missing_directory
echo [Debug] Cannot open the launcher directory.
goto done
:cancelled
echo [Debug] Operation cancelled.
set "DEBUG_RESULT=0"

:done
if "%DEBUG_PUSHED%"=="1" popd
if "%DEBUG_INTERACTIVE%"=="1" (
    if "%DEBUG_SHELL_READY%"=="1" (
        "%DEBUG_SHELL%" -NoProfile -Command "[Console]::WriteLine('Press Enter to close...'); [void][Console]::ReadLine()"
    ) else (
        pause
    )
)
exit /b %DEBUG_RESULT%
