@echo off

set BinPath=Engine\Binaries\Win64
set BinUnrealPak=UnrealPak.exe
set PAKARGS=-compress
set FILEARGS=-compress
set MountPoint=../../../UnrealTournament/
set CustomRoot=

set overwrite=1
set force=0
set uncompress=0
set newversion=

:: -----------------------------------------------------

set script_no_wait=1
set script_silent=0

set UE4Root=%~dp0
if NOT ["%CustomRoot%"] == [""] set UE4Root=%CustomRoot%\

:: Normalize paths
set UE4Root=%UE4Root:\\=\%
set UE4Root=%UE4Root:"=%

set OutDir=%TEMP%\%~n1
set NewPak=%~dp0%~nx1
set UnrealPak=%UE4Root%%BinPath%\%BinUnrealPak%

:: Normalize UnrealPak bin
set OutDir=%OutDir:\\=\%
set OutDir=%OutDir:"=%

set PakDir=%OutDir%\Pak
set PakResponseFile=%OutDir%\list.txt

:: Normalize UnrealPak bin
set UnrealPak=%UnrealPak:\\=\%
set UnrealPak=%UnrealPak:"=%

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

:: check for silent mode
for %%x in (%*) do (
    if "%%x"=="-s" (
        set script_silent=1
    )
)

call :NullLine
call :Header #########################################################################
call :Header =========================================================================
call :Msg UE4 pak file compressing script v0.6
call :Msg by RattleSN4K3
call :Header -------------------------------------------------------------------------
call :Msg A small command line script allowing to re-compress pak files
call :Header -------------------------------------------------------------------------
call :Header

call :Wait 1000

if not exist "%UnrealPak%" goto :Error_BatchFileInWrongLocation
if %1.==. GOTO :Error_NoParameters
if not exist %1 goto :Error_NoPakFile %1
SETLOCAL ENABLEEXTENSIONS
ECHO.%~a1 | find "d" >NUL 2>NUL && (
	goto :Error_IsDir %1
)


:: Remove first argument from command line
SET allargs=%*
CALL SET restargs=%%allargs:*%1=%%
SET restargs=%restargs:~1%

:: parse command line arguments. see AssignKeyValue
call :SplitArgs %restargs%


if %uncompress% == 1 (
	set PAKARGS=
	set FILEARGS=
)


:: Info
call :Msg Processing:
call :Msg %~n1
call :Msg (%~dp1)
call :Msg
call :Msg Options:
if %uncompress% == 1 (
	call :Msg  - Uncompress file
) else if "%newversion%" NEQ "" (
    call :Msg  - Overwrite network version: %newversion%
    call :Msg
)
if %overwrite% == 1 (
	call :Msg  - Overwrite original file
) else (
	set TempVar1=
	set TempVar2=
	call :GetPath TempVar1="%NewPak%"
	call :GetFilename TempVar2="%NewPak%"

	call :Msg  - Output file: !TempVar2!
	call :Msg  - Output dir: !TempVar1!

	if %force% == 0 (
		if exist "%NewPak%" GOTO :Error_Exists
	) else (
		call :Msg  - Force overwrite output file	
	)
)
call :Msg


:: Process options
set PakFile=%~1
if %overwrite% == 1 (
	set NewPak=%~1
	if %FromDrop% == 1 (
		echo.
		echo.Press any key to continue... 
		pause > nul
	)
)


:: Clean up old temp files
if exist "%OutDir%" (
	call :Msg Clean up old temp files...
	rmdir "%OutDir%" /s /q
	call :Msg Clean up old temp files done.
)

:: Extracting
call :Msg Extracting...
"%UnrealPak%" "%PakFile%" -extract "%PakDir%" > nul
call :Msg Extracting done.


:: Count path depth
set count=0
call :countdepth "%PakDir%"


:: Check mounting
pushd %PakDir%
set subpath=
for /f "tokens=%count%* delims=\" %%f in ('dir /b /s /a-h-s *-AssetRegistry.bin') do (
	set subpath=/%%g
	set subpath=!subpath:%%~nxg=!
)

set subpath=%subpath:\=/%
if NOT "%subpath%" == "/" (
	set MountPoint=!MountPoint:%subpath%=/!
)
popd


:: Check network version
set networkversion=
if "%newversion%" NEQ "" (
    pushd %PakDir%
    set versionfile=
    for /r %PakDir% %%f in (*-version.txt) do (
        set versionfile=%%f
        set /p networkversion=<%%f
    )
    popd
    call :Msg 
    call :Msg Current network version: !networkversion!
    call :Msg Overwrite with: %newversion%

    echo %newversion%>!versionfile!
    call :Msg Version set.
    call :Msg 
)


:: Creating response file

