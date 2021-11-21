#!/usr/bin/env python

import sys
import os
import numpy as np
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt


print(str(sys.argv))

main_data_file = str(sys.argv[1])
unique_fd_file = str(sys.argv[2])

outfolder = os.getcwd() + "/" + main_data_file + "_perfd"


def main():

    main_f = open(main_data_file, "r")
    uniq_f = open(unique_fd_file, "r")

    if(os.path.exists(outfolder) != True):
        os.mkdir(outfolder)

    for u in uniq_f:
        fd = int(u)

        filename = outfolder + "/" + str(fd) + "_access"
        plotname = outfolder + "/" + str(fd) + "_accessplot.png"
        tmp_fd = open(filename, "a+")
        
        avg_read_sz = 0.0
        nr_reads = 0
        nr_readaheads = 0
        avg_readahead_sz = 0.0
        for line in main_f:
            try:
                sp = line.split(",")
                if(int(sp[1]) == fd):
                    tmp_fd.write(line)

                    if(sp[0] == "pread"):
                        avg_read_sz += int(sp[2])
                        nr_reads += 1
                    elif(sp[0] == "readahead"):
                        avg_readahead_sz += int(sp[2])
                        nr_readaheads += 1
                    
                    
            except:
                continue
        main_f.seek(0)

        avg_read_sz /= nr_reads
        avg_readahead_sz /= nr_readaheads

        ### Done file, now plot it
        tmp_fd.seek(0)
        nr_timestamps = len(tmp_fd.readlines())
        tmp_fd.seek(0)


        x_axis_time = np.arange(nr_timestamps)
        y_read_offset = np.zeros(nr_timestamps)
        y_readahead_offset = np.zeros(nr_timestamps)

        y_read_size = np.zeros(nr_timestamps)
        y_readahead_size = np.zeros(nr_timestamps)

        for idx,line in enumerate(tmp_fd):
            split = line.split(",")
            if(split[0] == "pread"):
                y_read_offset[idx] = int(split[2])
                y_read_size[idx] = 1
            elif(split[0] == "readahead"):
                y_readahead_offset[idx] = int(split[2])
                y_readahead_size[idx] = int(avg_read_sz/int(split[3]))


        plt.title("Read Readahead pattern for fd="+str(fd))
        plt.xlabel("Timeline")
        plt.ylabel("File Offset")
        reads = plt.scatter(x_axis_time, y_read_offset, s=y_read_size, c="red", label="Read")
        readaheads = plt.scatter(x_axis_time, y_readahead_offset, s=y_readahead_size, facecolor="None", edgecolors="blue", label="Readahead")
        plt.grid()
        plt.legend(handles=[reads, readaheads])
        plt.savefig(plotname)
        
        tmp_fd.close()



if __name__ == "__main__":
    main()
