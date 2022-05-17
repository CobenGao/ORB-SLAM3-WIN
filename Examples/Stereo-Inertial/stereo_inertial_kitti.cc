/**
* This file is part of ORB-SLAM3
*
* Copyright (C) 2017-2020 Carlos Campos, Richard Elvira, Juan J. Gómez Rodríguez, José M.M. Montiel and Juan D. Tardós, University of Zaragoza.
* Copyright (C) 2014-2016 Raúl Mur-Artal, José M.M. Montiel and Juan D. Tardós, University of Zaragoza.
*
* ORB-SLAM3 is free software: you can redistribute it and/or modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation, either version 3 of the License, or
* (at your option) any later version.
*
* ORB-SLAM3 is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
* the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
* GNU General Public License for more details.
*
* You should have received a copy of the GNU General Public License along with ORB-SLAM3.
* If not, see <http://www.gnu.org/licenses/>.
*/

#include <iostream>
#include <algorithm>
#include <fstream>
#include <chrono>
#include <ctime>
#include <sstream>

#include<opencv2/core/core.hpp>

#include<System.h>
#include "ImuTypes.h"

using namespace std;

void LoadImages(const string &strPathLeft, const string &strPathRight, const string &strPathTimes,
                vector<string> &vstrImageLeft, vector<string> &vstrImageRight, vector<double> &vTimeStamps);

void LoadIMU(const string &strImuPath, vector<double> &vTimeStamps, vector<cv::Point3f> &vAcc, vector<cv::Point3f> &vGyro);

uint64_t ParseTime(std::string dt_str);


