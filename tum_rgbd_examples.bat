@echo off
cls
setlocal
set pathDataset=D:\Dl_Works\dataset\video\tum
Rem Testing and Debugging
Rem fr1_xyz fr1_rpy
Rem fr2_xyz fr2_rpy
Rem Handheld SLAM
Rem fr1_360 fr1_floor fr1_desk fr1_desk2 fr1_room
Rem fr2_360_hemisphere fr2_360_kidnap fr2_desk fr2_large_no_loop fr2_large_with_loop
Rem fr3_office
Rem Robot SLAM
Rem fr2_pioneer_360 fr2_pioneer_slam fr2_pioneer_slam2 fr2_pioneer_slam3
set dataset=fr2_pioneer_360
set datasetUrl=https://vision.in.tum.de/rgbd/dataset
Rem Monocular RGB-D
set typeSensor=Monocular

Rem kitti ground turth fromat:
Rem r11 r12 r13 tx r21 r22 r23 ty r31 r32 r33 tz

set tmp_str=%dataset%
set first_token=1
set nameDataset=rgbd_dataset
set configFile=
:split
for /f "tokens=1,* delims=_" %%i in ("%tmp_str%") do (
    if "%first_token%" == "1" (
        Rem fr     -> freiburg
        if "%%i" == "fr1" (
            set configFile=TUM1.yaml
            set nameDataset=%nameDataset%_freiburg1
            set datasetUrl=%datasetUrl%/freiburg1
        ) else if "%%i" == "fr2" (
            set configFile=TUM2.yaml
            set nameDataset=%nameDataset%_freiburg2
            set datasetUrl=%datasetUrl%/freiburg2
        ) else if "%%i" == "fr3" (
            set configFile=TUM3.yaml
            set nameDataset=%nameDataset%_freiburg3
            set datasetUrl=%datasetUrl%/freiburg3
        ) else (
            echo only support fr1,fr2,fr3 & exit /b 1
        )
        set first_token=0
    ) else (
        Rem cab    -> cabinet
        Rem val    -> validation
        Rem str    -> structure
        Rem nstr   -> nostructure
        Rem tex    -> texture
        Rem ntex   -> notexture
        Rem office -> long_office_household
        if "%%i" == "cab" (
            set nameDataset=%nameDataset%_cabinet
        ) else if "%%i" == "val" (
            set nameDataset=%nameDataset%_validation
        ) else if "%%i" == "str" (
            set nameDataset=%nameDataset%_structure
        ) else if "%%i" == "nstr" (
            set nameDataset=%nameDataset%_nostructure
        ) else if "%%i" == "tex" (
            set nameDataset=%nameDataset%_texture
        ) else if "%%i" == "ntex" (
            set nameDataset=%nameDataset%_notexture
        ) else if "%%i" == "office" (
            set nameDataset=%nameDataset%_long_office_household
        ) else (
            set nameDataset=%nameDataset%_%%i
        )
    )
  set tmp_str=%%j
)
if not "%tmp_str%"=="" goto split

echo dataset name: %nameDataset%

if not exist %pathDataset%\%nameDataset%\ (
    if not exist %pathDataset%\ ( echo mkddir %pathDataset% & md %pathDataset% )

    echo download dataset from %datasetUrl%/%nameDataset%.tgz
    call wget -P %pathDataset% -q -c --show-progress %datasetUrl%/%nameDataset%.tgz
    if errorlevel 1 (echo download fail & exit /b 1)

    echo extract %nameDataset%.tgz to %pathDataset%
    md %pathDataset%\%nameDataset%
    call tar -xf %pathDataset%\%nameDataset%.tgz -C %pathDataset%\%nameDataset% --strip-components 1
    if errorlevel 1 (echo extract fail & exit /b 1)

    del %pathDataset%\%nameDataset%.tgz
    if errorlevel 1 (echo delete .tgz fail & exit /b 1)
)

if not exist .\Examples\RGB-D\associations\%dataset%.txt (
    echo generate associate file
    call python .\evaluation\associate.py ^
        %pathDataset%\%nameDataset%\rgb.txt ^
        %pathDataset%\%nameDataset%\depth.txt ^
        > .\Examples\RGB-D\associations\%dataset%.txt
    if errorlevel 1 (
        echo generate file fail
        del .\Examples\RGB-D\associations\%dataset%.txt
        exit /b 1
    )
)

echo run rgbd_tum.exe
call .\Examples\RGB-D\rgbd_tum.exe ^
    .\Vocabulary\ORBvoc.txt ^
    .\Examples\RGB-D\%configFile% ^
    %pathDataset%\%nameDataset% ^
    .\Examples\RGB-D\associations\%dataset%.txt
if errorlevel 1 (echo run rgbd_tum.exe fail & exit /b 1)

if exist %pathDataset%\%nameDataset%\groundtruth.txt (
    echo Evaluation of %dataset% trajectory with ground truth
    if not exist .\evo_result\ md .\evo_result
    call evo_ape.exe tum %pathDataset%\%nameDataset%\groundtruth.txt CameraTrajectory.txt ^
        -r full -va --plot --plot_mode xyz ^
        --save_plot .\evo_result\%nameTrajectory%_ape ^
        --save_results .\evo_result\%nameTrajectory%_ape.zip
    if errorlevel 1 (echo run evo_ape evaluation fail & exit /b 1)

    call evo_rpe.exe tum %pathDataset%\%nameDataset%\groundtruth.txt CameraTrajectory.txt ^
        -r angle_deg --delta 1 --delta_unit m -va ^
        --plot --plot_mode xyz ^
        --save_plot .\evo_result\%nameTrajectory%_rpe ^
        --save_results .\evo_result\%nameTrajectory%_rpe.zip
    if errorlevel 1 (echo run evo_rpe evaluation fail & exit /b 1)
)

endlocal
exit /b 0
