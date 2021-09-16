#ifndef _FRONTEND_HPP
#define _FRONTEND_HPP

typedef int (*real_open_t)(const char *, int);
typedef int (*real_open1_t)(const char *, int, mode_t);
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

typedef int (*real_posix_fadvise_t)(int, off_t, off_t, int);
typedef ssize_t (*real_readahead_t)(int, off_t, size_t);

/*
 * int open(const char *path, int oflag, .../,mode_t mode /);
int openat(int fd, const char *path, int oflag, ...);
int creat(const char *path, mode_t mode);
FILE *fopen(const char *restrict filename, const char *restrict mode);

 * */

#if 0
int real_open(const char *pathname, int flags){
        return ((real_open_t)dlsym(RTLD_NEXT, "open"))
            (pathname, flags);
}

FILE *real_fopen(const char *filename, const char *mode){
        return ((real_fopen_t)dlsym(RTLD_NEXT, "fopen"))
            (filename, mode);
}

size_t real_fread(void *ptr, size_t size, size_t nmemb, FILE *stream){
        return ((real_fread_t)dlsym(RTLD_NEXT, "fread"))
            (ptr, size, nmemb, stream);
}


size_t real_fwrite(const void *ptr, size_t size, size_t nmemb, FILE *stream){
        return ((real_fwrite_t)dlsym(RTLD_NEXT, "fwrite"))
            (ptr, size, nmemb, stream);
}


ssize_t real_write(int fd, const void *data, size_t size) {
        return ((real_write_t)dlsym(RTLD_NEXT, "write"))
            (fd, data, size);
}


ssize_t real_read(int fd, void *data, size_t size) {
        return ((real_read_t)dlsym(RTLD_NEXT, "read"))
            (fd, data, size);
}

ssize_t real_pread(int fd, void *data, size_t size, off_t offset){
        return ((real_pread_t)dlsym(RTLD_NEXT, "pread"))
            (fd, data, size, offset);
}
#endif


int real_fclose(FILE *stream){
        return ((real_fclose_t)dlsym(
                    RTLD_NEXT, "fclose"))(stream);
}


int real_close(int fd){
        return ((real_close_t)dlsym(
                    RTLD_NEXT, "close"))(fd);
}


bool reg_fd(int fd);
int reg_file(FILE *stream);

#endif
