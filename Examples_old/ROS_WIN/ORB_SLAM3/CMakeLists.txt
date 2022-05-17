cmake_minimum_required(VERSION 2.4.6)
project(orb_slam3)

SET(CMAKE_BUILD_TYPE Release)

MESSAGE("Build type: " ${CMAKE_BUILD_TYPE})

set (CMAKE_CXX_STANDARD 11)
set (CMAKE_CXX_STANDARD_REQUIRED TRUE)
set (CMAKE_CXX_EXTENSIONS FALSE)

add_definitions(/D_SILENCE_ALL_CXX11_DEPRECATION_WARNINGS /DBOOST_BIND_GLOBAL_PLACEHOLDERS)
add_compile_options(/EHsc)
add_definitions(-DCOMPILEDWITHC11)

#set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS}  -W0 -MT -bigobj")
#set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} /EHsc -W0 -MT -bigobj")

#set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS}  -Wall  -O3 -march=native ")
#set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wall  -O3 -march=native")

# Check C++11 or C++0x support
#include(CheckCXXCompilerFlag)
#CHECK_CXX_COMPILER_FLAG("-std=c++11" COMPILER_SUPPORTS_CXX11)
#CHECK_CXX_COMPILER_FLAG("-std=c++0x" COMPILER_SUPPORTS_CXX0X)
#if(COMPILER_SUPPORTS_CXX11)
#   set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++11")
#   add_definitions(-DCOMPILEDWITHC11)
#   message(STATUS "Using flag -std=c++11.")
#elseif(COMPILER_SUPPORTS_CXX0X)
#   set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++0x")
#   add_definitions(-DCOMPILEDWITHC0X)
#   message(STATUS "Using flag -std=c++0x.")
#else()
#   add_definitions(-DCOMPILEDWITHC11)
#   message(FATAL_ERROR "The compiler ${CMAKE_CXX_COMPILER} has no C++11 support. Please use a different C++ compiler.")
#endif()

LIST(APPEND CMAKE_MODULE_PATH ${PROJECT_SOURCE_DIR}/../../../cmake_modules)

find_package(catkin REQUIRED COMPONENTS
  roscpp tf sensor_msgs image_transport cv_bridge)

find_package(OpenCV 4)
   if(NOT OpenCV_FOUND)
      message(FATAL_ERROR "OpenCV > 4.4 not found.")
   endif()

find_package(Boost REQUIRED system serialization)

find_package(Eigen3 3.1.0 REQUIRED)
set(Pangolin_DIR ${PROJECT_SOURCE_DIR}/../../../Thirdparty/Pangolin/build/src)
find_package(Pangolin REQUIRED)
find_package(OpenSSL REQUIRED Crypto)

catkin_package(
  CATKIN_DEPENDS roscpp tf sensor_msgs image_transport cv_bridge
  )

include_directories(
${catkin_INCLUDE_DIRS}
${PROJECT_SOURCE_DIR}
${PROJECT_SOURCE_DIR}/../../../
${PROJECT_SOURCE_DIR}/../../../include
${PROJECT_SOURCE_DIR}/../../../include/CameraModels
${PROJECT_SOURCE_DIR}/../../../Thirdparty/Sophus
${Pangolin_INCLUDE_DIRS}
)

set(LIBS 
${OpenCV_LIBS} 
${EIGEN3_LIBS}
${Pangolin_LIBRARIES}
${PROJECT_SOURCE_DIR}/../../../Thirdparty/DBoW2/lib/DBoW2.lib
${PROJECT_SOURCE_DIR}/../../../Thirdparty/g2o/lib/g2o.lib
${PROJECT_SOURCE_DIR}/../../../lib/ORB_SLAM3.lib
#-lboost_system
${Boost_LIBRARIES}
${OPENSSL_CRYPTO_LIBRARY}
${catkin_LIBRARIES}
)

# Node for monocular camera
add_executable(Mono
src/ros_mono.cc
)

target_link_libraries(Mono
${LIBS}
)

# Node for monocular camera (Augmented Reality Demo)
add_executable(MonoAR
src/AR/ros_mono_ar.cc
src/AR/ViewerAR.h
src/AR/ViewerAR.cc
)

