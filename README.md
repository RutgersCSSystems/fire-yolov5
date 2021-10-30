Crosslayer: Random One liner
==================================================

A small description


### Directory structure
.
├── README.md
├── appbench            # application workloads
├── linux-5.14.0        # Modified Linux kernel
├── references.txt      # list of references for paper
├── results             # folder with all results 
├── scripts             # all scripts for setup and microbench running
└── shared_libs/pred    # shared lib predictor src


### Setup Environment


#### Cloudlab Node allocation
Recommendation to use c6525-100g@Utah; this one has two large NVMe SSDs.
Use Profile CS764Fall2018/single-raw-ubuntu-18 to setup the node.
```
https://www.cloudlab.us/show-profile.php?uuid=76d501c8-02fb-11e9-9331-90e2ba22fee4
```

#### Partition Setup & cloning

If you are using CloudLab, the root partition is only 16GB for some profiles.
First setup the CloudLab node with SSD and install all the required libraries.

```
lsblk
```

You should see the following indicating the root partition size is very small:

```
NAME        MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
nvme0n1     259:1    0  1.5T  0 disk 
├─nvme0n1p1 259:2    0   16G  0 part /
├─nvme0n1p2 259:3    0    3G  0 part 
├─nvme0n1p3 259:4    0    3G  0 part [SWAP]
└─nvme0n1p4 259:5    0  1.4T  0 part 
nvme1n1     259:7    0  1.5T  0 disk 
```

To partition the device use the following commands

```
sudo fdisk /dev/nvme1n1
```

You will see the following output. Choose the following options to complete partition setup
```
Command (m for help): n
Partition type
   p   primary (0 primary, 0 extended, 4 free)
   e   extended (container for logical partitions)
Select (default p):
....
Last sector, +sectors or +size{K,M,G,T,P} (2048-937703087, default 937703087):
....
Created a new partition 1 of type 'Linux' and of size 1.5 TiB.

Command (m for help): w
The partition table has been altered.
Calling ioctl() to re-read partition table.
Syncing disks.
.....
```

Now you would have to setup a filesystem and mount it 

```
sudo mkfs.ext4 /dev/nvme1n1p1

mkdir ~/ssd; sudo mount /dev/nvme1n1p1 ~/ssd

cd ~/ssd; sudo chown $USER .
```


Now to get the appropriate branch

```
cd ssd
git clone git@github.com:sudarsunkannan/NVM.git -b hpc
git submodule update --init ## This get the linux kernel
```

You now have the repo. Before running things, run

```
cd NVM
source ./scripts/setvars.sh ## This sets appropriate env variables
```



### Compile Kernel

If you check the linux-5.14.0 folder and it seems empty simply run

```
git submodule update --init
```

#### To compile deb for baremetal

Before running the following commands, make sure you dont have other deb files in the NVM folder.

```
cd NVM/linux-5.14.0
./compile_deb.sh ## This will produce and install deb for this linux kernel
sudo reboot ## this will reboot the node with the new linux 
```

#### To compile for qemu

```
cd NVM/linux-5.14.0
sudo cp oldnix.config .config
sudo make prepare
cd NVM
./scripts/compile-install/compile_kern_kvm.sh
```

### Qemu Management

#### Qemu Setup

```
./scripts/qemu/qemu_create.sh ## has to be done only once
```

#### Run Qemu
To run qemu, first compile the kernel for qemu; then

```
./scripts/qemu/run_qemu.sh
```


### Run Experiments
All the experiments are in the following folder.
this script needs to be updated to run different applications

```
cd ./scripts/run/run_all_variation.sh
```
