#!/bin/bash
set -x

if [ -z "$NVMBASE" ]; then
	echo "NVMBASE environment variable not defined. Have you ran setvars?"
	exit 1
fi

sudo umount $MOUNT_DIR
#Compile the kernel
cd $KERN_SRC
#Enable the KVM mode in your kernel config file
#sudo make x86_64_defconfig
#sudo make kvmconfig 
#Compile the kernel with '-j' (denotes parallelism) in sudo mode
sudo make prepare ##Uses the modified .config file to compile kernel
sudo make $PARA &> $KERN_SRC/compile.out
grep -r "error:|undefined|warning|Permission" $KERN_SRC/compile.out &> $KERN_SRC/errors.out
#sudo make modules &>> $KERN_SRC/compile.out
#sudo make modules_install &>> $KERN_SRC/compile.out
#grep -r "error:|undefined" $KERN_SRC/compile.out &>> $KERN_SRC/errors.out
#sudo make install &>> $KERN_SRC/compile.out
#grep -r "error:|undefined" $KERN_SRC/compile.out &>> $KERN_SRC/errors.out

sudo cp ./arch/x86/boot/bzImage $KERNEL/vmlinuz-$VER
sudo cp System.map $KERNEL/System.map-$VER
sudo cp .config $KERNEL/config-$VER
#sudo update-initramfs -c -k $y
grep -r "error:" $KERN_SRC/compile.out &> $KERN_SRC/errors.out
cat $KERN_SRC/errors.out

