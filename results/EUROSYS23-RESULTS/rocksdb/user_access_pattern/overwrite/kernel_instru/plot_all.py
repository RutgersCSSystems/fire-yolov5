#!/usr/bin/env python 
import os
import sys
import numpy as np
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt


unique_fd_file = "unique_inode_nr_10M"
main_data_file = "readaheads_10M_cleaned"

outfolder = os.getcwd() + "/perinode_10M"


def main():
     main_f = open(main_data_file, "r")
     uniq_f = open(unique_fd_file, "r")

     if(os.path.exists(outfolder) != True):
        os.mkdir(outfolder)

     nr_uniq_fd = len(uniq_f.readlines())
     uniq_f.seek(0)
     uniq_fd_ctr = 0.0;

     for u in uniq_f:
         fd = int(u)
         percentage = (uniq_fd_ctr/nr_uniq_fd) * 100.0
         print(str(percentage) + "% done")
         uniq_fd_ctr += 1

         filename = outfolder + "/" + str(fd) + "_readaheads"
         plotname = outfolder + "/" + str(fd) + "_missplot.png"

         perfd = open(filename, "r")
         nr_timestamps = len(perfd.readlines())
         perfd.seek(0)
         x_axis_time = np.arange(nr_timestamps) #timestamps
         y_axis_offset = np.zeros(nr_timestamps)
         size = np.ones(nr_timestamps)
         for idx,line in enumerate(perfd):
             split = line.split(",")
             read_offt = split[1] ##read_off
             y_axis_offset[idx] = int(read_offt)

         ##plotting and saving
         plt.title("Access Pattern for fd="+str(fd))
         plt.xlabel("Time line")
         plt.ylabel("File Offset")
         plt.scatter(x_axis_time, y_axis_offset, s=size, c="red")
         plt.grid()
         plt.savefig(plotname)

         perfd.close()





if __name__ == "__main__":
    main()

