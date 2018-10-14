#!/bin/bash

INSTALL_SYSTEM_LIBS(){
sudo apt-get install -y git
sudo apt-get install -y software-properties-common
sudo apt-get install -y python3-software-properties
sudo apt-get install -y python-software-properties
sudo apt-get install -y unzip
sudo apt-get install -y python-setuptools python-dev build-essential
sudo easy_install pip
sudo apt-get install -y numactl
sudo apt-get install -y libsqlite3-dev
sudo apt-get install -y libnuma-dev
sudo apt-get install -y cmake
sudo apt-get install -y build-essential
sudo apt-get install -y maven
sudo apt-get install -y fio
sudo apt-get install -y libbfio-dev
sudo apt-get install -y libboost-dev
sudo apt-get install -y libboost-thread-dev
sudo apt-get install -y libboost-system-dev
sudo apt-get install -y libboost-program-options-dev
sudo apt-get install -y libconfig-dev
sudo apt-get install -y uthash-dev
sudo apt-get install -y cscope
sudo apt-get install -y msr-tools
sudo apt-get install -y msrtool
sudo pip install psutil
#sudo pip install thrift_compiler
#INSTALL_JAVA
sudo apt-get -y install build-essential
sudo apt-get -y install libssl-dev
sudo apt-get install -y libgflags-dev
sudo apt-get install -y zlib1g-dev
sudo apt-get install -y libbz2-dev
sudo apt-get install -y libevent-dev
}

INSTALL_SPARK(){
sudo service docker stop
sudo apt-get remove docker docker.io
sudo rm -rf /var/lib/docker
sudo rm -rf $APPBENCH/docker
mkdir $APPBENCH/docker
sudo apt-get install docker docker.io
sudo service docker stop
sudo cp $SCRIPTS/daemon.json /etc/docker/daemon.json
sudo service docker start
sudo docker pull cloudsuite/graph-analytics
sudo docker pull cloudsuite/twitter-dataset-graph
}

INSTALL_GFLAGS(){
cd $SHARED_LIBS
git clone https://github.com/gflags/gflags.git
cd gflags
export CXXFLAGS="-fPIC" && cmake . -DCMAKE_INSTALL_PREFIX=/usr/local -DBUILD_SHARED_LIBS=ON && make -j16 && sudo make install
cd $APPBENCH/apps
git clone https://github.com/facebook/rocksdb
#cp $APPBENCH/apps/db_bench_tool.cc $APPBENCH/apps/rocksdb/tools/
cp $APPBENCH/apps/run_rocksdb.sh $APPBENCH/apps/rocksdb/build/run.sh
cd rocksdb
mkdir build 
cd build
cmake ..
make -j16
}


#Get Other Apps not in out Repo
GETAPPS(){
mkdir $APPBENCH
cd $APPBENCH
git clone https://github.com/SudarsunKannan/leveldb
mkdir $APPBENCH/apps
cd $APPBENCH/apps
git clone https://github.com/SudarsunKannan/fio
cd $APPBENCH/apps
git clone https://github.com/memcached/memcached.git
}

INSTALL_SYSTEM_LIBS
INSTALL_GFLAGS
INSTALL_SPARK

GETAPPS
# Set variable, setup packages and generate data
$SCRIPTS/compile_sharedlib.sh
$APPBENCH/setup.sh
$APPBENCH/compile_all.sh

#Compile Linux Kernel
#cd $KERN_SRC
#$SCRIPTS/compile_deb.sh

#Changing bandwidth of a NUMA node
$APPBENCH/install_quartz.sh
$APPBENCH/throttle.sh
$APPBENCH/throttle.sh



