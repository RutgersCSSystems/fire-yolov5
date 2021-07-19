#!/bin/bash

##/usr/share/bcc/tools/biolatency

sudo apt update

sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 4052245BD4284CDD
echo "deb https://repo.iovisor.org/apt/$(lsb_release -cs) $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/iovisor.list
sudo apt update
sudo apt-get install bcc-tools libbcc-examples blktrace collectl perf-tools-unstable nmon htop -y

echo 'export $PATH=/usr/share/bcc/tools:$PATH' >> ~/.bashrc
echo "source ~/.bashrc #do it before using biolatency"
