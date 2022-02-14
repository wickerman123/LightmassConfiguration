@ECHO OFF
SETLOCAL EnableExtensions ENABLEDELAYEDEXPANSION

:Variables
REM **** Variables that can be modified bellow ****
REM VARIABLE: UnrealVersion. You can choose your version if you have more than one installed 
REM or want to target an specific release. Supported versions starts with UE 4.24 and up to 4.26 so far.
REM Defaul is: set UnrealVersion=4.24.
set UnrealVersion=4.27

REM VARIABLE: pUnified. The name of the file that's going to be downloaded for this version
REM DEFAULT: set pUnified=GPULightmass-UE4.24.1.zip
set pUnified=GPULightmass-UE4.27.2-release.zip

REM Download URLS can be modified. This URLs contian the GPU Lightmass for a particular version.
set u7ZIP=https://www.7-zip.org/a/7za920.zip
set uGPULightmass424u=https://dl.orangedox.com/cYwXxmgaur0vOrQzHH?dl=1
set uGPULightmass4241u=https://dl.orangedox.com/QVRpJRuW3iRweVJ9UA?dl=1
set uGPULightmass4243u=https://dl.orangedox.com/y3qGXLCstPo1DggwKA?dl=1
set uGPULightmass4254u=https://dl.orangedox.com/7fPK2NJ1Jmx3s8Gtv5?dl=1
set uGPULightmass426u=https://dl.orangedox.com/KAsDFVpPgoRHoXXtsJ?dl=1
set uGPULightmass4261u=https://dl.orangedox.com/RiBB5lkdyBuxsXJpNH?dl=1
set uGPULightmass4262u=https://dl.orangedox.com/6wS2UhrnsHeFEsZAIp?dl=1
set uGPULightmass4272u=https://www.dropbox.com/sh/fog19rn216h2lav/AAALRm46JGMjgLscLWwbNWwoa?dl=1
set uGPULightmass=%uGPULightmass4272u%

REM TDR Settings
set iTDRValue=300

REM SETTINGS FOR LIGHT BUILD QUALITY
:: FAST
SET FastNumPrimaryGISamples=16
SET FastNumSecondaryGISamples=8
:: MEDIUM
SET MediumNumPrimaryGISamples=32
SET MediumNumSecondaryGISamples=16
:: ULTRA
SET UltraNumPrimaryGISamples=64
SET UltraNumSecondaryGISamples=16
:: EXTREME
SET ExtremeNumPrimaryGISamples=128
SET ExtremeNumSecondaryGISamples=32
:: INSANE
SET InsaneNumPrimaryGISamples=256
SET InsaneNumSecondaryGISamples=64

:FUNCTIONS
REM HERE BE DRAGONS!
REM ...................................................................
REM DO NOT CHANGE ANYTHING FROM HERE UNLESS YOU KNOW WHAT YOU ARE DOING
REM ...................................................................
REM 
set sScriptVersion=v0.3.4
REM 4.20 requires NVIDIA DRIVER VERSION 398.26 or later required. 
set iMinDriverVersion_420=2421139826
REM 4.21 requires NVIDIA DRIVER VERSION 411.31 or later required. 
set iMinDriverVersion_421=2421141131

REM Remove dots from Version Variable
set uVersion=%UnrealVersion:.=% 

If %uVersion% GTR 420 (
	set iMinDriverVersion=%iMinDriverVersion_421%
) ELSE (
	set iMinDriverVersion=%iMinDriverVersion_421%
)

