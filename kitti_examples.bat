@echo off
cls
setlocal enabledelayedexpansion
set pathDataset=D:\Dl_Works\dataset\video\kitti
set dataset=07
Rem Monocular Stereo Stereo-Inertial
set typeSensor=Stereo-Inertial
set datasetUrl=https://s3.eu-central-1.amazonaws.com/avg-kitti
Rem data_odometry_gray data_odometry_color
set nameDataset=data_odometry_gray

if not exist %pathDataset%\%nameDataset%\ (
    if not exist %pathDataset%\ ( echo mkddir %pathDataset% & md %pathDataset% )
    Rem data_odometry_color.zip
    echo download dataset from %datasetUrl%/%nameDataset%.zip
    Rem call wget -P %pathDataset% -q -c --show-progress %datasetUrl%/%nameDataset%.zip
    Rem if errorlevel 1 (echo download fail & exit /b 1)
    echo extract %nameDataset%.zip to %pathDataset%
    call unzip -n -q %pathDataset%\%nameDataset%.zip -d %pathDataset%
    if errorlevel 1 (echo extract fail & exit /b 1)

    call rename %pathDataset%\dataset %nameDataset%
    if errorlevel 1 (echo dataset re-name fail & exit /b 1)

    Rem del %pathDataset%\%nameDataset%.zip
    Rem if errorlevel 1 (echo delete .zip fail & exit /b 1)
)

set nameRaw=
if "%typeSensor:~-8%"=="Inertial" (
    if "%dataset%"=="00" (
        set nameRaw=2011_10_03_drive_0027
    ) else if "%dataset%"=="01" (
        set nameRaw=2011_10_03_drive_0042
    ) else if "%dataset%"=="02" (
        set nameRaw=2011_10_03_drive_0034
    ) else if "%dataset%"=="03" (
        set nameRaw=2011_09_26_drive_0067
    ) else if "%dataset%"=="04" (
        set nameRaw=2011_09_30_drive_0016
    ) else if "%dataset%"=="05" (
        set nameRaw=2011_09_30_drive_0018
    ) else if "%dataset%"=="06" (
        set nameRaw=2011_09_30_drive_0020
    ) else if "%dataset%"=="07" (
        set nameRaw=2011_09_30_drive_0027
    ) else if "%dataset%"=="08" (
        set nameRaw=2011_09_30_drive_0028
    ) else if "%dataset%"=="09" (
        set nameRaw=2011_09_30_drive_0033
    ) else if "%dataset%"=="10" (
        set nameRaw=2011_09_30_drive_0034
    ) else (
        echo data_raw not support %dataset%
        exit /b 1
    )
    
    if not exist %pathDataset%\!nameRaw!_extract\ (
        echo download raw_data from %datasetUrl%/!nameRaw!/!nameRaw!_extract.zip
        Rem call wget -P %pathDataset% -q -c --show-progress %datasetUrl%/!nameRaw!/!nameRaw!_extract.zip
        Rem if errorlevel 1 (echo download fail & exit /b 1)

        echo extract !nameRaw!_extract.zip to %pathDataset%
        call unzip -n -q %pathDataset%\!nameRaw!_extract.zip -d %pathDataset%
        if errorlevel 1 (echo extract fail & exit /b 1)

        call move %pathDataset%\!nameRaw:~0,10!\!nameRaw!_extract %pathDataset%\!nameRaw!_extract
        if errorlevel 1 (echo move fail & exit /b 1)

        call rmdir /S /Q %pathDataset%\!nameRaw:~0,10!
        if errorlevel 1 (echo remove fail & exit /b 1)

        Rem del %pathDataset%\!nameRaw!_extract.zip
        Rem if errorlevel 1 (echo delete .zip fail & exit /b 1)
    )
)

set pathExe=.\Examples\%typeSensor%
set argsExe=.\Vocabulary\ORBvoc.txt
if %dataset% leq 02 (
    set argsExe=%argsExe% %pathExe%\KITTI00-02.yaml
) else if %dataset% equ 03 (
    set argsExe=%argsExe% %pathExe%\KITTI03.yaml
) else if %dataset% leq 12 (
    set argsExe=%argsExe% %pathExe%\KITTI04-12.yaml
) else (
    echo dataset not support %dataset%
    exit /b 1
)

set argsExe=%argsExe% %pathDataset%\dataset\sequences\%dataset%\
set nameExe=
if "%typeSensor%"=="Monocular" (
    set nameExe=mono_kitti
) else if "%typeSensor%"=="Stereo" (
    set nameExe=stereo_kitti
) else (
     echo %typeSensor% not support & exit /b 1
)

set nameTrajectory=%nameExe%_%dataset%

echo run %pathExe%\%nameExe%.exe %argsExe% %nameTrajectory%
Rem call %pathExe%\%nameExe%.exe %argsExe% %nameTrajectory%
Rem if errorlevel 1 (echo run slam fail & exit /b 1)

echo Evaluation of KITTI trajectory with ground truth
