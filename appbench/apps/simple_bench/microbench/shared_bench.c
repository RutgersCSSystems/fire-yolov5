#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <pthread.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <stdint.h>
#include <time.h>
#include <sys/mman.h>


#define DEFAULT_FILENAME "sample_file.txt"
#define DEFAULT_FILE_SIZE (1024 * 1024 * 100) // 100 MB
#define DEFAULT_THREAD_COUNT 4

char* filename;
off_t file_size;
int thread_count;
off_t read_write_size;
int sequential_mode; // 1 for sequential, 0 for random
int generate_file;   // 1 to generate the file, 0 to use an existing file

// Global variable for cumulative throughput
double cumulative_throughput = 0.0;
pthread_mutex_t throughput_mutex = PTHREAD_MUTEX_INITIALIZER;

// Function to generate random data and write it to a file
void generate_sample_file() {
    FILE* file = fopen(filename, "wb");
    if (file == NULL) {
        perror("Failed to create the sample file");
        exit(1);
    }

    // Generate random data and write it to the file
    char* data = malloc(file_size);
    for (off_t i = 0; i < file_size; i++) {
        data[i] = rand() % 256;
    }
    fwrite(data, 1, file_size, file);
    fclose(file);
    free(data);
}


// Function to generate random data and write it to a file using mmap
void generate_sample_file_mmap() {
    int fd;
    char* data;

    fd = open(filename, O_CREAT | O_RDWR, S_IRUSR | S_IWUSR);
    if (fd == -1) {
        perror("Failed to create the sample file");
        exit(1);
    }

    // Set the file size
    if (ftruncate(fd, file_size) == -1) {
        perror("Failed to set file size");
        exit(1);
    }

    // Map the file into memory
    data = mmap(NULL, file_size, PROT_WRITE, MAP_SHARED, fd, 0);
    if (data == MAP_FAILED) {
        perror("Failed to mmap file");
        exit(1);
    }

    // Generate random data directly into the mapped memory
    for (off_t i = 0; i < file_size; i++) {
        data[i] = rand() % 256;
    }

    // Unmap and close the file
    if (munmap(data, file_size) == -1) {
        perror("Failed to munmap file");
        exit(1);
    }
    close(fd);
}

// Function to read data sequentially from the file
void* sequential_read(void* arg) {
    int thread_id = *(int*)arg;
    int fd;
    char* buffer = malloc(read_write_size);
    memset(buffer, 0, read_write_size);

    if (generate_file) {
        printf("File generation mode enabled. Skipping read workloads.\n");
        pthread_exit(NULL);
    }

    // Open the file
    fd = open(filename, O_RDONLY);
    if (fd == -1) {
        perror("Failed to open file");
        exit(1);
    }

    // Calculate chunk size for each thread
    off_t chunk_size = file_size / thread_count;
    off_t start_offset = thread_id * chunk_size;

    // Seek to the start offset for this thread
    lseek(fd, start_offset, SEEK_SET);

    // Read data sequentially
    ssize_t bytes_read;
    clock_t start_time = clock();

    while ((bytes_read = read(fd, buffer, read_write_size)) > 0) {
        // Read the data
    }

    clock_t end_time = clock();
    double elapsed_time = (double)(end_time - start_time) / CLOCKS_PER_SEC;

    close(fd);
    free(buffer);

    double throughput = (file_size / (1024 * 1024)) / elapsed_time; // MB/sec

    // Update cumulative throughput
    pthread_mutex_lock(&throughput_mutex);
    cumulative_throughput += throughput;
    pthread_mutex_unlock(&throughput_mutex);

    printf("Thread %d Sequential Read Throughput: %.2f MB/sec\n", thread_id, throughput);
    pthread_exit(NULL);
}

// Function to read data randomly from the file
void* random_read(void* arg) {
    int thread_id = *(int*)arg;
    int fd;
    char* buffer = malloc(read_write_size);
    memset(buffer, 0, read_write_size);

    if (generate_file) {
        printf("File generation mode enabled. Skipping read workloads.\n");
        pthread_exit(NULL);
    }

    // Open the file
    fd = open(filename, O_RDONLY);
    if (fd == -1) {
        perror("Failed to open file");
        exit(1);
    }

    // Calculate chunk size for each thread
    off_t chunk_size = file_size / thread_count;
    off_t start_offset = thread_id * chunk_size;

    // Read data randomly
    ssize_t bytes_read;
    clock_t start_time = clock();

    for (off_t i = 0; i < chunk_size; i += read_write_size) {
        lseek(fd, start_offset + (rand() % chunk_size), SEEK_SET);
        bytes_read = read(fd, buffer, read_write_size);
    }

    clock_t end_time = clock();
    double elapsed_time = (double)(end_time - start_time) / CLOCKS_PER_SEC;

    close(fd);
    free(buffer);

    double throughput = (file_size / (1024 * 1024)) / elapsed_time; // MB/sec

    // Update cumulative throughput
    pthread_mutex_lock(&throughput_mutex);
    cumulative_throughput += throughput;
    pthread_mutex_unlock(&throughput_mutex);

    printf("Thread %d Random Read Throughput: %.2f MB/sec\n", thread_id, throughput);
    pthread_exit(NULL);
}

int main(int argc, char* argv[]) {
    if (argc < 5) {
        fprintf(stderr, "Usage: %s <filename> <file_size> <thread_count> [read_write_size] [sequential_mode] [generate_file]\n", argv[0]);
        return 1;
    }

    filename = argv[1];
    file_size = atoll(argv[2]);
    thread_count = atoi(argv[3]);
    read_write_size = (argc > 4) ? atoll(argv[4]) : 1024;
    sequential_mode = (argc > 5) ? atoi(argv[5]) : 1; // Default to sequential mode
    generate_file = (argc > 6) ? atoi(argv[6]) : 0;   // Default to not generate file

    if (generate_file) {
        printf("File generation mode enabled. Generating the file.\n");
        generate_sample_file_mmap();
        return 0; // Exit without running read workloads
    }

    pthread_t threads[thread_count];
    int thread_ids[thread_count];

    // Create threads for reading
    void* (*read_func)(void*) = (sequential_mode) ? sequential_read : random_read;

    for (int i = 0; i < thread_count; i++) {
        thread_ids[i] = i;
        pthread_create(&threads[i], NULL, read_func, &thread_ids[i]);
    }

    // Wait for threads to finish
    for (int i = 0; i < thread_count; i++) {
        pthread_join(threads[i], NULL);
    }

    // Print cumulative throughput
    if (!generate_file) {
        printf("Cumulative Throughput: %.2f MB/sec\n", cumulative_throughput);
    }

    return 0;
}