REM CONSOLE COLORS AND MESSAGES
SET mERROR=[31m[7mERRO[0m: 
SET mINFO=[42m[7mINFO[0m: 
SET mWARN=[43m[7mWARN[0m: 
SET cStrong=[97m
SET cUnderline=[4m
SET cReset=[0m
SET cRED=[31m
SET cGREEN=[32m
SET cSOFT=[90m
SET cYellow=[93m
SET cInverted=[7m

SET pUnrealEd=\Engine\Binaries\Win64\UE4Editor-UnrealEd.dll
SET pGPULightmass=\Engine\Binaries\Win64\GPULightmassKernel.dll

REM REGISTRY SETTINGS
set KEY_NAME=HKLM\Software\EpicGames\Unreal Engine\%UnrealVersion%
set VALUE_NAME=InstalledDirectory

set KEY_NAME_TDR=HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers
set VALUE_NAME_TDR=TdrDelay

:MAIN
CALL :UAC
CALL :HEADER
CALL :TDRDELAY
CALL :7Z
CALL :CHECKRUNNING
CALL :SETUP
IF !EPICERROR! EQU 1 GOTO :EXIT
CALL :MENU
GOTO :EXIT

:UAC
REM  --> Check for permissions
fsutil dirty query %systemdrive% >nul
REM --> If error flag set, we do not have admin.
if '%errorlevel%' NEQ '0' (
    echo Requesting administrative privileges...
    echo.
    echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\getadmin.vbs"
    echo UAC.ShellExecute "%~s0", "", "", "runas", 1 >> "%temp%\getadmin.vbs"

    cscript "%temp%\getadmin.vbs" >nul

    if %ERRORLEVEL% EQU 1 (
		  ECHO Cannot obtain Admin as CScript is disabled.
		  ECHO.
        ECHO Please run again with Administrator access OR
		  ECHO.
        ECHO Change "Enabled" to "1" in Registry at HKLM\SOFTWARE\Microsoft\Windows Script Host\Settings
		  ECHO.
		  ECHO NOW TRYING WITH powershell
		  ECHO.
		  cd /d "%~dp0"
        mshta "javascript:var shell=new ActiveXObject('shell.application');shell.ShellExecute('%~nx0','','','runas',1);close();"
        EXIT
    )
    exit
) else ( 
    REM Cleanning up...
	if exist "%temp%\getadmin.vbs" ( del "%temp%\getadmin.vbs" )
    pushd "%CD%"
    CD /D "%~dp0"
)
Exit /B

:7z
IF NOT EXIST 7za.exe (
	ECHO %mINFO%Downloading 7zip
	powershell -Command "Invoke-WebRequest %u7ZIP% -OutFile 7za.zip"
	powershell -Command "Expand-Archive -LiteralPath 7za.zip -DestinationPath ."
	del /q 7za.zip >nul
)
EXIT /B

:VERSION
REM STUB FUNCTION FOR DETECTING VERSION (major, minor, patch) AND PROVIDING A MENU TO CHOOSE FROM
EXIT /B

:HEADER
ECHO.
ECHO %cStrong%Luoshuang's GPULightmass %cSoft%Installer Script %sScriptVersion%%cReset%
ECHO %cSoft%                     - For Unreal Version %UnrealVersion%%cReset%
ECHO.
wmic path win32_VideoController get driverVersion,Name
FOR /F "tokens=1*" %%a IN ('wmic path win32_VideoController get driverVersion^,Name ^| find "NVIDIA"') DO (SET _DRIVER=%%a)
SET _DRIVER=%_DRIVER:.=%
IF DEFINED _DRIVER (
	IF "%_DRIVER%" GEQ "%iMinDriverVersion%" (
		ECHO %mINFO%%cGREEN%Nvidia Driver version is %iMinDriverVersion:~5,3%.%iMinDriverVersion:~8,2% or greater ^(GOOD^)%cReset%
	) ELSE (
		ECHO %mINFO%%cGREEN%Nvidia Driver version is %_DRIVER:~5,3%.%_DRIVER:~8,2% %cReset%
		ECHO %mERROR%%cRED%NVIDIA DRIVER NEEDS TO BE UPDATED TO %iMinDriverVersion:~5,3%.%iMinDriverVersion:~8,2% OR GREATER TO USE GPU LIGHTMASS.%cReset%
		ECHO.
		TIMEOUT 5
	)
) ELSE (
	ECHO %mERROR%%cRED%CAN'T FIND NVIDIA DRIVER INFORMATION ^(CRITICAL^)%cReset%
	TIMEOUT 5
)
EXIT /B

:SETUP
REM GET THE FOLDER WHERE UE4 WAS INSTALLED
FOR /F "tokens=2*" %%A IN ('REG.exe query "%KEY_NAME%" /v "%VALUE_NAME%" 2^>nul') DO (set pInstallDir=%%B)
IF NOT DEFINED pInstallDir (
	echo %mERROR%%cRED%Unreal Engine Version %UnrealVersion% Not Installed or registry not set... %cReset%
	echo %cSoft%Script will now quit.%cReset%
	echo.
	SET EPICERROR=1
	goto exit
)
echo %mINFO%[1mUnreal Engine Version %UnrealVersion% is installed in: %cReset%
echo      - !pInstallDir!

REM CHECK IF GPU LIGHTMASS IS INSTALLED
IF EXIST !pInstallDir!!pGPULightmass! (
	ECHO %mINFO%%cGREEN%GPU Lightmass is Installed%cReset%
	SET NOTINSTALLED=0
) ELSE (
	ECHO %mINFO%%cRED%GPU Lightmass is NOT Installed%cReset%
	SET NOTINSTALLED=1
)

REM CHECK FOR BACKUP
IF EXIST CPULightmass-%UnrealVersion%.zip (
	ECHO %mINFO%%cGREEN%CPU Lightmass is BACKED UP%cReset%
	SET BACKED=1
	REM GOTO MENU
) ELSE (
	ECHO %mWARN%%cRED%CPU Lightmass is NOT BACKED UP%cReset%
	SET BACKED=0
	CALL :BACKUP
)

REM CHECK FOR SETUP FILES
IF NOT EXIST !pUnified! (
	ECHO Downloading GPU Lightmass, this can take a while. Please wait...
	powershell -Command "Invoke-WebRequest %uGPULightmass% -OutFile %UnrealVersion%.zip"
	powershell -Command "Expand-Archive -LiteralPath %UnrealVersion%.zip -DestinationPath ."
	IF !ERRORLEVEL! EQU 0 (del %UnrealVersion%.zip /q) ELSE (ECHO %mERROR%%cRED%ERROR DOWNLOADING: %uGPULightmass% ERRORLEVEL: !ERRORLEVEL!%cReset%)
	echo.
	IF EXIST %pUnified% (ECHO %mINFO%DOWNLOAD COMPLETE.) ELSE (ECHO %mERROR%%cRED%DOWNLOAD ERROR: !pUnified! %cReset%)
) ELSE (
	ECHO %mINFO%%cGREEN%GPULightmass is already downloaded.%cReset%
)
EXIT /B 0

:CHECKRUNNING
REM DETECT IF UNREAL IS RUNNING
tasklist /FI "IMAGENAME eq UE4Editor.exe" | find /I /N "UE4Editor.exe">NUL
if !ERRORLEVEL! EQU 0 (
echo %mWARN%Unreal Editor is running. GPU INSTALL NOT POSSIBLE if not installed already.
SET RUNNING=1
) ELSE (
echo %mINFO%%cGREEN%Unreal Editor is NOT running. *GOOD*%cReset%
)
EXIT /B 0

:BACKUP
IF EXIST !pInstallDir!\Engine\Binaries\DotNET\ProgressReporter.exe (
	ECHO.
	ECHO %mERROR%%cRED%GPU Lightmass is installed. Clean backup not possible.%cReset%
	ECHO.
	CHOICE /m "Do you want to force backup anyway? (Useful if you just updated Unreal and had GPULightmass installed)."
	IF !ERRORLEVEL! EQU 1 (GOTO :FORCED) ELSE (EXIT /B 1)
)
GOTO :BACKINGUP
:FORCED
ECHO Performing FORCED BACKUP...
GOTO :STARTBACKUP
:BACKINGUP
ECHO Lightmass backup procedure in progress...
ECHO.
:STARTBACKUP
ECHO %mINFO%%cSoft%Performing Lightmass BACKUP%cReset%
set InstallVersion=CPULightmass-%UnrealVersion%.zip
if exist listfile.txt del listfile.txt /Q
echo Engine\Config\BaseLightmass.ini >> listfile.txt
echo Engine\Binaries\Win64\UnrealLightmass-SwarmInterface.dll >> listfile.txt
echo Engine\Binaries\Win64\UnrealLightmass.exe >> listfile.txt
echo Engine\Binaries\Win64\UnrealLightmass-ApplicationCore.dll >> listfile.txt
echo Engine\Binaries\Win64\UnrealLightmass-BuildSettings.dll >> listfile.txt
echo Engine\Binaries\Win64\UnrealLightmass-Cbor.dll >> listfile.txt
echo Engine\Binaries\Win64\UnrealLightmass-Core.dll >> listfile.txt
echo Engine\Binaries\Win64\UnrealLightmass-CoreUObject.dll >> listfile.txt
echo Engine\Binaries\Win64\UnrealLightmass-Json.dll >> listfile.txt
echo Engine\Binaries\Win64\UnrealLightmass-Messaging.dll >> listfile.txt
echo Engine\Binaries\Win64\UnrealLightmass-NetCommon.dll >> listfile.txt
echo Engine\Binaries\Win64\UnrealLightmass-Networking.dll >> listfile.txt
echo Engine\Binaries\Win64\UnrealLightmass-Projects.dll >> listfile.txt
REM echo Engine\Binaries\Win64\UnrealLightmass-SandboxFile.dll >> listfile.txt
echo Engine\Binaries\Win64\UnrealLightmass-Serialization.dll >> listfile.txt
echo Engine\Binaries\Win64\UnrealLightmass-Sockets.dll >> listfile.txt
echo Engine\Binaries\Win64\UnrealLightmass-TraceLog.dll >> listfile.txt
echo Engine\Binaries\Win64\UE4Editor-UnrealEd.dll >> listfile.txt
SET ZIPPATH=%CD%
PUSHD !pInstallDir!
!ZIPPATH!\7za a !ZIPPATH!\!InstallVersion! @!ZIPPATH!\listfile.txt
POPD
del listfile.txt /Q >nul

REM set _datestr=%date:~10,4%-%date:~7,2%-%date:~4,2%
set _datestr=%date:/=%
Set _backupfile=Lightmass-Backup-%UnrealVersion%-%_datestr%.zip

IF EXIST "!_backupfile!" (
	ECHO.
	ECHO %mWARN%%cRED%There is currently a !_backupfile! file in the current folder.%cReset%
	ECHO.
	ECHO This is optional. You can still recover CPU Lightmass from !InstallVersion!
	ECHO.
	CHOICE /c yn /m "Do you want to overrite your current Lightmass Backup?"
	IF !ERRORLEVEL! NEQ 1 EXIT /B 1
)
copy "!InstallVersion!" "!_backupfile!" >nul
EXIT /B 0

:MENU
REM TO DO: CHECK VERSION Installed
REM FOR /F "skip=1 delims=" %%a IN ('certutil -hashfile "!pInstallDir!!pGPULightmass!" MD5') DO (SET _HASH=%%a)
REM ECHO %_HASH%
CALL :TestHash
SET "_Loop="
SET "_sCPU="
SET "_sFast="
SET "_sMedium="
SET "_sHigh="
SET "_sExtreme="
SET "_sUnified="
SET "_cCPU="
SET "_cFast="
SET "_cMedium="
SET "_cHigh="
SET "_cExtreme="
SET "_cUnified="
SET _SELECTED=%cInverted%%cYellow%[CURRENT]

ECHO %mINFO%EDITOR HASH: !_EditorHash!

IF [!_EDITORQuality!]==[CPU] (
	SET _sCPU=%_SELECTED%
)

IF [!_EDITORQuality!]==[GPU] (
	IF !_GPUQuality!==FastPreview SET _sFast=%_SELECTED% && SET _cFast=%cInverted%
	IF !_GPUQuality!==MediumQuality SET _sMedium=%_SELECTED% && SET _cMedium=%cInverted%
	IF !_GPUQuality!==UltraHigh SET _sHigh=%_SELECTED% && SET _cHigh=%cInverted%
	IF !_GPUQuality!==Extreme SET _sExtreme=%_SELECTED% && SET _cExtreme=%cInverted%
	IF !_GPUQuality!==Unified SET _sUnified=%_SELECTED% && SET _cUnified=%cInverted%
)

ECHO.
ECHO Choose the Lightmass version you would like to install:
ECHO ------------------------------------------------------
ECHO.
IF !RUNNING! NEQ 1 (ECHO %cSoft%1 - Backup Current Lightmass%cReset%) ELSE (ECHO %mWARN%%cSoft%CPU LIGHTMASS Cannot be backup while UnrealEd is running [DISABLED]%cReset%)
IF !RUNNING! NEQ 1 (ECHO 2 - RESTORE CPU Lightmass !_sCPU!%cReset%) ELSE (ECHO %mWARN%%cSoft%CPU LIGHTMASS Cannot be restored until UnrealEd is closed !_sCPU!%cReset% [DISABLED]%cReset%)
ECHO !_cUnified!%cStrong%3 - Install GPU Lightmass with Unified Settings !_sUnified!%cReset%
ECHO %cSoft%4 - Change Unified Quality Settings %cReset%
ECHO %cSoft%5 - Open UnrealEngine Folder in Explorer %cReset%
ECHO %cYellow%9 - EXIT%cReset%
ECHO.
CHOICE /C:123459 /M "Choose your option"
IF !ERRORLEVEL! EQU 1 CALL :BACKUP && GOTO :MENU
IF !ERRORLEVEL! EQU 2 CALL :CPU && GOTO :MENU
IF !ERRORLEVEL! EQU 3 SET InstallVersion=%pUnified% && CALL :INSTALL && CALL :Settings && GOTO :MENU
IF !ERRORLEVEL! EQU 4 SET "_Loop=1" && CALL :Settings && GOTO :MENU
IF !ERRORLEVEL! EQU 5 CALL :Explorer && GOTO :MENU
IF !ERRORLEVEL! EQU 6 GOTO :EOF

GOTO :MENU

:Settings
ECHO.
ECHO Choose the Quality Settings to set in Baselightmass.ini:
ECHO -------------------------------------------------------
REM powershell -Command "(Get-Content '!pInstallDir!\Engine\Config\BaseLightmass.ini') | Select-String -Pattern 'NumPrimaryGISamples'" >nul
REM powershell -Command "(Get-Content '!pInstallDir!\Engine\Config\BaseLightmass.ini') | Select-String -Pattern 'NumSecondaryGISamples'" >nul
FINDSTR "NumPrimaryGISamples" "!pInstallDir!\Engine\Config\BaseLightmass.ini"
FINDSTR "NumSecondaryGISamples" "!pInstallDir!\Engine\Config\BaseLightmass.ini"
ECHO.
ECHO %cStrong%1 - GPU Lightmass Fast Preview !_sUniFast!
ECHO %cStrong%2 - GPU Lightmass Medium Quality !_sUniMedium!
ECHO %cStrong%3 - GPU Lightmass Ultra High Quality !_sUniHigh!
ECHO %cStrong%4 - GPU Lightmass Extreme Quality !_sUniExtreme!%cReset%
ECHO %cStrong%5 - GPU Lightmass Insane Quality !_sUniExtreme!%cReset%
ECHO %cStrong%6 - Open Baselightmass.ini in Notepad !_sUniExtreme!%cReset%
ECHO %cYellow%9 - Go back...%cReset%
ECHO.
CHOICE /C:1234569 /M "Choose your option"
IF !ERRORLEVEL! EQU 1 SET NumPrimaryGISamples=!FastNumPrimaryGISamples! && SET NumSecondaryGISamples=!FastNumPrimaryGISamples! && GOTO :ReplaceSettings
IF !ERRORLEVEL! EQU 2 SET NumPrimaryGISamples=!MediumNumPrimaryGISamples! && SET NumSecondaryGISamples=!MediumNumPrimaryGISamples! && GOTO :ReplaceSettings
IF !ERRORLEVEL! EQU 3 SET NumPrimaryGISamples=!UltraNumPrimaryGISamples! && SET NumSecondaryGISamples=!UltraNumPrimaryGISamples! && GOTO :ReplaceSettings
IF !ERRORLEVEL! EQU 4 SET NumPrimaryGISamples=!ExtremeNumPrimaryGISamples! && SET NumSecondaryGISamples=!ExtremeExtremeNumPrimaryGISamples! && GOTO :ReplaceSettings
IF !ERRORLEVEL! EQU 5 SET NumPrimaryGISamples=!InsaneNumPrimaryGISamples! && SET NumSecondaryGISamples=!InsaneNumPrimaryGISamples! && GOTO :ReplaceSettings
IF !ERRORLEVEL! EQU 6 GOTO :Notepad
IF !ERRORLEVEL! EQU 7 EXIT /B
EXIT /B

:Notepad
where /q notepad++
IF !ERRORLEVEL! EQU 1 (Notepad "!pInstallDir!\Engine\Config\BaseLightmass.ini") ELSE (Notepad++ "!pInstallDir!\Engine\Config\BaseLightmass.ini")
IF !_LOOP! EQU 1 GOTO :Settings
EXIT /B

:ReplaceSettings
powershell -Command "(Get-Content '!pInstallDir!\Engine\Config\BaseLightmass.ini') | ForEach-Object { $_ -replace 'NumPrimaryGISamples=.*','NumPrimaryGISamples=!NumPrimaryGISamples!' } | Set-Content '!pInstallDir!\Engine\Config\BaseLightmass.ini'"
powershell -Command "(Get-Content '!pInstallDir!\Engine\Config\BaseLightmass.ini') | ForEach-Object { $_ -replace 'NumSecondaryGISamples=.*','NumSecondaryGISamples=!NumSecondaryGISamples!' } | Set-Content '!pInstallDir!\Engine\Config\BaseLightmass.ini'"
IF !_LOOP! EQU 1 GOTO :Settings
EXIT /B

:Explorer
explorer %pInstallDir%
EXIT /B

:CPU
ECHO CPU Lightmass Install
ECHO.
IF EXIST set CPULightmass-%UnrealVersion%.zip (
	ECHO Cleaning up %UnrealVersion% of old GPU Lightmass Files
	SET InstallVersion=CPULightmass-%UnrealVersion%.zip
	del "!pInstallDir!\Engine\Binaries\DotNET\ProgressReporter.exe"
	del "!pInstallDir!\Engine\Binaries\Win64\GPULightmassKernel.dll"
	GOTO INSTALL
)
ECHO %mERROR%%cRED%Can't find %InstallVersion%. CPU Lightmass won't be restored.%cReset%
EXIT /B

:INSTALL
IF !NOTINSTALLED! EQU 1 (
	IF !RUNNING! EQU 1 (
		GOTO :WONTINSTALL
	) ELSE (
		ECHO GPU Lightmass Install, version: !InstallVersion!
		ECHO.
	)
) ELSE (
	IF !RUNNING! EQU 1 (
		ECHO SWITCHING GPU VERSION: !InstallVersion!
		ECHO.
	) ELSE (
		ECHO GPU Lightmass Install, version: !InstallVersion!
	)
)
IF EXIST !InstallVersion! (7za x !InstallVersion! -o"!pInstallDir!" -y -r) ELSE (ECHO %mERROR%Can't find !InstallVersion!)
EXIT /B

:TDRDELAY
FOR /F "tokens=2*" %%A IN ('REG.exe query "%KEY_NAME_TDR%" /v "%VALUE_NAME_TDR%" 2^>nul') DO (set /a iTdrDelay=%%B)
IF NOT DEFINED iTdrDelay (
	ECHO %mWARN%%cRED%TDR Delay settings not found%cReset%
	ECHO.
	ECHO It is recommended to change Windows Timeout Detection and Recovery settings to prevent 
	ECHO        the GPU from being timed out under heavy workload: e.g.: unspecified launch failure and other Error crashes
	ECHO.
	CHOICE /m "Do you want to set your TDR setting to %iTDRValue% (recommended)?"
	IF !ERRORLEVEL! EQU 1 CALL :TDRSet
) else (
	Echo %mINFO%%cGREEN%Your TdrDelay is set to !iTdrDelay! *GOOD*%cReset%
)
Exit /B

:TDRSet
ECHO.
REG ADD %KEY_NAME_TDR% /v %VALUE_NAME_TDR% /t REG_DWORD /d %iTDRValue%
if %ERRORLEVEL% EQU 0 ECHO %mWARN%%cGREEN%TDR Settings added successfully. %cRED%Please restart or log-off for changes to take effect%cReset%
Exit /B

:TestHash
REM ECHO TESTING UnrealEd
SET pFileToCheck=!pInstallDir!!pUnrealEd!
SET "_HASH="
SET "_FOUND="
IF EXIST !pFileToCheck! (CALL :Test) ELSE (SET _EDITORQuality=NOT FOUND)
IF DEFINED _HASH SET _EditorHash=!_HASH!
IF DEFINED _FOUND (
	SET _EDITORQuality=!_QUALITY: =!
	ECHO %mINFO%EDITOR QUALITY: [!_QUALITY: =!]
	SET _EDITORVersion=!_EDITOR: =!
	ECHO %mINFO%EDITOR VERSION: [!_EDITOR: =!]
) ELSE (
	ECHO %mERROR%%cRED%CPU Lightmass Kernel version is unknown.%cReset%
	IF NOT DEFINED _EDITORQuality SET _EDITORQuality=UNKNOWN
	SET "_EDITORVersion="
)
REM ECHO TESTING GPULightmassKernel
SET pFileToCheck=!pInstallDir!!pGPULightmass!
SET "_HASH="
SET "_FOUND="
IF EXIST !pFileToCheck! (CALL :Test) ELSE (SET _GPUQuality=NOT FOUND)
IF DEFINED _HASH SET _GPUHash=!_HASH!
IF DEFINED _FOUND (
	SET _GPUQuality=!_QUALITY: =!
	ECHO %mINFO%GPU QUALITY: [!_QUALITY: =!]
	SET _GPUVersion=!_GPU: =!
	ECHO %mINFO%GPU VERSION: [!_GPU: =!]
) ELSE (
	REM ECHO %mERROR%CPU Lightmass Kernel version is unknown.
	IF NOT DEFINED _GPUQuality SET _GPUQuality=UNKNOWN
	SET "_GPUVersion="
)
REM TO DO: CHECKS (IF EDITOR QUALITY IS CPU AND GPU INSTALLED THEN DIRTY; IF EDITOR IS GPU AND GPU NOT FOUND THEN DIRTY; IF EDITOR IS GPU AND GPUQUALITY NOT EQU EDITORQUALITY THEN DIRTY)
REM IF !_ENGINE!==!UnrealVersion! (ECHO TEST OK) ELSE (ECHO DIRTY INSTALL, ENGINE IS !_ENGINE! and VERSION IS !UnrealVersion!)

EXIT /B

:Test
SET "_HASH="
SET "_ENGINE="
SET "_QUALITY="
SET "_FOUND="
SET "_EDITOR="
SET "_GPU="
IF NOT EXIST !pFileToCheck! ECHO %mERROR%!pFileToCheck! does not exist && EXIT /B 1
ECHO.
REM ECHO HASHING !pFileToCheck!...
FOR /F "tokens=*" %%a IN ('certutil -hashfile "!pFileToCheck!" MD5 ^| find /i /v "md5" ^| find /i /v "certutil"') DO (SET _HASH=%%a)
REM ECHO TESTING TOKENS for hash: !_HASH!
IF DEFINED _HASH (
	FOR /F "skip=2 tokens=*" %%a IN ('find "!_HASH!" hash.txt') DO (SET _FOUND=%%a)
	if DEFINED _FOUND (
		REM ECHO FOUND: !_FOUND!
		FOR /F "tokens=1-4* delims=:" %%g IN ("!_FOUND!") DO (
			SET _ENGINE=%%g
			IF %%h==UE4Editor-UnrealEd.dll (SET _EDITOR=!_ENGINE: =!)
			IF %%h==GPULightmassKernel.dll (SET _GPU=!_ENGINE: =!)
			IF [%%j]==[] (SET _QUALITY=CPU) ELSE (SET _QUALITY=%%i)
			SET _QUALITY=!_QUALITY: =!
		)
	)
) ELSE (
	REM ECHO !pFileToCheck!: FILE NOT FOUND
)
EXIT /B

:WONTINSTALL
ECHO %mERROR%%cRED%Can't install GPU if Unreal is running. Quit Unreal and install.%cReset%
EXIT /B 1

:EXIT
ECHO.
ECHO ALL DONE. Have a good day!
TIMEOUT 3 >nul
EXIT /B 0
