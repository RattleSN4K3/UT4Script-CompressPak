@echo off

set CompressBat="%~dp0\CompressPak.bat"

: Check if opened from CMD
setlocal enabledelayedexpansion
set testl=%cmdcmdline:"=%
set testr=!testl:%~nx0=!
set FromDrop=0
if not "%testl%" == "%testr%" (
	:: opened from drag'n'drop
	set script_no_wait=0
	set FromDrop=1
) else (
	:: opened from CMD
	set overwrite=0
)

:: Check if script can be found
if not exist %CompressBat% (
	set batfile=
	call :GetFilename batfile=%CompressBat%
	echo.ERROR:
	echo.
	echo !batfile! does not exist.
	echo.Please install !batfile! properly and run this script again.
	echo.

	if %FromDrop% == 1 pause
	goto Exit
)

:: Get rest of the command line input
setlocal enabledelayedexpansion
set restcmd=%*
set find=%1
set replace=
call set restcmd=%%restcmd:!find!=!replace!%%

:: Call script
call %CompressBat% %1 -u %restcmd%
goto Exit

:GetFilename
set %~1=%~nx2
goto :EOF

:Exit