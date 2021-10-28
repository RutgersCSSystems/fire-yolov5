#include <assert.h>
#include <dirent.h>
#include <errno.h>
#include <fcntl.h>
#include <math.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <sys/time.h>
#include <pthread.h> 

#include "snappy.h"

#include <crfslib.h>
#include "unvme_nvme.h"

#ifdef _POSIX
#define OUTPUT_DIR "/mnt/pmemdir/output_dir/"
#else
#define OUTPUT_DIR "/mnt/ram/output_dir/"
#endif
#define FILEPERM 0666

static int use_mmap;
static int use_nvmalloc;

char g_buf[4096];

size_t g_tot_input_bytes = 0;
size_t g_tot_output_bytes = 0;
static int g_snappy_init = 0;
struct snappy_env g_snappy_env;
double compress_time=0;
int g_completed=0;

struct thrd_cntxt {
        int id;
	struct snappy_env env;	
	char in_path[256];
	char out_path[256];	
	size_t tot_input_bytes;
	size_t tot_output_bytes;
};
struct thrd_cntxt cntxt[32];



double simulation_time(struct timeval start, struct timeval end) {
        double current_time;
        current_time = ((end.tv_sec + end.tv_usec * 1.0 / 1000000) -
                        (start.tv_sec + start.tv_usec * 1.0 / 1000000));
        return current_time;
}

FILE *cls_file;
static char *ReadFromFile(int cntr, size_t *size, char *filename,
                          char *read_dir) {
        char *input = NULL;
        size_t bytes = 0;
        FILE *fp = NULL;
        char filearr[512];
        char *nvptr = NULL;
        size_t fsize = 0;

        cls_file = NULL;

        if (strlen(filename) < 4) return NULL;

        bzero(filearr, 512);
        strcpy(filearr, read_dir);
        strcat(filearr, "/");
        strcat(filearr, filename);

        fp = fopen(filearr, "r");
        if (fp == NULL) {
                fprintf(stdout, "open failed for %s \n", filearr);
                return NULL;
        }
        cls_file = fp;
        fseek(fp, 0L, SEEK_END);
        fsize = ftell(fp);
        fseek(fp, 0, SEEK_SET);
        /*if(fstat(fileno(fp), &file_status) != 0){
                perror("ERROR");
        }*/
        if (fsize < 1) {
                *size = 0;
                return NULL;
        }
        input = (char *)malloc(fsize);
        bytes = fread(input, 1, fsize, fp);
        if (!bytes) {
                fprintf(stdout, "invalid input data %s", filearr);
                *size = 0;
		free(input);
                input = NULL;
		return NULL;
        }

        *size = bytes;
	fclose(fp);

        return input;
}

static char *ReadFromFile_Devfs(int cntr, size_t *size, char *filename,
                          char *read_dir) {
        char *input = NULL;
        size_t bytes = 0;
        char filearr[512];
        size_t fsize = 0;
        struct stat st;
        int fd = 0;

        if (strlen(filename) < 4) return NULL;

        bzero(filearr, 512);
        strcpy(filearr, read_dir);
        strcat(filearr, "/");
        strcat(filearr, filename);
        stat(filearr, &st);
        if (st.st_size == 0) return NULL;
        if ((fd = crfsopen(filearr, O_RDWR, FILEPERM)) < 0) {
                perror("open error");
                return NULL;
        }
        input = (char *)malloc(st.st_size);
        bytes = crfsread(fd, input, st.st_size);
        if (!bytes) {
                fprintf(stdout, "invalid input data %s", filearr);
                *size = 0;
                input = NULL;
        }
        crfsclose(fd);
        *size = bytes;
        return input;
}


void WritetoFile_Devfs(char *str, char *filename, size_t len) {
        int fd = 0, ret = 0;
        
        fd = crfsopen(filename, O_CREAT | O_RDWR, FILEPERM);
        if (fd < 0) {
                perror(filename);
                exit(1);
        }
        ret = crfswrite(fd, str, len);
        if (ret != len) {
                perror("write failed");
                exit(1);
        }

        crfsclose(fd); 
}

