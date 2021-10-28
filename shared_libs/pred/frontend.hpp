#ifndef _FRONTEND_HPP
#define _FRONTEND_HPP

#define __PREAD_RA_SYSCALL 449
#define __READ_RA_SYSCALL 450

typedef int (*real_open_t)(const char *, int, ...);
typedef int (*real_openat_t)(int, const char *, int);
typedef int (*real_openat1_t)(int, const char *, int, mode_t);
typedef int (*real_creat_t)(const char *, mode_t);
typedef FILE *(*real_fopen_t)(const char *, const char *);

typedef ssize_t (*real_read_t)(int, void *, size_t);
typedef ssize_t (*real_pread_t)(int, void *, size_t, off_t);
typedef size_t (*real_fread_t)(void *, size_t, size_t,FILE *);
typedef ssize_t (*real_write_t)(int, const void *, size_t);
typedef size_t (*real_fwrite_t)(const void *, size_t, 
        size_t,FILE *);

typedef int (*real_fclose_t)(FILE *);
typedef int (*real_close_t)(int);
typedef uid_t (*real_getuid_t)(void);

typedef int (*real_posix_fadvise_t)(int, off_t, off_t, int);
typedef ssize_t (*real_readahead_t)(int, off64_t, size_t);

typedef int (*real_clone_t)(int (void*), void *, int, void *, pid_t *, void *, pid_t *);

real_fopen_t fopen_ptr = NULL;
real_open_t open_ptr = NULL;

real_pread_t pread_ptr = NULL;
real_read_t read_ptr = NULL;

real_write_t write_ptr = NULL;

real_fread_t fread_ptr = NULL;
real_fwrite_t fwrite_ptr = NULL;

real_clone_t clone_ptr = NULL;

/*Advise calls*/

real_posix_fadvise_t posix_fadvise_ptr = NULL;
real_readahead_t readahead_ptr = NULL;


int real_clone(int (*fn)(void *), void *child_stack, int flags, void *arg,
        pid_t *ptid, void *newtls, pid_t *ctid){
    if(!clone_ptr)
        clone_ptr = (real_clone_t)dlsym(RTLD_NEXT, "clone");

    return ((real_clone_t)clone_ptr)(fn, child_stack, flags, arg, ptid, newtls, ctid);

}

int real_posix_fadvise(int fd, off_t offset, off_t len, int advice){
    if(!posix_fadvise_ptr)
        posix_fadvise_ptr = (real_posix_fadvise_t)dlsym(RTLD_NEXT, "posix_fadvise");

    return ((real_posix_fadvise_t)posix_fadvise_ptr)(fd, offset, len, advice);
}

ssize_t real_readahead(int fd, off_t offset, size_t count){
    if(!readahead_ptr)
        readahead_ptr = (real_readahead_t)dlsym(RTLD_NEXT, "readahead");

    return ((real_readahead_t)readahead_ptr)(fd, offset, count);
}

FILE *real_fopen(const char *filename, const char *mode){

    if(!fopen_ptr)
        fopen_ptr = (real_fopen_t)dlsym(RTLD_NEXT, "fopen");

    return ((real_fopen_t)fopen_ptr)(filename, mode);
}

size_t real_fread(void *ptr, size_t size, size_t nmemb, FILE *stream){

    if(!fread_ptr)
        fread_ptr = (real_fread_t)dlsym(RTLD_NEXT, "fread");

    return ((real_fread_t)fread_ptr)(ptr, size, nmemb, stream);
}


size_t real_fwrite(const void *ptr, size_t size, size_t nmemb, FILE *stream){

    if(!fwrite_ptr)
        fwrite_ptr = (real_fwrite_t)dlsym(RTLD_NEXT, "fwrite");

    return ((real_fwrite_t)fwrite_ptr)(ptr, size, nmemb, stream);
}

ssize_t real_pread(int fd, void *data, size_t size, off_t offset){

    if(!pread_ptr)
        pread_ptr = (real_pread_t)dlsym(RTLD_NEXT, "pread");

    return ((real_pread_t)pread_ptr)(fd, data, size, offset);
}


ssize_t real_write(int fd, const void *data, size_t size) {

    if(!write_ptr)
        write_ptr = ((real_write_t)dlsym(RTLD_NEXT, "write"));

    return ((real_write_t)write_ptr)(fd, data, size);
}

ssize_t real_read(int fd, void *data, size_t size) {

    if(!read_ptr)
        read_ptr = (real_read_t)dlsym(RTLD_NEXT, "read");

    return ((real_read_t)read_ptr)(fd, data, size);
}

int real_open(const char *pathname, int flags, mode_t mode){
    if(!open_ptr)
        open_ptr = ((real_open_t)dlsym(RTLD_NEXT, "open"));

    return ((real_open_t)open_ptr)(pathname, flags, mode);
}

int real_fclose(FILE *stream){
        return ((real_fclose_t)dlsym(
                    RTLD_NEXT, "fclose"))(stream);
}


int real_close(int fd){
        return ((real_close_t)dlsym(
                    RTLD_NEXT, "close"))(fd);
}

uid_t real_getuid(){
        return ((real_getuid_t)dlsym(
                    RTLD_NEXT, "getuid"))();
}


/*
 * Does both fread and readahead in one syscall
 */
size_t fread_ra(void *ptr, size_t size, size_t nmemb, FILE *stream, size_t ra_size){

    ssize_t ret;
    int fd;
    fd = fileno(stream);

    /*
     * XXX: Since fread is a library call, I cannot implement fread_ra without changing
     * glibc. So instead, we convert fread_ra to pread_ra syscall as a hack
     *
     * NOTE: Here the pread_ra syscall assumes that ra_pos = read_pos + read_bytes; ie.
     * It will only readahead from the end of read request. reads and readaheads in diff
     * positions is not implemented yet in the modified kernel 5.14. 
     */
    ret = syscall(__PREAD_RA_SYSCALL, fd, ptr, nmemb*size, ftell(stream), 0, ra_size);
    if(ret <=0){
        printf("%s: Error %s\n", __func__, strerror(errno));
        return 0;
    }

    fseek(stream, 0L, SEEK_END);

    return ret/size; //should return nr of items read
}


bool reg_fd(int fd);
int reg_file(FILE *stream);


/*
 * Per-Thread constructors can be made using
 * constructors for threadlocal objects
 */
class thread_cons_dest{
    public:
        //Any variables here.
        bool test_new; //set true at construction
        long mytid; //this threads TID

        unsigned long nr_readaheads; //Counts the nr of readaheads done by apps

        thread_cons_dest(); //constructor
        ~thread_cons_dest(); //destructor
};

void touch_tcd(void); //checks if a new thread was created


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

     printf("My gppid = %d\n", gppid);

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


/*
 * The next set of functions and structs are for enabling only unique readaheads
 */

struct prev_ra{
    std::atomic<long> tid; //TID allowed to do readaheads
    std::atomic<bool> first; //Is this the first time doing workload RA

#if 0
    int fd;
    off_t offset;
    size_t count; /*Will not use this for now*/

    //pthread_spinlock_t lock;
    pthread_mutex_t lock;
#endif 
};


#endif
