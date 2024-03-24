#!/bin/bash

# Requires the follow enviroment vartiables to be set:
#  1.APPS
sudo apt update
sudo apt upgrade 
sudo apt install ubuntu-drivers-common
sudo ubuntu-drivers devices
sudo apt install nvidia-driver-535
sudo apt install nvidia-cuda-toolkit
#sudo reboot now

