@echo off
echo "Configuring and building Thirdparty/DBoW2 ..."
cd Thirdparty\DBoW2
md build
cd build
cmake .. -G "NMake Makefiles" -DCMAKE_BUILD_TYPE=Release
nmake

cd ..\..\g2o
echo "Configuring and building Thirdparty/g2o ..."
md build
cd build
cmake .. -G "NMake Makefiles" -DCMAKE_BUILD_TYPE=Release
nmake

cd ..\..\Pangolin
echo "Configuring and building Thirdparty/Pangolin ..."
md build
cd build
cmake .. -G "NMake Makefiles" -DCMAKE_BUILD_TYPE=Release
nmake

cd ..\..\..\

echo "Uncompress vocabulary ..."

cd Vocabulary
tar -xf ORBvoc.txt.tar.gz
cd ..

echo "Configuring and building ORB_SLAM3 ..."
md build
cd build
cmake .. -G "NMake Makefiles" -DCMAKE_BUILD_TYPE=Release
nmake

echo "Converting vocabulary to binary"
cd ..\tools
call .\bin_vocabulary.exe

echo "Building ROS nodes & install to d:/ros_extpkg"
cd ..\Examples_old\ROS_WIN\ORB_SLAM3
md d:\ros_extpkg
md build
cd build
cmake .. -G "NMake Makefiles" -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=D:\ros_extpkg
nmake install

cd ..\..\..\..\