int main(int argc, char **argv)
{
    if(argc < 5)
    {
        cerr << endl << "Usage: ./stereo_inertial_kitti_vi path_to_vocabulary path_to_settings path_to_image_folder_1 path_to_image_folder_2 path_to_times_file path_to_imu_data (trajectory_file_name)" << endl;
        return 1;
    }

    const int num_seq = (argc-3)/4;
    cout << "num_seq = " << num_seq << endl;
    bool bFileName= (((argc-3) % 4) == 1);
    string file_name;
    if (bFileName)
    {
        file_name = string(argv[argc-1]);
        cout << "file name: " << file_name << endl;
    }

    // Load all sequences:
    int seq;
    vector< vector<string> > vstrImageLeftFilenames;
    vector< vector<string> > vstrImageRightFilenames;
    vector< vector<double> > vTimestampsCam;
    vector< vector<cv::Point3f> > vAcc, vGyro;
    vector< vector<double> > vTimestampsImu;
    vector<int> nImages;
    vector<int> nImu;
    vector<int> first_imu(num_seq,0);


    vstrImageLeftFilenames.resize(num_seq);
    vstrImageRightFilenames.resize(num_seq);
    vTimestampsCam.resize(num_seq);
    vAcc.resize(num_seq);
    vGyro.resize(num_seq);
    vTimestampsImu.resize(num_seq);
    nImages.resize(num_seq);
    nImu.resize(num_seq);

    int tot_images = 0;
    for (seq = 0; seq<num_seq; seq++)
    {
        cout << "Loading images for sequence " << seq << "...";

        LoadImages(string(argv[4*(seq+1)-1]), string(argv[4*(seq+1)]), string(argv[4*(seq+1)+1]), vstrImageLeftFilenames[seq], vstrImageRightFilenames[seq], vTimestampsCam[seq]);
        cout << "LOADED!" << endl;

        cout << "Loading IMU for sequence " << seq << "...";
        LoadIMU(string(argv[4*(seq+1)+2]), vTimestampsImu[seq], vAcc[seq], vGyro[seq]);
        cout << "LOADED!" << endl;

        nImages[seq] = vstrImageLeftFilenames[seq].size();
        tot_images += nImages[seq];
        nImu[seq] = vTimestampsImu[seq].size();

        if((nImages[seq]<=0)||(nImu[seq]<=0))
        {
            cerr << "ERROR: Failed to load images or IMU for sequence" << seq << endl;
            return 1;
        }

        // Find first imu to be considered, supposing imu measurements start first

        while(vTimestampsImu[seq][first_imu[seq]]<=vTimestampsCam[seq][0])
            first_imu[seq]++;
        first_imu[seq]--; // first imu measurement to be considered
    }

    // Read rectification parameters
    cv::FileStorage fsSettings(argv[2], cv::FileStorage::READ);
    if(!fsSettings.isOpened())
    {
        cerr << "ERROR: Wrong path to settings" << endl;
        return -1;
    }

    cv::Mat K_l, K_r, P_l, P_r, R_l, R_r, D_l, D_r;
    fsSettings["LEFT.K"] >> K_l;
    fsSettings["RIGHT.K"] >> K_r;

    fsSettings["LEFT.P"] >> P_l;
    fsSettings["RIGHT.P"] >> P_r;

    fsSettings["LEFT.R"] >> R_l;
    fsSettings["RIGHT.R"] >> R_r;

    fsSettings["LEFT.D"] >> D_l;
    fsSettings["RIGHT.D"] >> D_r;

    int rows_l = fsSettings["LEFT.height"];
    int cols_l = fsSettings["LEFT.width"];
    int rows_r = fsSettings["RIGHT.height"];
    int cols_r = fsSettings["RIGHT.width"];

    if(K_l.empty() || K_r.empty() || P_l.empty() || P_r.empty() || R_l.empty() || R_r.empty() || D_l.empty() || D_r.empty() ||
            rows_l==0 || rows_r==0 || cols_l==0 || cols_r==0)
    {
        cerr << "ERROR: Calibration parameters to rectify stereo are missing!" << endl;
        return -1;
    }

    cv::Mat M1l,M2l,M1r,M2r;
    cv::initUndistortRectifyMap(K_l,D_l,R_l,P_l.rowRange(0,3).colRange(0,3),cv::Size(cols_l,rows_l),CV_32F,M1l,M2l);
    cv::initUndistortRectifyMap(K_r,D_r,R_r,P_r.rowRange(0,3).colRange(0,3),cv::Size(cols_r,rows_r),CV_32F,M1r,M2r);

    // Vector for tracking time statistics
    vector<float> vTimesTrack;
    vTimesTrack.resize(tot_images);

    cout << endl << "-------" << endl;
    cout.precision(17);

    // Create SLAM system. It initializes all system threads and gets ready to process frames.
    ORB_SLAM3::System SLAM(argv[1],argv[2],ORB_SLAM3::System::IMU_STEREO, true);

    cv::Mat imLeft, imRight, imLeftRect, imRightRect;
    for (seq = 0; seq<num_seq; seq++)
    {
        // Seq loop
        vector<ORB_SLAM3::IMU::Point> vImuMeas;
        double t_rect = 0;
        int num_rect = 0;
        int proccIm = 0;
        for(int ni=0; ni<nImages[seq]; ni++, proccIm++)
        {
            // Read left and right images from file
            imLeft = cv::imread(vstrImageLeftFilenames[seq][ni],cv::IMREAD_UNCHANGED);
            imRight = cv::imread(vstrImageRightFilenames[seq][ni],cv::IMREAD_UNCHANGED);

            if(imLeft.empty())
            {
                cerr << endl << "Failed to load image at: "
                     << string(vstrImageLeftFilenames[seq][ni]) << endl;
                return 1;
            }

            if(imRight.empty())
            {
                cerr << endl << "Failed to load image at: "
                     << string(vstrImageRightFilenames[seq][ni]) << endl;
                return 1;
            }


    #ifdef COMPILEDWITHC11
            std::chrono::steady_clock::time_point t_Start_Rect = std::chrono::steady_clock::now();
    #else
            std::chrono::monotonic_clock::time_point t_Start_Rect = std::chrono::monotonic_clock::now();
    #endif
            cv::remap(imLeft,imLeftRect,M1l,M2l,cv::INTER_LINEAR);
            cv::remap(imRight,imRightRect,M1r,M2r,cv::INTER_LINEAR);

    #ifdef COMPILEDWITHC11
            std::chrono::steady_clock::time_point t_End_Rect = std::chrono::steady_clock::now();
    #else
            std::chrono::monotonic_clock::time_point t_End_Rect = std::chrono::monotonic_clock::now();
    #endif

            t_rect = std::chrono::duration_cast<std::chrono::duration<double> >(t_End_Rect - t_Start_Rect).count();
            double tframe = vTimestampsCam[seq][ni];

            // Load imu measurements from previous frame
            vImuMeas.clear();

            if(ni>0)
                while(vTimestampsImu[seq][first_imu[seq]]<=vTimestampsCam[seq][ni]) // while(vTimestampsImu[first_imu]<=vTimestampsCam[ni])
                {
                    vImuMeas.push_back(ORB_SLAM3::IMU::Point(vAcc[seq][first_imu[seq]].x,vAcc[seq][first_imu[seq]].y,vAcc[seq][first_imu[seq]].z,
                                                             vGyro[seq][first_imu[seq]].x,vGyro[seq][first_imu[seq]].y,vGyro[seq][first_imu[seq]].z,
                                                             vTimestampsImu[seq][first_imu[seq]]));
                    first_imu[seq]++;
                }

    #ifdef COMPILEDWITHC11
            std::chrono::steady_clock::time_point t1 = std::chrono::steady_clock::now();
    #else
            std::chrono::monotonic_clock::time_point t1 = std::chrono::monotonic_clock::now();
    #endif

            // Pass the images to the SLAM system
            SLAM.TrackStereo(imLeftRect,imRightRect,tframe,vImuMeas);

    #ifdef COMPILEDWITHC11
            std::chrono::steady_clock::time_point t2 = std::chrono::steady_clock::now();
    #else
            std::chrono::monotonic_clock::time_point t2 = std::chrono::monotonic_clock::now();
    #endif

            double ttrack= std::chrono::duration_cast<std::chrono::duration<double> >(t2 - t1).count();

            vTimesTrack[ni]=ttrack;

            // Wait to load the next frame
            double T=0;
            if(ni<nImages[seq]-1)
                T = vTimestampsCam[seq][ni+1]-tframe;
            else if(ni>0)
                T = tframe-vTimestampsCam[seq][ni-1];

            if(ttrack<T)
                usleep((T-ttrack)*1e6); // 1e6
        }

        if(seq < num_seq - 1)
        {
            cout << "Changing the dataset" << endl;

            SLAM.ChangeDataset();
        }


    }
    // Stop all threads
    SLAM.Shutdown();


    // Save camera trajectory
    if (bFileName)
    {
        const string kf_file =  "kf_" + string(argv[argc-1]) + ".txt";
        const string f_file =  "f_" + string(argv[argc-1]) + ".txt";
        SLAM.SaveTrajectoryEuRoC(f_file);
        SLAM.SaveKeyFrameTrajectoryEuRoC(kf_file);
    }
    else
    {
        SLAM.SaveTrajectoryEuRoC("CameraTrajectory.txt");
        SLAM.SaveKeyFrameTrajectoryEuRoC("KeyFrameTrajectory.txt");
    }

    return 0;
}

