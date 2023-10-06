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
int shared_mode;     // 1 for shared file, 0 for private files

// Global variable for cumulative throughput
double cumulative_throughput = 0.0;
double total_bytes = 0.0;
pthread_mutex_t throughput_mutex = PTHREAD_MUTEX_INITIALIZER;
clock_t start_time;

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

// Function to generate random data and write it to a private file
void generate_private_sample_file(int thread_id) {
    char thread_filename[256];
    snprintf(thread_filename, sizeof(thread_filename), "%s_%d", filename, thread_id);

    int fd;
    char* data;

    fd = open(thread_filename, O_CREAT | O_RDWR, S_IRUSR | S_IWUSR);
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
    /*for (off_t i = 0; i < file_size; i++) {
        data[i] = rand() % 256;

    }*/
    memset(data, 100, file_size);

    // Unmap and close the file
    if (munmap(data, file_size) == -1) {
        perror("Failed to munmap file");
        exit(1);
    }
    close(fd);
}

// Function to read data sequentially from a file
void* sequential_read(void* arg) {
    int thread_id = *(int*)arg;
    int fd;
    char thread_filename[256];
    char* buffer = malloc(read_write_size);
    memset(buffer, 0, read_write_size);

    if (generate_file) {
        printf("File generation mode enabled. Skipping read workloads.\n");
        pthread_exit(NULL);
    }

    if (shared_mode) {
        // Open the shared file
        fd = open(filename, O_RDONLY);
    } else {
        // Open a private file for this thread
        snprintf(thread_filename, sizeof(thread_filename), "%s_%d", filename, thread_id);
        fd = open(thread_filename, O_RDONLY);
    }

    if (fd == -1) {
        perror("Failed to open file");
        exit(1);
    }

    file_size = lseek(fd, 0, SEEK_END);
    // Calculate chunk size for each thread
    //off_t chunk_size = file_size / thread_count;
    //off_t start_offset = thread_id * chunk_size;
    off_t chunk_size = 0;
    off_t start_offset = 0;


    // Seek to the start offset for this thread
    lseek(fd, start_offset, SEEK_SET);

    // Read data sequentially
    ssize_t bytes_read = 0, curr_read=0;
    clock_t start_time = clock();

    while ((curr_read = read(fd, buffer, read_write_size)) > 0) {
        // Read the data
	//fprintf(stderr, "curr_read %zu \n", curr_read);
	bytes_read += curr_read;
    }

    clock_t end_time = clock();
    double elapsed_time = (double)(end_time - start_time) / CLOCKS_PER_SEC;

    close(fd);
    free(buffer);

    double throughput = (bytes_read / (1024 * 1024)) / elapsed_time; // MB/sec

    // Update cumulative throughput
    pthread_mutex_lock(&throughput_mutex);
    cumulative_throughput += throughput;
    total_bytes += bytes_read;
    pthread_mutex_unlock(&throughput_mutex);
    //printf("Thread %d Sequential Read Throughput: %.2f MB/sec file_size %lu\n", thread_id, throughput, file_size);
    pthread_exit(NULL);
}

void* random_read(void* arg) {
    int thread_id = *(int*)arg;
    int fd;
    char thread_filename[256];
    char* buffer = malloc(read_write_size);
    memset(buffer, 0, read_write_size);

    if (generate_file) {
        printf("File generation mode enabled. Skipping read workloads.\n");
        pthread_exit(NULL);
    }

    if (shared_mode) {
        // Open the shared file
        fd = open(filename, O_RDONLY);
    } else {
        // Open a private file for this thread
        snprintf(thread_filename, sizeof(thread_filename), "%s_%d", filename, thread_id);
        fd = open(thread_filename, O_RDONLY);
    }

    if (fd == -1) {
        perror("Failed to open file");
        exit(1);
    }

    file_size = lseek(fd, 0, SEEK_END);

    // Calculate chunk size for each thread
    off_t chunk_size = file_size; // / thread_count;
    off_t start_offset = 0; //thread_id * chunk_size;

    lseek(fd, start_offset, SEEK_SET);	

    // Read data randomly
    ssize_t bytes_read = 0;
    ssize_t numchunks = file_size/read_write_size;
    clock_t start_time = clock();
    off_t i = 0;

    //for (int j=0; j< 10; j++) 
    for (i = 0; i < chunk_size; i += read_write_size) {
        //lseek(fd, start_offset + (rand() % chunk_size), SEEK_SET);
	start_offset = (rand() % numchunks);
        //bytes_read = read(fd, buffer, read_write_size);
	bytes_read += pread(fd, buffer, read_write_size, start_offset);
    }

    clock_t end_time = clock();
    double elapsed_time = (double)(end_time - start_time) / CLOCKS_PER_SEC;

    close(fd);
    free(buffer);

    double throughput = (bytes_read / (1024 * 1024)) / elapsed_time; // MB/sec
    // Update cumulative throughput
    pthread_mutex_lock(&throughput_mutex);
    cumulative_throughput += throughput;
    total_bytes += bytes_read;
    pthread_mutex_unlock(&throughput_mutex);

    return NULL;

    //printf("Thread %d Random Read Throughput: %.2f MB/sec iterations %d\n", thread_id, throughput, i);
    //pthread_exit(NULL);
}

int main(int argc, char* argv[]) {
    if (argc < 6) {
        fprintf(stderr, "Usage: %s <filename> <file_size> <thread_count> [read_write_size] [sequential_mode] [generate_file] [shared_mode]\n", argv[0]);
        return 1;
    }

    filename = argv[1];
    file_size = atoll(argv[2]);
    thread_count = atoi(argv[3]);
    read_write_size = (argc > 4) ? atoll(argv[4]) : 1024;
    sequential_mode = (argc > 5) ? atoi(argv[5]) : 1; // Default to sequential mode
    generate_file = (argc > 6) ? atoi(argv[6]) : 0;   // Default to not generate file
    shared_mode = (argc > 7) ? atoi(argv[7]) : 0;     // Default to private files

    if (generate_file) {
        printf("File generation mode enabled. Generating the file.\n");
        if (shared_mode) {
            generate_sample_file_mmap();
        } else {
            for (int i = 0; i < thread_count; i++) {
                generate_private_sample_file(i);
            }
        }
        return 0; // Exit without running read workloads
    }

    pthread_t threads[thread_count];
    int thread_ids[thread_count];

    // Set the shared start time
    start_time = clock();


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
	double elapsed_time = (double)(clock() - start_time) / CLOCKS_PER_SEC;
	double throughput = (total_bytes / (1024 * 1024)) / elapsed_time; // MB/sec
        printf("Cumulative Throughput: %.2f MB/sec, Time %.2f \n", throughput, elapsed_time);
    }

    return 0;
}

