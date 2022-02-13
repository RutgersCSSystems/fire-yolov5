#ifndef _LINUX_CROSSLAYER_H
#define _LINUX_CROSSLAYER_H

//#include <linux/fs.h>

struct file_pfetch_state;
struct readahead_control;
struct inode;
struct read_ra_req;

/**
 * struct file_pfetch_state - track a file's prefetch stats.
 *
 */
struct file_pfetch_state {
    spinlock_t		spinlock;
    /*vars updated only on force_page_cache_ra*/
    bool enable_f_stats;
    bool is_app_readahead; //true if app is doing readahead
    unsigned long ra_final_nr_pages; //fadvice: final pages submitted for bio
    unsigned long ra_orig_nr_pages; //pages to be readahead originally

    /*only OS internal pfetching */
    unsigned long async_pages; //pages deemed for prefetching by OS
    unsigned long final_async_pages; //pages finally prefetched by the OS

    /*general stats*/
    unsigned long full_pfetches; // if asked = done
    unsigned long less256_pfetches ; // if asked = done + 256
    unsigned long partial_pfetches; // if asked > done
    unsigned long failed_pfetches; // if done = 0
    unsigned long total_pfetches; // total fadvise calls
    unsigned long os_pfetches; // nr of pfetches done by the OS


    /*Global Read Cache-hits stats*/
    unsigned long nr_pages_read; //total bytes read in task's lifetime
    unsigned long nr_pages_hit; //total bytes already in PG_cache
    unsigned long nr_pages_miss; //total pages not in PG_cache
    unsigned long nr_do_read_fault; //total nr of read faults 

    /*Prints intermediate information*/
    unsigned long last_jiffies; //stores the previous event jiffies timestamp
    unsigned long _nr_pages_read; //nr pages read from last_jiffies timestamp
    unsigned long _nr_pages_hit; //nr pages hit in PG_cache since last_jiffies stamp
    unsigned long _nr_pages_miss; //nr pages miss in in PG_cache since last_jiffies
    unsigned long _nr_do_read_fault; //nr faults since last_jiffies
};


/*
 * User request for readaheads with read
 * see pread_ra SYSCALL in fs/read_write.c
 */
struct read_ra_req {
    loff_t ra_pos;
    size_t ra_count;
    
    /*The following are return values from the OS
     * Reset at recieving them
     */
    unsigned long nr_present; //nr pages present in cache
    unsigned long bio_req_nr;//nr pages requested bio for

//#ifdef CONFIG_CACHE_LIMITING
    long total_cache_usage; //total cache usage in bytes (OS return)
    bool full_file_ra; //populated by app true if pread_ra is being done to get full file
    long cache_limit; //populated by the app, desired cache_limit
//#endif
};


void init_global_pfetch_state(void);

void init_file_pfetch_state(struct file_pfetch_state *pfetch_state);

void add_nr_read_fault(struct task_struct *task);

void update_read_cache_stats(struct task_struct *task, unsigned long nr_pg_reads,
        unsigned long nr_pg_in_cache, unsigned long nr_misses, struct file *filp);

void update_ra_final_nr_pages(struct task_struct *task, struct inode *inode, 
        struct readahead_control *ractl, unsigned long nr_pages);

void update_ra_orig_nr_pages(struct task_struct *task, struct inode *inode, 
        struct readahead_control *ractl, unsigned long nr_pages);

void update_async_pages(struct task_struct *task, struct inode *inode, 
        struct readahead_control *ractl, unsigned long nr_pages);

void update_final_async_pages(struct task_struct *task, struct inode *inode, 
        struct readahead_control *ractl, unsigned long nr_pages);

void update_pfetch_success(struct task_struct *task, struct inode *inode,
        struct readahead_control *ractl, unsigned long final_nr_pages);

void print_task_stats(struct task_struct *task);
void print_inode_stats(struct inode *inode);
void print_ractl_stats(struct readahead_control *ractl);
void print_global_stats(void);
void print_inter_global_stats(void);

#ifdef CONFIG_CACHE_LIMITING
void cache_limit_cons(void);
void cache_limit_dest(void);
void cache_limit_reset(void);
long cache_usage_ret(void);
void cache_usage_increase(int nr_pages);
void cache_usage_reduce(int nr_pages);
#endif

#endif
