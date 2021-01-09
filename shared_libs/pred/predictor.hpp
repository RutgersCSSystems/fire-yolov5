
#define SEQ_CHANGE 0.1 //Change values based on seq observation
#define RAND_CHANGE 0.4 //Change values based on random observation

#define TOL 0.1 //Tolerance from 0 to call there is no file read 

bool firsttime = true;


typedef ssize_t (*real_read_t)(int, void *, size_t);
typedef size_t (*real_fread_t)(void *, size_t, size_t,FILE *);
typedef ssize_t (*real_write_t)(int, const void *, size_t);
typedef size_t (*real_fwrite_t)(const void *, size_t, size_t,FILE *);
typedef int (*real_fclose_t)(FILE *);
typedef int (*real_close_t)(int);
typedef int (*real_open_t)(const char *, int flags);

size_t real_fclose(FILE *stream){
        return ((real_fclose_t)dlsym(RTLD_NEXT, "fclose"))(stream);
}
int real_close(int fd){
        return ((real_close_t)dlsym(RTLD_NEXT, "close"))(fd);
}
size_t real_fread(void *ptr, size_t size, size_t nmemb, FILE *stream){
        return ((real_fread_t)dlsym(RTLD_NEXT, "fread"))(ptr, size, nmemb, stream);
}
size_t real_fwrite(const void *ptr, size_t size, size_t nmemb, FILE *stream){
        return ((real_fwrite_t)dlsym(RTLD_NEXT, "fwrite"))(ptr, size, nmemb, stream);
}
ssize_t real_write(int fd, const void *data, size_t size) {
        return ((real_write_t)dlsym(RTLD_NEXT, "write"))(fd, data, size);
}
ssize_t real_read(int fd, void *data, size_t size) {
        return ((real_read_t)dlsym(RTLD_NEXT, "read"))(fd, data, size);
}
int real_open(const char *pathname, int flags){
        return ((real_open_t)dlsym(RTLD_NEXT, "open"))(pathname, flags);
}
