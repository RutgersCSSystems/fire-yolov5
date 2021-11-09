#!/usr/bin/env python 
import os


unique_fd_file = "unique_inode_nr_10M"
main_data_file = "readaheads_10M_cleaned"

outfolder = os.getcwd() + "/perinode_10M"

blocksize=4096

# inode_nr, block_nr

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
         tmp_fd = open(filename, "a")
         for line in main_f:
             sp = line.split(",")
             if (sp[0] == str(fd)):
                 tmp_fd.write(line)
         tmp_fd.close()
         main_f.seek(0)



if __name__ == "__main__":
    main()