unsigned long tot_time = 0;
struct timeval start_io, end_io;

void WritetoFile(char *str, char *filename, size_t len) {
        FILE *fp = fopen(filename, "wb");
        if (fp == NULL) {
                perror(filename);
                exit(1);
        }
        int ret = fwrite(str, len, 1, fp);
        if (ret != 1) {
                perror("fwrite");
                exit(1);
        }
        fclose(fp);
}


#ifndef _USE_THREADING
static void CompressData(char *read_dir) {
#else
static void CompressData(void *cntxt) {
#endif

        int cntr = 0;

        FILE *fp;
        char buffer[256];
        char output_dir[256];
        size_t outsz = 0;
        FILE *outfp = NULL;
        size_t datasize;
        struct timeval t0,t1;
        long diff;
	struct snappy_env local_env = g_snappy_env;


#ifdef _USE_THREADING
	struct thrd_cntxt *thrdcntxt = (struct thrd_cntxt *)cntxt;
	char *read_dir = thrdcntxt->in_path;

	local_env = thrdcntxt->env;
	strcpy(output_dir, thrdcntxt->out_path);
#else
        /* Create output dir for compressed files */
        mkdir(OUTPUT_DIR, 0755);
        strcpy(output_dir, OUTPUT_DIR);
#endif
        DIR *mydir = opendir(read_dir);
        struct dirent *entry = NULL;

        assert(mydir);
        entry = readdir(mydir);
        assert(entry);

        /*
         * if snappy compression environment variable is not set,
         * then initialize it.
         */
        while ((entry = readdir(mydir)) != NULL) {
                char *output = NULL;
                char *input = NULL;
                char fname[256];

                cls_file = NULL;
		//fprintf(stderr, "entry->d_name %s \n", entry->d_name);
                if (entry->d_type == DT_DIR) 
			//goto next;
			continue;

                if (strlen(entry->d_name) < 4) 
			//goto next;
			continue;

#ifdef _ENABLE_TIMER
                gettimeofday(&start_t, NULL);
#endif
                input = NULL;
#ifdef _POSIX
                input = ReadFromFile(cntr, &datasize, entry->d_name, read_dir);
#else
                input = ReadFromFile_Devfs(cntr, &datasize, entry->d_name, read_dir);
#endif
                if (!input) {
                        fprintf(stdout,"failed %s \n",entry->d_name);
                        continue;
                }

                if (!datasize) 
			continue;

                bzero(fname, 256);
                strcpy(fname, (char *)output_dir);
                strcat(fname, entry->d_name);
                strcat(fname, ".comp");

                output = (char *)malloc(datasize * 2);
                assert(output);

                g_tot_input_bytes += datasize;

#ifdef _USE_THREADING
		thrdcntxt->tot_input_bytes += datasize;
#endif
                /* gettimeofday(&t0,NULL); */
                if (snappy_compress(&local_env, (const char *)input, datasize, output, &outsz) != 0) {
                        printf("compress failed\n");
                }
                if (!use_mmap && !use_nvmalloc) {
                        if (input) {
                                free(input);
                                input = NULL;
                        }
                }
                g_tot_output_bytes += outsz;

#ifdef _USE_THREADING
                thrdcntxt->tot_output_bytes += outsz;
#endif

                if (output && outsz && entry) {
#ifdef _POSIX
                        WritetoFile(output, fname, outsz);
#else
                        WritetoFile_Devfs(output, fname, outsz);
#endif
                }

                if (output) {
                       free(output);
                        output = NULL;
                }

#ifdef _ENABLE_TIMER
                gettimeofday(&end_t, NULL);
                compress_time += simulation_time(start_t, end_t);
#endif

#if 0
        next:
                if (cls_file) {
                        fclose(cls_file);
                        cls_file = NULL;
                }
#endif
        }
	g_completed++;
}

#ifndef _USE_THREADING
static void CompressDataOffload(char *read_dir) {
#else
static void CompressDataOffload(char *cntxt) {
#endif
        int tmp_fd = 0;
        char filearr[512];
        char out_fname[256];
        char tmp_file[256];
        struct stat st;

#ifdef _USE_THREADING
	struct thrd_cntxt *thrdcntxt = (struct thrd_cntxt *)cntxt;
	char *read_dir = thrdcntxt->in_path;
#endif
        DIR *mydir = opendir(read_dir);
        struct dirent *entry = NULL;
        double thruput = 0;
        struct timeval start_t, end_t;
        double sec = 0.0;
        size_t outsz = 0;

        assert(mydir);
        entry = readdir(mydir);
        assert(entry);

        /* mkdir for output directory */
        mkdir(OUTPUT_DIR, 0755);

        bzero(tmp_file, 256);
        snprintf(tmp_file, sizeof(tmp_file), "%s%d", OUTPUT_DIR "tmp_file", thrdcntxt->id);

	/* printf("test_file: %s\n", tmp_file); */
	if ((tmp_fd = crfsopen(tmp_file, O_CREAT | O_RDWR, FILEPERM)) < 0) {
		perror("creat");
		return NULL;
	}

        while ((entry = readdir(mydir)) != NULL) {
                char *output = NULL;
                char *input = NULL;

                if (entry->d_type == DT_DIR) continue;

                if (strlen(entry->d_name) < 4) continue;

                bzero(filearr, 512);
                strcpy(filearr, read_dir);
                strcat(filearr, "/");
                strcat(filearr, entry->d_name);

                stat(filearr, &st);
                if (st.st_size == 0) 
                        continue;

#ifdef _DISABLE_OPT
                bzero(out_fname, 256);
                strcat(out_fname, OUTPUT_DIR);
                strcat(out_fname, entry->d_name);
                strcat(out_fname, ".comp");
#endif

#ifdef _ENABLE_TIMER
                gettimeofday(&start_t, NULL);
#endif
                /* Issue a compress write directly, which takes fd as arg*/
                if ((outsz = devfscompresswrite(tmp_fd, &g_buf, st.st_size, filearr)) == 0) {
                        printf("File data block checksum write fail \n");
                        if (tmp_fd > 0) 
				crfsclose(tmp_fd);
                        return;
                }
#ifdef _ENABLE_TIMER
                gettimeofday(&end_t, NULL);
                compress_time += simulation_time(start_t, end_t);
#endif
#ifdef _USE_THREADING
		thrdcntxt->tot_input_bytes += st.st_size;
                thrdcntxt->tot_output_bytes += outsz;
#else
                g_tot_input_bytes += st.st_size;
                g_tot_output_bytes += outsz;
#endif
        }
	g_completed++;
        if (tmp_fd > 0) 
		crfsclose(tmp_fd);
}


void generate_path(struct thrd_cntxt *cntxt, char *str, int tdx) 
{
	int pathlen = 0;
	memset(cntxt->in_path, '0', 256);
	memset(cntxt->out_path, '0', 256);

	strcpy(cntxt->in_path, (char*)str);
	strcat(cntxt->in_path,"/");

	strcpy(cntxt->out_path, (char*)str);
	mkdir(cntxt->out_path, 0755);

	strcat(cntxt->out_path,"/OUT");

	pathlen = strlen(cntxt->in_path);
	sprintf(cntxt->in_path+pathlen,"%d",tdx);

	pathlen = strlen(cntxt->out_path);
	sprintf(cntxt->out_path+pathlen,"%d",tdx);

	mkdir(cntxt->out_path, 0755);
	strcat(cntxt->out_path,"/");
	//fprintf(stderr, "INPUT %s OUTPUT %s \n", cntxt->in_path, cntxt->out_path);
}


void thread_perform_compress(char *str, int numthreads) {

	pthread_t *thread = (pthread_t *)malloc(numthreads*sizeof(pthread_t));
	int tdx=0;

#ifndef _USE_THREADING

        if (!g_snappy_init) {
                if (snappy_init_env(&g_snappy_env)) {
                        printf("failed to init snappy environment\n");
                        return;
                }
                g_snappy_init = 1;
        }

#ifndef _COMPRESS_OFFLOAD
        CompressData((char*)str);
#else
        CompressDataOffload((char*)str);
#endif

#else //_USE_THREADING
	for (tdx=0; tdx < numthreads-1; tdx++) {

		int pathlen=0;

		generate_path(&cntxt[tdx], str, tdx+1);
                cntxt[tdx].id = tdx;
#ifndef _COMPRESS_OFFLOAD
	        if (snappy_init_env(&cntxt[tdx].env)) {
                        printf("failed to init snappy environment\n");
                        return;
                }

	        pthread_create(&thread[tdx], NULL, CompressData, (void*)&cntxt[tdx]);
#else
	        pthread_create(&thread[tdx], NULL, CompressDataOffload, (void*)&cntxt[tdx]);
#endif
	}

	generate_path(&cntxt[tdx], str, tdx+1);
        cntxt[tdx].id = tdx;

#ifndef _COMPRESS_OFFLOAD
	if (snappy_init_env(&cntxt[tdx].env)) {
		printf("failed to init snappy environment\n");
		return;
	}
	CompressData((void*)&cntxt[tdx]);
#else
	CompressDataOffload((void*)&cntxt[tdx]);
#endif
	for (tdx=0; tdx < numthreads; tdx++)
		pthread_join(thread[tdx], NULL);

	while(g_completed < numthreads-1);

	g_tot_input_bytes = 0;
	g_tot_output_bytes = 0; 

	for (tdx=0; tdx < numthreads; tdx++) {
		g_tot_input_bytes += cntxt[tdx].tot_input_bytes;
		g_tot_output_bytes += cntxt[tdx].tot_output_bytes;
	}
#endif
        fprintf(stdout, "tot input sz %zu outsz %zu\n", g_tot_input_bytes, g_tot_output_bytes);
}



int main(int argc, char **argv) {
        if (argc < 3) {
                fprintf(stdout, "enter directory and thread count to compress \n");
                return 0;
        }

        if (argc > 3) {
                return 0;
        }
        struct timeval start, end;
        double sec = 0;

        // ParaFS
        const char *shell_devfs = NULL;
        unsigned int qentrycount = USE_DEFAULT_PARAM;
        unsigned int devcorecnt = USE_DEFAULT_PARAM;
        unsigned int schedpolicy = DEFAULT_SCHEDULER_POLICY;

        /* shell_devfs = getenv("PARAFSENV");
        if (shell_devfs) {

                if (getenv("QENTRYCOUNT"))
                        qentrycount = (unsigned int)atoi(getenv("QENTRYCOUNT"));
                if (getenv("DEVCORECNT"))
                        devcorecnt = (unsigned int)atoi(getenv("DEVCORECNT"));
                if (getenv("SCHEDPOLICY"))
                        schedpolicy = (unsigned int)atoi(getenv("SCHEDPOLICY"));

                devfsinit(qentrycount, devcorecnt, schedpolicy);
        } */

#ifndef _POSIX
        crfsinit(qentrycount, devcorecnt, schedpolicy);
#endif

        gettimeofday(&start, NULL);

	thread_perform_compress(argv[1], atoi(argv[2]));

        gettimeofday(&end, NULL);
        sec = simulation_time(start, end);
        //printf("Compression takes %.2lf s\n", compress_time);
        printf("Total time: %.2lf s\n", sec);
        printf("Average throughput: %.2lf MB/s\n",
               g_tot_input_bytes/ sec / 1024 / 1024);

#ifndef _POSIX
        // ParaFS
        /* if (shell_devfs) */
        crfsexit();
#endif

        return 0;
}
