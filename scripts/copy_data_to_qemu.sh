#!/bin/bash
set -x

#Full path of directory or file to copy
DIRPATH=$1
DESTPATH=$2

#Next, mount your image to the directory
sudo mount -o loop $QEMU_IMG_FILE $MOUNT_DIR

if [ -z "$DESTPATH" ]
then
    sudo cp -r $DIRPATH $MOUNT_DIR/root/
else
    sudo cp -r $DIRPATH $DESTPATH
fi

sudo umount $MOUNT_DIR
