#!/bin/bash
sudo route add -net 10.42.1.0 gw 192.168.7.10 netmask 255.255.255.0 eno1
sudo route add -net 10.42.2.0 gw 192.168.7.10 netmask 255.255.255.0 eno1
export ROS_IP=192.168.30.123 # change here 
export ROS_MASTER_URI=http://192.168.7.10:11311
