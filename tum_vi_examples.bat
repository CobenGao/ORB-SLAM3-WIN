@echo off
cls
setlocal
set pathDataset=D:\Dl_Works\dataset\video\tum

Rem corridor1_512 corridor2_512 corridor3_512 corridor4_512 corridor5_512
Rem magistrale2_512 magistrale3_512 magistrale4_512 magistrale5_512 magistrale6_512
Rem outdoors1_512 outdoors2_512 outdoors3_512 outdoors4_512 outdoors5_512 outdoors6_512 outdoors7_512 outdoors8_512
Rem room1_512 room2_512 room3_512 room4_512 room5_512 room6_512
Rem slides1_512 slides2_512 slides3_512
set dataset=room3_512
Rem Monocular Monocular-Inertial Stereo Stereo-Inertial
set typeSensor=Monocular-Inertial
set datasetUrl=https://vision.in.tum.de/tumvi/exported/euroc

set tmp_str=%dataset%
set pic_res=
:split
for /f "tokens=1,* delims=_" %%i in ("%tmp_str%") do (
  set pic_res=%%i
  set tmp_str=%%j
)
if not "%tmp_str%"=="" goto split

set datasetUrl=%datasetUrl%/%pic_res%_16
set nameDataset=%dataset%_16

if not exist %pathDataset%\%nameDataset%\ (
    if not exist %pathDataset%\ ( echo mkddir %pathDataset% & md %pathDataset% )
    echo download dataset from %datasetUrl%/dataset-%nameDataset%.tar
    call wget -P %pathDataset% -q -c --show-progress %datasetUrl%/dataset-%nameDataset%.tar
    if errorlevel 1 (echo download fail & exit /b 1)

    echo extract dataset-%nameDataset%.tar to %pathDataset%
    md %pathDataset%\%nameDataset%
    call tar -xvf %pathDataset%\dataset-%nameDataset%.tar -C %pathDataset%\%nameDataset% --strip-components 1
    if errorlevel 1 (echo extract fail & exit /b 1)
    del %pathDataset%\dataset-%nameDataset%.tar
    if errorlevel 1 (echo delete .tar fail & exit /b 1)
    cls
)

set pathExe=.\Examples\%typeSensor%
set argsExe=.\Vocabulary\ORBvoc.txt %pathExe%\TUM-VI.yaml %pathDataset%\%nameDataset%\mav0\cam0\data
set nameExe=
if "%typeSensor%"=="Monocular" (
    set nameExe=mono_tum_vi
    set argsExe=%argsExe%  %pathExe%\TUM_TimeStamps\dataset-%dataset%.txt
) else if "%typeSensor%"=="Monocular-Inertial" (
    set nameExe=mono_inertial_tum_vi
    set argsExe=%argsExe%  %pathExe%\TUM_TimeStamps\dataset-%dataset%.txt %pathExe%\TUM_IMU\dataset-%dataset%.txt
) else if "%typeSensor%"=="Stereo" (
    set nameExe=stereo_tum_vi
    set argsExe=%argsExe%  %pathExe%\TUM_TimeStamps\dataset-%dataset%.txt
) else if "%typeSensor%"=="Stereo-Inertial" (
    set nameExe=stereo_inertial_tum_vi
    set argsExe=%argsExe%  %pathExe%\TUM_TimeStamps\dataset-%dataset%.txt %pathExe%\TUM_IMU\dataset-%dataset%.txt
) else (
     echo %typeSensor% not support & exit /b 1
)

echo run mono_inertial_tum_vi.exe
call .\Examples\Monocular-Inertial\mono_inertial_tum_vi.exe ^
    .\Vocabulary\ORBvoc.txt ^
    .\Examples\Monocular-Inertial\%configFile% ^
    .\Examples\Monocular-Inertial\TUM_TimeStamps\dataset-%dataset%.txt ^
    .\Examples\Monocular-Inertial\TUM_IMU\dataset-%dataset%.txt ^
    tum_vi_%dataset%
if errorlevel 1 (echo run rgbd_tum.exe fail & exit /b 1)

echo Evaluation of tum_vi_%dataset% trajectory with ground truth
if not exist .\evo_result\ md .\evo_result

call evo_ape.exe euroc %pathDataset%\%nameDataset%\mav0\mocap0\data.csv f_tum_vi_%dataset%.txt ^
    -r full -va --plot --plot_mode xyz ^
    --save_plot .\evo_result\%dataset%_ape ^
    --save_results .\evo_result\%dataset%_ape.zip
if errorlevel 1 (echo run evo_ape evaluation fail & exit /b 1)

call evo_rpe.exe euroc %pathDataset%\%nameDataset%\mav0\mocap0\data.csv f_tum_vi_%dataset%.txt ^
    -r angle_deg --delta 1 --delta_unit m -va ^
    --plot --plot_mode xyz ^
    --save_plot .\evo_result\%dataset%_rpe ^
    --save_results .\evo_result\%dataset%_rpe.zip
if errorlevel 1 (echo run evo_rpe evaluation fail & exit /b 1)

endlocal
exit /b 0