@echo off
cls
setlocal enabledelayedexpansion
set pathDataset=D:\Dl_Works\dataset\video\EuRoC
Rem machine_hall : MH  MH01_easy MH02_easy MH03_medium MH04_difficult MH05_difficult
Rem vicon_room1 : V1   V101_easy V102_medium V103_difficult
Rem vicon_room2 : V2   V201_easy V202_medium V203_difficult
set dataset=MH01_easy
Rem Monocular Monocular-Inertial Stereo Stereo-Inertial
set typeSensor=Monocular
set datasetUrl=http://robotics.ethz.ch/~asl-datasets/ijrr_euroc_mav_dataset

set typeSess=multi_sess
set datasetlist=
set fileGt=!dataset:~0,4!_GT.txt
if "!typeSensor:~-8!"=="Inertial" (
    set fileGt=.\evaluation\Ground_truth\EuRoC_imu\!fileGt!
) else (
    set fileGt=.\evaluation\Ground_truth\EuRoC_left_cam\!fileGt!
)
if "!dataset!"=="MH" (
    set datasetlist=MH01_easy,MH02_easy,MH03_medium,MH04_difficult,MH05_difficult
) else if "!dataset!"=="V1" (
    set datasetlist=V101_easy,V102_medium,V103_difficult
) else if "!dataset!"=="V2" (
    set datasetlist=V201_easy,V202_medium,V203_difficult
) else (
    set typeSess=single_sess
    set datasetlist=!dataset!
    if "!typeSensor:~-8!"=="Inertial" (
        set fileGt=!pathDataset!\!dataset:~0,2!_!dataset:~2!\mav0\state_groundtruth_estimate0\data.csv
    )
)

set pathExe=.\Examples\!typeSensor!
set argsExe=.\Vocabulary\ORBvoc.txt !pathExe!\EuRoC.yaml
for %%i in (!datasetlist!) do (
    set splited=%%i
    set typeDataset=!splited:~0,2!
    set nameDataset=!typeDataset!_!splited:~2!
    set argsExe=!argsExe! !pathDataset!\!nameDataset! !pathExe!\EuRoC_TimeStamps\!splited:~0,4!.txt
    set full_name=
    if "!typeDataset!"=="MH" (
        set full_name=machine_hall
    ) else if "!typeDataset!"=="V1" (
        set full_name=vicon_room1
    ) else if "!typeDataset!"=="V2" (
        set full_name=vicon_room2
    ) else (
        echo only support MH V1 V2 & exit /b 1
    )
    if not exist !pathDataset!\!nameDataset!\ (
        if not exist !pathDataset!\ ( echo mkddir !pathDataset! & md !pathDataset! )
        echo download dataset from !datasetUrl!/!full_name!/!nameDataset!/!nameDataset!.zip
        call wget -P !pathDataset! -q -c --show-progress !datasetUrl!/!full_name!/!nameDataset!/!nameDataset!.zip
        if errorlevel 1 (echo download fail & exit /b 1)

        echo extract !nameDataset!.zip to !pathDataset!
        call unzip -n -q !pathDataset!\!nameDataset!.zip -d !pathDataset!\!nameDataset!
        if errorlevel 1 (echo extract fail & exit /b 1)

        del !pathDataset!\!nameDataset!.zip
        if errorlevel 1 (echo delete .zip fail & exit /b 1)
    )
)

set nameExe=
if "!typeSensor!"=="Monocular" (
    set nameExe=mono_euroc
) else if "!typeSensor!"=="Monocular-Inertial" (
    set nameExe=mono_inertial_euroc
) else if "!typeSensor!"=="Stereo" (
    set nameExe=stereo_euroc
) else if "!typeSensor!"=="Stereo-Inertial" (
    set nameExe=stereo_inertial_euroc
) else (
     echo !typeSensor! not support & exit /b 1
)

Rem convert to lowercase
set nameTrajectory=!dataset!
for %%i in (a b c d e f g h i j k l m n o p q r s t u v w x y z) do (
    call set nameTrajectory=!!nameTrajectory:%%i=%%i!!
)
set nameTrajectory=!nameTrajectory!_!nameExe!_!typeSess!

echo run !pathExe!\!nameExe!.exe !argsExe! !nameTrajectory!
call !pathExe!\!nameExe!.exe !argsExe! !nameTrajectory!
if errorlevel 1 (echo run slam fail & exit /b 1)

echo Evaluation of EuRoC trajectory with ground truth
if not exist .\evo_result\ md .\evo_result
call evo_ape.exe euroc !fileGt! f_!nameTrajectory!.txt ^
    -r full -va --plot --plot_mode xyz ^
    --save_plot .\evo_result\!nameTrajectory!_ape ^
    --save_results .\evo_result\!nameTrajectory!_ape.zip
if errorlevel 1 (echo run evo_ape evaluation fail & exit /b 1)

call evo_rpe.exe euroc !fileGt! f_!nameTrajectory!.txt ^
    -r angle_deg --delta 1 --delta_unit m -va ^
    --plot --plot_mode xyz ^
    --save_plot .\evo_result\!nameTrajectory!_rpe ^
    --save_results .\evo_result\!nameTrajectory!_rpe.zip
if errorlevel 1 (echo run evo_rpe evaluation fail & exit /b 1)

endlocal
exit /b 0