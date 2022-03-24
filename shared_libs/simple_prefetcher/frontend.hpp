#ifndef _FRONTEND_HPP
#define _FRONTEND_HPP

#include "shim.hpp"
#include "utils/thpool.h"
#include "utils/bitarray.h"

#define __PREAD_RA_SYSCALL 449
#define __READ_RA_SYSCALL 450
#define __READAHEAD_INFO 451

#define DEFNSEQ (-8) //Not seq or strided(since off_t is ulong)
#define LIKELYNSEQ (-4) /*possibly not seq */
#define POSSNSEQ 0 /*possibly not seq */
#define MAYBESEQ 1 /*maybe seq */
#define POSSSEQ 2 /* possibly seq? */
#define LIKELYSEQ 4 /* likely seq? */
#define DEFSEQ 64 /* definitely seq */


//returns filesize if fd is regular file
//else 0
off_t reg_fd(int fd){

    if(fd<=2)
        return false;

    struct stat st;

    if(fstat(fd, &st) == 0){
        switch (st.st_mode & S_IFMT) {
            case S_IFBLK:
                debug_printf("fd:%d block device\n", fd);
                break;
            case S_IFCHR:
                debug_printf("fd:%d character device\n", fd);
                break;
            case S_IFDIR:
                debug_printf("fd:%d directory\n", fd);
                break;
            case S_IFIFO:
                debug_printf("fd:%d FIFO/pipe\n", fd);
                break;
            case S_IFLNK:
                debug_printf("fd:%d symlink\n", fd);
                break;
            case S_IFREG:
                debug_printf("fd:%d regular file\n", fd); 
                return st.st_size;
                //return true;            
                break;
            case S_IFSOCK:
                debug_printf("fd:%d socket\n", fd);
                break;
            default:
                debug_printf("fd:%d unknown?\n", fd);
        }
        /*
           if(S_ISREG(st.st_mode)){
           return true;
           }
           */
    }
    //return true;
    return false;
}

//returns filesize if FILE is regular file
//else 0
off_t reg_file(FILE *stream){
    return reg_fd(fileno(stream));
}


//wrapper for pread_ra
ssize_t pread_ra(int fd, void *data, size_t size, off_t offset, 
        struct read_ra_req *ra_req)
{
    return syscall(__PREAD_RA_SYSCALL, fd, data, size, offset, ra_req);
}

long readahead_info(int fd, loff_t offset, size_t count, struct read_ra_req *ra_req)
{
        return syscall(__READAHEAD_INFO, fd, offset, count, ra_req);
}

/*
 * Does both fread and readahead in one syscall
 */
size_t fread_ra(void *ptr, size_t size, size_t nmemb, FILE *stream, size_t ra_size){

    ssize_t ret;
    int fd;
    fd = fileno(stream);

    struct read_ra_req ra_req;
    ra_req.ra_pos = 0;
    ra_req.ra_count = ra_size;

    /*
     * XXX: Since fread is a library call, I cannot implement fread_ra without changing
     * glibc. So instead, we convert fread_ra to pread_ra syscall as a hack
     *
     * NOTE: Here the pread_ra syscall assumes that ra_pos = read_pos + read_bytes; ie.
     * It will only readahead from the end of read request. reads and readaheads in diff
     * positions is not implemented yet in the modified kernel 5.14.
     */
    ret = pread_ra(fd, ptr, nmemb*size, ftell(stream), &ra_req);
    if(ret <=0){
        printf("%s: Error %s\n", __func__, strerror(errno));
        return 0;
    }

    fseek(stream, 0L, SEEK_END);

    return ret/size; //should return nr of items read
}


/*
 * Per-Thread constructors can be made using
 * constructors for threadlocal objects
 */
class per_thread_ds{
    public:
        //Any variables here.
        long mytid; //this threads TID

        int last_fd; //records the last fd being used to read
        int current_fd; // records the current fd being used

        unsigned long nr_readaheads; //Counts the nr of readaheads done by apps

        //constructor
        per_thread_ds(){
                mytid = gettid();
        }

        ~per_thread_ds(){}
};


/*
 * The following set of commands are to enable single call at construction
 */

