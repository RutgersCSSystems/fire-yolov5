#!/bin/bash
set -x

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
sudo add-apt-repository ppa:webupd8team/java
sudo apt-get update
sudo apt-get install -y openjdk-8-jdk
sudo apt-get -y install build-essential
sudo apt-get -y install libssl-dev
sudo apt-get install -y libgflags-dev
sudo apt-get install -y zlib1g-dev
sudo apt-get install -y libbz2-dev
sudo apt-get install -y libevent-dev
sudo apt-get install -y systemd
#sudo apt-get install memcached
sudo apt-get install libaio*
sudo apt-get install software-properties-common
}

INSTALL_SPARK(){
sudo service docker stop
sudo apt-get -y remove docker docker.io
sudo rm -rf /var/lib/docker $APPBENCH/docker
mkdir $APPBENCH/docker
sudo apt-get -y install docker docker.io
sudo service docker stop
sudo cp scripts/docker_new.service /lib/systemd/system/docker.service
sudo systemctl daemon-reload
sudo service docker start
sudo docker pull cloudsuite/graph-analytics
sudo docker pull cloudsuite/twitter-dataset-graph
}

INSTALL_CMAKE(){
    cd $SHARED_LIBS
    wget https://cmake.org/files/v3.7/cmake-3.7.0-rc3.tar.gz
    tar zxvf cmake-3.7.0-rc3.tar.gz
    cd cmake-3.7.0-rc3
    rm -rf CMakeCache*
    ./configure
    ./bootstrap
    make -j16
    sudo make install
}

INSTALL_SYSBENCH() {
        curl -s https://packagecloud.io/install/repositories/akopytov/sysbench/script.deb.sh | sudo bash
        sudo apt -y install sysbench
}

INSTALL_MYSQL() {
        sudo apt-get install mysql-server-5.7

	# change datadir to ssd	
	sudo systemctl stop mysql
	sudo rsync -av /var/lib/mysql $SSD/mysql
	sudo mv /var/lib/mysql /var/lib/mysql.bak
	sed -i '/datadir/d' /etc/mysql/mysql.conf.d/mysqld.cnf | cat -n
	echo 'datadir = $SSD/mysql/mysql' >> /etc/mysql/mysql.conf.d/mysqld.cnf
	echo 'alias /var/lib/mysql/ -> $SSD/mysql,' >> /etc/apparmor.d/tunables/alias
	sudo systemctl restart apparmor
	sudo mkdir /var/lib/mysql/mysql -p
	sudo systemctl start mysql
}

ADD_SPARK_TO_BASHRC() {
	echo "export SPARK_HOME=/users/skannan/ssd/NVM/appbench/apps/spark" &>> ~/.bashrc
	echo "export PATH=$PATH:$SPARK_HOME/bin:$SPARK_HOME/sbin" &>> ~/.bashrc
	echo "export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64/jre" &>> ~/.bashrc
	echo "export HADOOP_HOME=$SPARK_HOME/hadoop-3.2.1" &>> ~/.bashrc
	echo "export HADOOP_INSTALL=$HADOOP_HOME" &>> ~/.bashrc
	echo "export HADOOP_MAPRED_HOME=$HADOOP_HOME" &>> ~/.bashrc
	echo "export HADOOP_COMMON_HOME=$HADOOP_HOME" &>> ~/.bashrc
	echo "export HADOOP_HDFS_HOME=$HADOOP_HOME" &>> ~/.bashrc
	echo "export YARN_HOME=$HADOOP_HOME" &>> ~/.bashrc
	echo "export HADOOP_COMMON_LIB_NATIVE_DIR=$HADOOP_HOME/lib/native" &>> ~/.bashrc
	echo "export PATH=$PATH:$HADOOP_HOME/sbin:$HADOOP_HOME/bin" &>> ~/.bashrc
	echo "export HADOOP_OPTS="-Djava.library.path=$HADOOP_HOME/lib/native"" &>> ~/.bashrc
}

INSTALL_SPARK_HIBENCH(){
	cd $APPBENCH/apps
	SPARKFILE=spark-2.4.4-bin-hadoop2.7.tgz
	SPARKDIR=$APPBENCH/apps/spark
	HIBENCHDIR=$SPARKDIR/HiBench
        SPARKFILES=$APPBENCH/apps/spark_files
	HADOOP="hadoop-3.2.1"
	HADOOP_DIR=$SPARKDIR/$HADOOP

       ADD_SPARK_TO_BASHRC

	wget https://www.apache.org/dist/spark/spark-2.4.4/$SPARKFILE
	tar -xvzf $SPARKFILE
	rm $SPARKFILE
	mv spark-2.4.4* $SPARKDIR
	cd $SPARKDIR
	wget http://apache.mirrors.pair.com/hadoop/common/$HADOOP/$HADOOP".tar.gz"
        git clone https://github.com/Intel-bigdata/HiBench
        cd $HIBENCHDIR
	mvn -Dspark=2.1 -Dscala=2.11 clean package
	cp $SPARKFILES/$HADOOP/etc/* $HADOOP_DIR/etc/
        cp $SPARKFILES/HiBench/conf/* $HIBENCHDIR/conf/ 
}


INSTALL_CASSANDRA() {
	cd $APPBENCH/apps
	git clone https://github.com/SudarsunKannan/butterflyeffect
	cd butterflyeffect/code
	source scripts/setvars.sh
	scripts/install_cassandra.sh
	source $CODE/scripts/setvars.sh
	cp $CODE/cassandra.sh $CSRC/bin/cassandra
}

INSTALL_ROCKSDB() {
	cd $APPBENCH/apps
	git clone https://github.com/facebook/rocksdb
	#cp $APPBENCH/apps/db_bench_tool.cc $APPBENCH/apps/rocksdb/tools/
	cd rocksdb
	#mkdir build 
	#cd build
	#rm -rf CMakeCache.txt
	#cmake ..
	git checkout a8975b62455cb73a8e23ff6be709df1b97859d2d
	DEBUG_LEVEL=0 make shared_lib db_bench -j16
	cp $APPBENCH/apps/rocks-script/run_rocksdb.sh $APPBENCH/apps/rocksdb/run.sh
}

INSTALL_GFLAGS(){
	cd $SHARED_LIBS
	git clone https://github.com/gflags/gflags.git
	cd gflags
	rm -rf CMakeCache.txt
	export CXXFLAGS="-fPIC" && cmake . -DCMAKE_INSTALL_PREFIX=/usr/local -DBUILD_SHARED_LIBS=ON && make -j16 && sudo make install
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
INSTALL_CASSANDRA
}

INSTALL_SYSTEM_LIBS
INSTALL_SPARK_HIBENCH
exit

INSTALL_CMAKE
INSTALL_GFLAGS
INSTALL_ROCKSDB
GETAPPS
exit

exit

#INSTALL_SYSBENCH
#INSTALL_MYSQL
# Set variable, setup packages and generate data
source scripts/setvars.sh
$SCRIPTS/compile_sharedlib.sh
#$APPBENCH/setup.sh
#$APPBENCH/compile_all.sh
#Compile Linux Kernel
cd $KERN_SRC
$SCRIPTS/compile_deb.sh
#Changing bandwidth of a NUMA node
$APPBENCH/install_quartz.sh
$APPBENCH/throttle.sh
$APPBENCH/throttle.sh
exit

INSTALL_SPARK
exit