:: preserve pak order (kinda)
set orderfile=%OutDir%\order.txt
"%UnrealPak%" "%PakFile%" -list > %orderfile%
for /F "tokens=*" %%A in (%orderfile%) do (
	set InFile=
	call :ParseOutputList InFile=%%A
	if NOT "!InFile!" == "" (
		echo "%PakDir%\!InFile!" "%MountPoint%!InFile!" %FILEARGS%>>%PakResponseFile%
	)
)

:: !!! OLD CODE BELOW

:: pushd %PakDir%
:: for /f "tokens=%count%* delims=\" %%f in ('dir /b /s /a-d-h-s') do (
:: 	echo "%PakDir%\%%g" "%MountPoint%%%g" %FILEARGS%>>%PakResponseFile%
:: )
:: popd

:: !!! OLD CODE END


:: Compressing
if %overwrite% == 1 (
	call :Msg Overwriting old pak file
)
call :Msg Compressing...
"%UnrealPak%" "%NewPak%" -create="%PakResponseFile%" %PAKARGS% > nul
call :Msg Compressing done.

:: Deleting temp files
if exist "%OutDir%" (
	call :Msg Deleting temp files...
	rmdir "%OutDir%" /s /q
	call :Msg Deleting temp files done.
)

call :Msg
call :Msg Process done.

call :Wait 5000
goto :Exit

:Error_BatchFileInWrongLocation
call :Msg ERROR:
call :Msg The batch file does not appear to be located in the root UE4 directory.
call :Msg This script must be run from within that directory.
call :Msg
call :Msg or specify 'CustomRoot' in the top of this file.
call :Msg
if %FromDrop% == 1 pause
goto Exit

:Error_NoParameters
call :Msg ERROR:
call :Msg No parameter set.
call :Msg
call :Wait 500
goto Exit

:Error_NoPakFile
call :Msg ERROR:
call :Msg No valid pak file given. Unable to find given file:
call :Msg %~1
call :Msg
call :Wait 1000
goto Exit

:Error_IsDir
call :Msg ERROR:
call :Msg Input file is a directory:
call :Msg %~1
call :Msg
call :Wait 1000
goto Exit

:Error_Exists
call :Msg
call :Msg ERROR:
call :Msg Output file already exists.
call :Msg Use the force option (-f) to overwrite or delete the file.
call :Msg
call :Wait 2000
goto Exit

:Header
if %script_silent% == 0 echo #%*
goto :EOF

:Msg
if %script_silent% == 0 echo # %*
goto :EOF

:NullLine
if %script_silent% == 0 echo.
goto :EOF

:Wait
if %script_no_wait% == 0 @ping 1.1.1.1 -n 1 -w %1 > nul
goto :EOF

:countdepth
set list=%1
set list=%list:"=%
FOR /f "tokens=1* delims=\" %%a IN ("%list%") DO (
  if not "%%a" == "" call Set /A count+=1
  if not "%%b" == "" call :countdepth "%%b"
)
goto :EOF

:GetFilename
set %~1=%~n2
goto :EOF

:GetPath
set %~1=%~dp2
goto :EOF

:ParseOutputList
:: setlocal enabledelayedexpansion
set string=%*
set "find=*Display: "
call set string=%%string:!find!=%%

set "find=* offset: "
call set delete=%%string:!find!=%%
call set string=%%string:!delete!=%%

:: remove " offset: "
set string=%string:~0,-9%

set first=%string:~0,1%
set first=%first:"=%
if "%first%" == "" (
	:: remove quotes
	set string=%string:~1,-1%
	set %~1=!string!
) else (
	set %~1=
)
goto :EOF


:ParseOutputTest
:: setlocal enabledelayedexpansion
set string=%*
set "find=*Display: "
call set string=%%string:!find!=%%

:: remove " OK."
set string=%string:~0,-4%

set first=%string:~0,1%
set first=%first:"=%
if "%first%" == "" (
	:: remove quotes
	set string=%string:~1,-1%
	set %~1=!string!
) else (
	set %~1=
)
goto :EOF


:SplitArgs
REM recursive procedure to split off the first two tokens from the input
if "%*" NEQ "" (
    REM %%i = KEY, %%j = VALUE, %%k = remainder of input
    REM delimiters are space character and equals character
    for /F "tokens=1,2,* delims== " %%i in ("%*") do (
        call :AssignKeyValue %%i %%j & call :SplitArgs %%j %%k
    )
)
goto :eof


:AssignKeyValue
REM KEY %1, VALUE %2
if "%1" EQU "-o" (
    SET overwrite=1
) else if "%1" EQU "-f" (
    SET force=1
) else if "%1" EQU "-u" (
    SET uncompress=1
) else if "%1" EQU "-n" (
    SET newversion=%2
) else (
    REM Append unrecognised [key,value] to BADARGS
    REM echo Unknown KEY %1
    REM SET BADARGS=%BADARGS%[%1, %2]
)
goto :eof

:Exit