target_link_libraries(MonoAR
${LIBS}
)

# Node for stereo camera
add_executable(Stereo
src/ros_stereo.cc
)

target_link_libraries(Stereo
${LIBS}
)

# Node for RGB-D camera
add_executable(RGBD
src/ros_rgbd.cc
)

target_link_libraries(RGBD
${LIBS}
)

# Node for monocular-inertial camera
add_executable(Mono_Inertial
src/ros_mono_inertial.cc
)

target_link_libraries(Mono_Inertial
${LIBS}
)

# Node for stereo-inertial camera
add_executable(Stereo_Inertial
src/ros_stereo_inertial.cc
)

target_link_libraries(Stereo_Inertial
${LIBS}
)

#add_custom_command(TARGET Stereo_Inertial POST_BUILD
#  COMMAND ${CMAKE_COMMAND} -E copy_if_different
#  ${Camera_Model_DLLS} ${CMAKE_RUNTIME_OUTPUT_DIRECTORY})

#${PROJECT_SOURCE_DIR}/../../Monocular-Inertial/*.yaml  ${LIBRARY_OUTPUT_PATH})
#############
## Install ##
#############
install(TARGETS Mono MonoAR Stereo RGBD Mono_Inertial Stereo_Inertial
  ARCHIVE DESTINATION ${CATKIN_PACKAGE_LIB_DESTINATION}
  LIBRARY DESTINATION ${CATKIN_PACKAGE_LIB_DESTINATION}
  RUNTIME DESTINATION ${CATKIN_PACKAGE_BIN_DESTINATION}
  )

# add yaml file
install(DIRECTORY ${PROJECT_SOURCE_DIR}/../../Monocular
  DESTINATION ${CATKIN_PACKAGE_SHARE_DESTINATION}/config
  FILES_MATCHING
  PATTERN "*.yaml"
  #PATTERN "*.txt"
  #PATTERN "*.cc" EXCLUDE
  )

install(DIRECTORY ${PROJECT_SOURCE_DIR}/../../Monocular-Inertial
  DESTINATION ${CATKIN_PACKAGE_SHARE_DESTINATION}/config
  FILES_MATCHING
  PATTERN "*.yaml"
  #PATTERN "*.txt"
  #PATTERN "*.cc" EXCLUDE
  )

install(DIRECTORY ${PROJECT_SOURCE_DIR}/../../Stereo
  DESTINATION ${CATKIN_PACKAGE_SHARE_DESTINATION}/config
  FILES_MATCHING
  PATTERN "*.yaml"
  #PATTERN "*.txt"
  #PATTERN "*.cc" EXCLUDE
  )

install(DIRECTORY ${PROJECT_SOURCE_DIR}/../../Stereo-Inertial
  DESTINATION ${CATKIN_PACKAGE_SHARE_DESTINATION}/config
  FILES_MATCHING
  PATTERN "*.yaml"
  #PATTERN "*.txt"
  #PATTERN "*.cc" EXCLUDE
  )

install(DIRECTORY ${PROJECT_SOURCE_DIR}/../../RGB-D
  DESTINATION ${CATKIN_PACKAGE_SHARE_DESTINATION}/config
  FILES_MATCHING
  PATTERN "*.yaml"
  #PATTERN "*.txt"
  #PATTERN "*.cc" EXCLUDE
  )

install(DIRECTORY ${PROJECT_SOURCE_DIR}/../../RGB-D-Inertial
  DESTINATION ${CATKIN_PACKAGE_SHARE_DESTINATION}/config
  FILES_MATCHING
  PATTERN "*.yaml"
  #PATTERN "*.txt"
  #PATTERN "*.cc" EXCLUDE
  )

install(DIRECTORY launch
  DESTINATION ${CATKIN_PACKAGE_SHARE_DESTINATION}
  )

install(FILES Asus.yaml ${PROJECT_SOURCE_DIR}/../../../Vocabulary/ORBvoc.txt
  DESTINATION ${CATKIN_PACKAGE_SHARE_DESTINATION}
  )
