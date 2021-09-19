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
typedef ssize_t (*real_readahead_t)(int, off64_t, size_t);

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
