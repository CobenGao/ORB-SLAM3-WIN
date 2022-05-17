# ORB-SLAM3 base on Windows VS2019, ros-noetic-desktop_full and opencv4

### V1.0, December 22th, 2021

```
roscore
```
if use [EuRoC dataset](http://projects.asl.ethz.ch/datasets/doku.php?id=kmavvisualinertialdatasets)
```
roslaunch orb_slam3 Stereo_Inertial_EuRoC.launch
```
```
roslaunch orb_slam3 EuRoc_Dataset.launch dataset_bag:=<your euroc bag with dir>
```
Hit "space" on keyboard to start
if use  [TUM-VI dataset](https://vision.in.tum.de/data/datasets/visual-inertial-dataset)
```
rosrun rosbag fastrebag.py dataset-room1_512_16.bag dataset-room1_512_16_small_chunks.bag
```