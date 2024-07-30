#!/bin/bash

# Requires the follow enviroment vartiables to be set:
#  1.APPS
sudo apt update
sudo apt upgrade 
sudo apt install -y ubuntu-drivers-common
sudo ubuntu-drivers devices
sudo apt install -y nvidia-driver-535
sudo apt install -y nvidia-cuda-toolkit
#sudo reboot now

