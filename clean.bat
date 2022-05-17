echo "clean all build files"

del Vocabulary\ORBvoc.txt

del Examples\Calibration\*.exe*
del Examples\Monocular\*.exe*
del Examples\Monocular-Inertial\*.exe*
del Examples\RGB-D\*.exe*
del Examples\RGB-D-Inertial\*.exe*
del Examples\Stereo\*.exe*
del Examples\Stereo-Inertial\*.exe*

del Examples_old\Monocular\*.exe*
del Examples_old\Monocular-Inertial\*.exe*
del Examples_old\RGB-D\*.exe*
del Examples_old\RGB-D-Inertial\*.exe*
del Examples_old\Stereo\*.exe*
del Examples_old\Stereo-Inertial\*.exe*

rmdir /S /Q build lib
rmdir /S /Q Thirdparty\DBoW2\build Thirdparty\DBoW2\lib
rmdir /S /Q Thirdparty\g2o\build Thirdparty\g2o\lib
rmdir /S /Q Thirdparty\Pangolin\lib Thirdparty\Pangolin\build
rmdir /S /Q Examples_old\ROS_WIN\ORB_SLAM3\build

rmdir /S /Q evaluation\__pycache__
del CameraTrajectory.txt KeyFrameTrajectory.txt
del f_*.txt kf_*.txt
rmdir /S /Q evo_result
