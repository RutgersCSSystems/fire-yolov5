#!/bin/bash

# Requires the follow enviroment vartiables to be set:
#  1.APPS

sudo apt update
git clone https://github.com/ultralytics/yolov5
cd yolov5
pip install -r requirements.txt
sudo apt-get update && sudo apt-get install libgl1
