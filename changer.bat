@echo off
setlocal enabledelayedexpansion
set RIOTDRIVE=C

title AccountSwitcher
IF NOT EXIST "%localappdata%\Riot Games\Riot Client" (
    echo i cant find the riot client folder in your localappdata
    pause
    GOTO :EOF
)

IF NOT EXIST "%RIOTDRIVE%:\Riot Games\Riot Client\RiotClientServices.exe" (
    set "out=change RIOTDRIVE=%RIOTDRIVE% on line 3 of the file to the drive your league is installed on (RIOTDRIVE=C, RIOTDRIVE=D, RIOTDRIVE=E, ..etc)"
    echo [31m!out![0m
    pause
    GOTO :EOF
)

cd "%localappdata%\Riot Games\Riot Client"

taskkill /f /im LeagueClient.exe 2>NUL
timeout /t 1 > NUL
taskkill /f /im RiotClientServices.exe 2>NUL

:WaitForRiotExit
tasklist /FI "IMAGENAME eq %processName%" 2>NUL | find /I "RiotClientServices.exe">NUL
if errorlevel 1 (
    goto AfterRiotExit
)

echo waiting for RiotClientServices.exe to exit.
timeout /t 1 > NUL
goto WaitForRiotExit
:AfterRiotExit

IF EXIST Data (
    SET Z=&& FOR %%A IN (Data) DO SET Z=%%~aA
    IF "!Z:~8,1!" == "l" (
        echo --------------------------------------------------------------------
    ) ELSE (
        findstr /I /N /C:"offline_access" "Data\RiotGamesPrivateSettings.yaml" >nul
        if errorlevel 1 (
            echo [31mYOU DID NOT SELECT "REMEMBER ME" WHEN LOGGING IN. THIS SESSION WILL BE DISCARDED.[0m
            IF EXIST Data (
                rmdir /S /Q Data
            )
            pause
            set "RIP=LogIn" & goto CheckLockSettings
        ) ELSE (
            SET /P SaveTarget="What do you want to save the account as? Hitting enter will discard this login: "
            IF "!SaveTarget!"=="" (
                echo Removing this account
            IF EXIST Data (
                    rmdir /S /Q Data
            )
                goto LogIn
            )
    
            IF EXIST "!SaveTarget!" (
                echo "The target account is already saved, just log into that one (!SaveTarget!) next if you want to update it. Logging out."
            goto LogIn
            ) ELSE (
                ren "Data" "!SaveTarget!"
            )
        )
    )
)

set "RIP=LogIn" & goto CheckLockSettings
:LogIn
echo [36m............Type the name of the account you want to log into. (hitting enter will generate a new login session)[0m
echo Alternatively, there are commands:
echo [36mlist[0m (list all the accounts you have)
echo [36mlocksettings[0m (will toggle the lock on your settings file)
echo [36mdelete[0m (delete specified acc)
echo [31mIf you have not logged into the account within 5 days, you may have been logged out. Log in again.[0m
SET /P target=">"

cls

IF EXIST Data (
    rmdir Data
)

IF "!target!"=="" (
    echo Hitting enter again will generate a new login session. Close the file if you don't want to.
    SET /P target=""
    IF "!target!"=="" (
        GOTO StartLeagueOfLegends
    ) ELSE (
        echo You have chosen to do nothing. You can close the batch file now.
        pause
        GOTO :EOF
    )
)

IF "!target!"=="list" (
    for /f "tokens=2 delims=/" %%a in ('echo %date%') do set "dayOfMonth=%%a"
    for /d %%z in (*) do (
        set "thisdir=%%z"
        if /i not "!thisdir!"=="Config" if /i not "!thisdir!"=="Logs" if /i not "!thisdir!"=="Crashes" if /i not "!thisdir!"=="Data" (
            set "canread=1"
            for /f "tokens=1,2,*" %%a in ('dir "!thisdir!\RiotGamesPrivateSettings.yaml" /TW /-C') do (
                IF "%%b"=="File(s)" (
                    set "canread=0"
                )
                IF "!canread!"=="1" (
                    set "adate=%%a"
                    set "atime=%%b"
                )
            )
            set "adateday=!adate:~3,2!"
            set /a diff=!dayOfMonth! - !adateday!
            if !diff! gtr 3 (
                set "out=[32m!thisdir![0m  [31m(this account may be expired)  !adate:~0,5!   @   !atime![0m"
                echo !out!
            ) else (
                set "out=[32m!thisdir![0m  !adate:~0,5!   @   !atime!"
                echo !out!
            )
        )
    )
    goto LogIn
)

IF "!target!"=="locksettings" (
    goto LockSettings
)

IF "!target!"=="delete" (
    set "RIP=LogIn" & goto DeleteAccount
)

mklink /J Data %target%


:StartLeagueOfLegends
if "!target!"=="pbe" (
    start "" "!RIOTDRIVE!:\Riot Games\Riot Client\RiotClientServices.exe" --launch-product=league_of_legends --launch-patchline=pbe
) else (
    start "" "!RIOTDRIVE!:\Riot Games\Riot Client\RiotClientServices.exe" --launch-product=league_of_legends --launch-patchline=live
)
GOTO :EOF


:DeleteAccount
SET /P DeletingAccount="specify the account: "
IF EXIST "!DeletingAccount!" (
    rmdir /S /Q "!DeletingAccount!"
    echo [31mDeleted !DeletingAccount!.[0m
)
GOTO !RIP!

:CheckLockSettings
set "filename=!RIOTDRIVE!:\Riot Games\League of Legends\Config\PersistedSettings.json"
attrib "%filename%" | findstr /R /C:" R " >nul
if errorlevel 1 (
    set "SettingsAreLocked=0"
    echo [31m[Your settings are not locked.][0m
) else (
    set "SettingsAreLocked=1"
    echo [32m[Your settings are locked.][0m
)
GOTO !RIP!

:LockSettings
set "filename=!RIOTDRIVE!:\Riot Games\League of Legends\Config\PersistedSettings.json"
attrib "%filename%" | findstr /R /C:" R " >nul

if errorlevel 1 (
    echo SETTINGS LOCKED
    attrib +R "%filename%"
) else (
    echo SETTINGS UNLOCKED
    attrib -R "%filename%"
)

pause
GOTO :EOF