#/bin/bash
#set -x

PERFORM_FSCK() {
        sudo umount /dev/nvme1n1
        sudo fsck.ext4 -fy /dev/nvme1n1
        sudo mount /dev/nvme1n1 /mnt/remote
        sudo chown -R kannan11 /mnt/remote
}


PERFORM_FSCK
