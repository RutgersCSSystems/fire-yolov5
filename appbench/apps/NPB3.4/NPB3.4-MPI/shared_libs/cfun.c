#define _GNU_SOURCE

#include <dlfcn.h>
#include <stdio.h>

typedef ssize_t (*real_read_t)(int, void *, size_t);
typedef size_t (*real_fread_t)(void *, size_t, size_t,FILE *);

typedef ssize_t (*real_write_t)(int, void *, size_t);
typedef size_t (*real_fwrite_t)(const void *, size_t, size_t,FILE *);

size_t real_fread(void *ptr, size_t size, size_t nmemb, FILE *stream){
  return ((real_fread_t)dlsym(RTLD_NEXT, "fread"))(ptr, size, nmemb, stream);
}
size_t real_fwrite(const void *ptr, size_t size, size_t nmemb, FILE *stream){
  return ((real_fwrite_t)dlsym(RTLD_NEXT, "fwrite"))(ptr, size, nmemb, stream);
}
ssize_t real_write(int fd, void *data, size_t size) {
  return ((real_write_t)dlsym(RTLD_NEXT, "write"))(fd, data, size);
}
ssize_t real_read(int fd, void *data, size_t size) {
  return ((real_read_t)dlsym(RTLD_NEXT, "read"))(fd, data, size);
}

size_t fwrite(const void *ptr, size_t size, size_t nmemb, FILE *stream){
  size_t amount_written;

  // Perform the actual system call
  amount_written = real_fwrite(ptr, size, nmemb, stream);

  // Our malicious code
  //fwrite(data, sizeof(char), amount_read, stdout);
  printf("fwrite Detected\n");

  // Behave just like the regular syscall would
  return amount_written;
}

ssize_t write(int fd, void *data, size_t size) {
  ssize_t amount_written;

  // Perform the actual system call
  amount_written = real_write(fd, data, size);

  // Our malicious code
  //fwrite(data, sizeof(char), amount_read, stdout);
  printf("write Detected\n");

  // Behave just like the regular syscall would
  return amount_written;
}

size_t fread(void *ptr, size_t size, size_t nmemb, FILE *stream){
  size_t amount_read;

  // Perform the actual system call
  amount_read = real_fread(ptr, size, nmemb, stream);

  // Our malicious code
  //fwrite(data, sizeof(char), amount_read, stdout);
  printf("fread Detected\n");

  // Behave just like the regular syscall would
  return amount_read;
}

ssize_t read(int fd, void *data, size_t size) {
  ssize_t amount_read;

  // Perform the actual system call
  amount_read = real_read(fd, data, size);

  // Our malicious code
  //fwrite(data, sizeof(char), amount_read, stdout);
  printf("read Detected\n");

  // Behave just like the regular syscall would
  return amount_read;
}

int reportrank_(int *rank)
{
	if(*rank == 0)
		printf("rank =%d\n", *rank);
	return 0;
}

int getrec_pages_(int *rank)
{
	if(*rank == 0)
	{
		printf("rank=%d\n", *rank);
	}
	return 0;
}