/*Returns the Parent PID of this process*/
pid_t getgppid(){
	char buf[128];

	pid_t ppid = getppid();

	pid_t gppid;

	FILE *fp;

	sprintf(buf, "/proc/%d/stat", (int)ppid);

	fp = fopen(buf, "r");
	if(fp == NULL)
		return -1;

	fscanf(fp, "%*d %*s %*s %d", &gppid);
	fclose(fp);

     //printf("My gppid = %d\n", gppid);

	return gppid;
}


/*Checks if this process is the root process*/
bool is_root_process(){
	char *gppid_env = getenv("TARGET_GPPID");

	if(gppid_env == NULL){
		printf("TARGET_GPPID is not set, cannot pick individual\n");
		goto err;
	}

	if(getgppid() == atoi(gppid_env)){
		return true;
	}

err:
	return false;
}


///////////////////////////////////////////////////////////////
//This portion is used to keep track of per file prefetching
///////////////////////////////////////////////////////////////


class file_predictor{
        public:
                int fd;
                size_t filesize;

                /*
                 * The file is divided into FILESIZE/(PORTION_SIZE*PAGESIZE) portions
                 * Each such portions is represented with a bit in access_history
                 * Accesses to an area represented by a set bit increases sequentiality
                 * else increases Non sequentiality
                 */
                bit_array_t *access_history;
                size_t nr_portions;
                size_t portion_sz;

                /*
                 * This variable summarizes if the file is reasonably
                 * sequential/strided for prefetching to happen.
                 */
                long sequentiality;
                
                /*
                 * Returns true if readahead has been issued 
                 * for this file
                 */
                bool already_prefetched;

                /*Constructor*/
                file_predictor(int this_fd, size_t size){
                        fd = this_fd;
                        filesize = size;

                        portion_sz = PAGESIZE * PORTION_PAGES;
                        nr_portions = size/portion_sz;

                        //Imperfect division of filesize with portion_sz
                        //add one bit to accomodate for the last portion in file
                        if(size % portion_sz){
                                nr_portions += 1;
                        }

                        access_history = BitArrayCreate(nr_portions);
                        BitArrayClearAll(access_history);

                        //Assume any opened file is probably not sequential
                        sequentiality = POSSNSEQ;
                        already_prefetched = false;
                }

		/*Destructor*/
		~file_predictor(){
			BitArrayDestroy(access_history);
		}

                /*
                 * If offset being accessed is from an Unset file portion, set it,
                 * 1. Set that file portion in access_history
                 * 2. reduce the sequentiality
                 *
                 * else increase the sequentiality
                 *
                 * XXX: Doesnt limit the sequentiality number, may overflow for large files
                 */
                void predictor_update(off_t offset, size_t size){

                        size_t portion_num = offset/portion_sz; //which portion
                        size_t num_portions = size/portion_sz; //how many portions in this req
                        size_t pn = 0; //used for adjacency check

                        if(portion_num > nr_portions){
                                printf("%s: ERR : portion_num > nr_portions, has the filesize changed ?\n", __func__);
                                goto exit;
                        }

                        /*
                         * Go through the bit array, setting ones portions associated
                         * with this read request
                         */
                        for(long i=0; i<=num_portions; i++)
                                        BitArraySetBit(access_history, portion_num+i);


                        /*
                         * Go through the adjacent bits in bitarray 
                         * to check for sequentiality
                         * TODO: Convert this a bit operation, this is heavy
                         * Develop a bit mask and test the corresponding bits
                         */
                        for(long i = -NR_ADJACENT_CHECK; i < NR_ADJACENT_CHECK; i++){
                                if(i == 0)
                                        continue;

                                pn = portion_num + i;
                                if(i > 0){
                                        //takes seq for reverse reads
                                        pn += num_portions; //look forward
                                }

                                /*bounds check*/
                                if(pn < 0 || pn > nr_portions)
                                        continue;

                                /*
                                 * If any one of the adjacent bits is set
                                 * consider it to be seq
                                 */
                                if(BitArrayTestBit(access_history, pn)){
                                        goto is_seq;
                                }
                        }

is_not_seq:
                        sequentiality -= 1;
                        goto exit;

is_seq:
                        sequentiality += 1;

exit:
                        return;
                }

                //Returns the current Sequentiality value
                long is_sequential(){
                        return sequentiality;
                }

};


#endif
