#!/usr/bin/env bash

# Client should be the one who visits nvme device on other nodes(targets) 


USER=$USER #DONT hardcode and checkin
IP_ADDR=10.10.1.2
REMOTE_TARGET=nvme-target1
REMOTE_DISK=/dev/nvme1n1
REMOTE_STORAGE=/mnt/remote

#NVMe over RoCE setup for client side
modprobe nvme-rdma

sudo apt install uuid-dev

# git clone https://github.com/linux-nvme/nvme-cli.git

# cd nvme-cli
# make
# make install

sudo apt install nvme-cli

#nvme gen-hostnqn > /etc/nvme/hostnqn

sudo nvme connect -t rdma -n $REMOTE_TARGET -a $IP_ADDR -s 4420

if mount | grep $REMOTE_STORAGE > /dev/null; then
	echo "Remote NVMe OK"
else
	sudo mount $REMOTE_DISK $REMOTE_STORAGE
	if [ $? -eq 0 ]; then
		sudo chown -R $USER $REMOTE_STORAGE
	else
		sudo mkfs.ext4 $REMOTE_DISK
		sudo mount $REMOTE_DISK $REMOTE_STORAGE
		sudo chown -R $USER $REMOTE_STORAGE
	fi
fi

#sudo nvme gen-hostnqn > /etc/nvme/hostnqn