void LoadImages(const string &strPathLeft, const string &strPathRight, const string &strPathTimes,
                vector<string> &vstrImageLeft, vector<string> &vstrImageRight, vector<double> &vTimeStamps)
{
    ifstream fTimes;
    fTimes.open(strPathTimes.c_str());
    vTimeStamps.reserve(5000);
    vstrImageLeft.reserve(5000);
    vstrImageRight.reserve(5000);
    size_t counter = 0;
    while(!fTimes.eof())
    {
        string s;
        getline(fTimes,s);
        // If the last line reached
        if (s == "")
            break;
        // Use camera 0 timestamps as the timestamp for both cams
        // Time format: 2011-09-26 13:02:37.101745664
        auto ts0_ns = ParseTime(s);

        if(!s.empty())
        {
            stringstream ss;
            ss << std::setw(10) << std::setfill('0') << counter;
            vstrImageLeft.push_back(strPathLeft + "/" + ss.str() + ".png");
            vstrImageRight.push_back(strPathRight + "/" + ss.str() + ".png");
            double t;
            ss >> t;
            vTimeStamps.push_back((static_cast<double>(ts0_ns) / 1.0e9));
            counter++;
        }
    }
}

void LoadIMU(const string &strImuPath, vector<double> &vTimeStamps, vector<cv::Point3f> &vAcc, vector<cv::Point3f> &vGyro)
{
    ifstream fImu;
    fImu.open(strImuPath.c_str());
    vTimeStamps.reserve(5000);
    vAcc.reserve(5000);
    vGyro.reserve(5000);

    const auto strImuDataDir = strImuPath + "/data";
    const auto strImuTimestampsPath = strImuPath + "timestamps.txt";

    // Read imu timestamps
    ifstream fImuTimestamps(strImuTimestampsPath);
    string s;
    size_t counter = 0;
    while (getline(fImuTimestamps, s))
    {
        // time format: 2011-09-26 13:04:31.879697321
        auto timestampNs = ParseTime(s);
        // convert from nanosecond back to milisecond
        vTimeStamps.push_back(static_cast<double>(timestampNs) / 1.0e9);

        // load IMU data
        stringstream ss;
        ss << std::setw(10) << std::setfill('0') << counter;
        ifstream fCurrTimestamp(strImuDataDir + "/" + ss.str() + ".txt");
        
        std::string line;
        std::getline(fCurrTimestamp, line);
        
        string item;
        size_t pos = 0;
        double data[30];
        int count = 0;
        while ((pos = line.find(' ')) != string::npos) {
            item = line.substr(0, pos);
            data[count++] = stod(item);
            line.erase(0, pos + 1);
        }
        item = s.substr(0, pos);
        data[6] = stod(item);

        vAcc.push_back(cv::Point3f(data[11], data[12], data[13]));
        vGyro.push_back(cv::Point3f(data[17], data[18], data[19]));

        fCurrTimestamp.close();

        counter++;
    }
    fImuTimestamps.close();
}

uint64_t ParseTime(std::string dt_str) {
    // the string length must be consistent
    if (dt_str.size() != 29) {
        throw "Time is not in the right format";
    }
	int year, month, day;
	int hour, minute;
	double second;
    sscanf(dt_str.c_str(), "%d-%d-%d %d:%d:%lf", &year, &month, &day, &hour, &minute, &second);

    return (hour * 60 * 60 + minute * 60 + second) * 1e9;
}