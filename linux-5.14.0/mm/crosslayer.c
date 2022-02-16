#define pr_fmt(fmt) KBUILD_MODNAME ": " fmt

#include <linux/kernel.h>
#include <linux/slab.h>
#include <linux/backing-dev.h>
#include <linux/mm.h>
#include <linux/mm_inline.h>
#include <linux/mmzone.h>
#include <linux/vmacache.h>
#include <linux/shm.h>
#include <linux/mman.h>
#include <linux/pagemap.h>
#include <linux/swap.h>
#include <linux/syscalls.h>
#include <linux/capability.h>
#include <linux/init.h>
#include <linux/file.h>
#include <linux/personality.h>
#include <linux/security.h>
#include <linux/hugetlb.h>
#include <linux/shmem_fs.h>
#include <linux/profile.h>
#include <linux/export.h>
#include <linux/mount.h>
#include <linux/mempolicy.h>
#include <linux/rmap.h>
#include <linux/mmu_notifier.h>
#include <linux/mmdebug.h>
#include <linux/perf_event.h>
#include <linux/audit.h>
#include <linux/khugepaged.h>
#include <linux/uprobes.h>
#include <linux/rbtree_augmented.h>
#include <linux/notifier.h>
#include <linux/memory.h>
#include <linux/printk.h>
#include <linux/userfaultfd_k.h>
#include <linux/moduleparam.h>
#include <linux/pkeys.h>
#include <linux/oom.h>
#include <linux/jiffies.h>

#include <linux/btree.h>
#include <linux/radix-tree.h>

#include <linux/buffer_head.h>
#include <linux/jbd2.h>

#include <linux/uaccess.h>
#include <asm/cacheflush.h>
#include <asm/tlb.h>
#include <asm/atomic.h>
#include <asm/mmu_context.h>
//#include <linux/pfn_trace.h>
#include <net/sock.h>
#include <linux/migrate.h>
//#include <sys/time.h>
#include <linux/time64.h>
#include <linux/fs.h>


#include "internal.h"

#define ENABLE_FILE_STATS 1
#define DISABLE_FILE_STATS 2
#define RESET_GLOBAL_STATS 3
#define PRINT_GLOBAL_STATS 4
#define CACHE_USAGE_CONS 5
#define CACHE_USAGE_DEST 6
#define CACHE_USAGE_RET 7
#define CACHE_USAGE_RESET 8
#define WALK_PAGECACHE 9

struct file_pfetch_state global_counts; //global counters

#ifdef CONFIG_CACHE_LIMITING
/*
 * This config counts nr of cache pages
 * for a given subset of task_structs
 */
atomic_long_t cache_usage; //nr_pages
atomic_long_t nr_procs; //nr_procs limiting cache usage
/*
 * to be called in the constructor of the 
 * application of interest
 */
void cache_limit_cons(void){
        if(!current->mm)
                return;

        if(!current->do_cache_acct){
                current->do_cache_acct = true;
                atomic_long_add(1UL, &nr_procs);
        }
        return;
}
EXPORT_SYMBOL(cache_limit_cons);


/*
 * To be called at destructor
 */
void cache_limit_dest(void){
        if(!current->mm)
                return;

        long nr = -1;

        if(current->do_cache_acct){
                current->do_cache_acct = false;
                nr = atomic_long_sub_return(1UL, &nr_procs);

                if(!nr){
                        /*if no process left, reset cache usage*/
                        printk("%s: total cache usage at the end = %ld\n", 
                                        __func__, cache_usage_ret());
                        cache_limit_reset();
                }
        }

        return;
}
EXPORT_SYMBOL(cache_limit_dest);

/*To be called at system boot*/
void cache_limit_reset(void){
        atomic_long_set(&cache_usage, 0UL);
        atomic_long_set(&nr_procs, 0UL);
}
EXPORT_SYMBOL(cache_limit_reset);

/*reduces cache usage by nr_pages*/
void cache_usage_reduce(int nr_pages){
        if(!current->mm)
                return;

        if(current->do_cache_acct){
                atomic_long_sub(nr_pages, &cache_usage);
        }
        return;
}
EXPORT_SYMBOL(cache_usage_reduce);

/*increases cache usage by nr_pages*/
void cache_usage_increase(int nr_pages){
        if(!current->mm)
                return;

        if(current->do_cache_acct){
                atomic_long_add(nr_pages, &cache_usage);
        }
        return;
}
EXPORT_SYMBOL(cache_usage_increase);

/*returns the current cache usage*/
long cache_usage_ret(void){
        return atomic_long_read(&cache_usage);
}
EXPORT_SYMBOL(cache_usage_ret);
#endif



void init_file_pfetch_state(struct file_pfetch_state *pfetch_state){

        spin_lock_init(&pfetch_state->spinlock);

        spin_lock(&pfetch_state->spinlock);

        //disable cross layer flag for this process
        current->is_crosslayer = 0;

        pfetch_state->enable_f_stats = 0;
        pfetch_state->is_app_readahead = 0;

        pfetch_state->ra_final_nr_pages = 0;
        pfetch_state->ra_orig_nr_pages = 0;

        pfetch_state->async_pages = 0;
        pfetch_state->final_async_pages = 0;

        pfetch_state->full_pfetches = 0;
        pfetch_state->less256_pfetches = 0;
        pfetch_state->partial_pfetches = 0;
        pfetch_state->failed_pfetches = 0;
        pfetch_state->total_pfetches = 0;
        pfetch_state->os_pfetches = 0; // nr of pfetches done by the OS

        pfetch_state->nr_pages_read = 0;
        pfetch_state->nr_pages_hit = 0;
        pfetch_state->nr_pages_miss = 0;
        pfetch_state->nr_do_read_fault = 0;

        pfetch_state->last_jiffies = 0;
        pfetch_state->_nr_pages_read = 0;
        pfetch_state->_nr_pages_hit = 0;
        pfetch_state->_nr_pages_miss = 0;
        pfetch_state->_nr_do_read_fault = 0;

        spin_unlock(&pfetch_state->spinlock);

}
EXPORT_SYMBOL(init_file_pfetch_state);


void add_nr_read_fault(struct task_struct *task){

        /*
         * Update global counters
         */
        spin_lock(&global_counts.spinlock);
        global_counts.nr_do_read_fault += 1;
        spin_unlock(&global_counts.spinlock);

        if(!task->mm || !task->pfetch_state.enable_f_stats)
                goto err;

        spin_lock(&task->pfetch_state.spinlock);

        /*High number of faults means the program has to wait longer*/
        task->pfetch_state.nr_do_read_fault += 1; // faults are done one page at a time

        spin_unlock(&task->pfetch_state.spinlock);

err:
        return;
}
EXPORT_SYMBOL(add_nr_read_fault);


void update_read_cache_stats(struct task_struct *task, unsigned long nr_pg_reads,
                unsigned long nr_pg_in_cache, unsigned long nr_misses, 
                struct file *filp) 
{

        /*
         * Update global counters
         */
        spin_lock(&global_counts.spinlock);

        global_counts._nr_pages_read += nr_pg_reads;
        global_counts._nr_pages_hit += nr_pg_in_cache;
        global_counts._nr_pages_miss += nr_misses;


        if(filp && current->is_crosslayer) {
                filp->nr_cache_miss +=  nr_misses;
                filp->nr_cache_hits +=  nr_pg_in_cache;
                printk(KERN_ALERT "FILE %s, misses %lu, hits %lu \n",
                                filp->f_path.dentry->d_iname, 
                                filp->nr_cache_miss, 
                                filp->nr_cache_hits);
        }


        //prints global stats after 1000 msecs
        if(jiffies_to_msecs(jiffies - global_counts.last_jiffies) >= 1000){
                global_counts.last_jiffies = jiffies;

                global_counts.nr_pages_read += global_counts._nr_pages_read;
                global_counts.nr_pages_hit += global_counts._nr_pages_hit;
                global_counts.nr_pages_miss += global_counts._nr_pages_miss;

                /* 
                 * BUG FIX: Doesn't make sense to simply print stats without 
                 * checking which process it is 
                 */
                if(current->is_crosslayer)
                        print_inter_global_stats();

                global_counts._nr_pages_read = 0;
                global_counts._nr_pages_hit = 0;
                global_counts._nr_pages_miss = 0;

        }

        spin_unlock(&global_counts.spinlock);

        if(!task->mm || !task->pfetch_state.enable_f_stats)
                goto err;

        //A page being in Page Cache doesnt mean it is usable.
        //It isnt usable if that page is just allocated by is not populated
        //In such a case, the task has to wait for page to be populated by do_read_fault()

        spin_lock(&task->pfetch_state.spinlock);

        task->pfetch_state.nr_pages_read += nr_pg_reads;
        task->pfetch_state.nr_pages_hit += nr_pg_in_cache;
        task->pfetch_state.nr_pages_miss += nr_misses;

        spin_unlock(&task->pfetch_state.spinlock);

err:
        return;
}
EXPORT_SYMBOL(update_read_cache_stats);


void update_ra_final_nr_pages(struct task_struct *task, struct inode *inode, 
                struct readahead_control *ractl, unsigned long nr_pages)
{
        if(!ractl || !task || !inode)
                goto err;

        if(!task->mm || !task->pfetch_state.enable_f_stats)
                goto err;

        if(task->pfetch_state.enable_f_stats){
                inode->pfetch_state.enable_f_stats = true;
                ractl->pfetch_state.enable_f_stats = true;
                if(ractl->pfetch_state.is_app_readahead){
                        ractl->pfetch_state.ra_final_nr_pages += nr_pages;
                        /*add locking for inode and task*/
                        spin_lock(&inode->pfetch_state.spinlock);
                        inode->pfetch_state.ra_final_nr_pages += nr_pages;
                        spin_unlock(&inode->pfetch_state.spinlock);

                        spin_lock(&task->pfetch_state.spinlock);
                        task->pfetch_state.ra_final_nr_pages += nr_pages;
                        spin_unlock(&task->pfetch_state.spinlock);
                }
        }

err:
        return;
}
EXPORT_SYMBOL(update_ra_final_nr_pages);


void update_ra_orig_nr_pages(struct task_struct *task, struct inode *inode, 
                struct readahead_control *ractl, unsigned long nr_pages)
{
        if(!ractl || !task || !inode)
                goto err;

        if(!task->mm || !task->pfetch_state.enable_f_stats)
                goto err;

        if(task->pfetch_state.enable_f_stats){
                inode->pfetch_state.enable_f_stats = true;
                ractl->pfetch_state.enable_f_stats = true;
                if(ractl->pfetch_state.is_app_readahead){
                        ractl->pfetch_state.ra_orig_nr_pages += nr_pages;

                        spin_lock(&inode->pfetch_state.spinlock);
                        inode->pfetch_state.ra_orig_nr_pages += nr_pages;
                        spin_unlock(&inode->pfetch_state.spinlock);

                        spin_lock(&task->pfetch_state.spinlock);
                        task->pfetch_state.ra_orig_nr_pages += nr_pages;
                        task->pfetch_state.total_pfetches += 1; //increments the total nr of fadvices
                        spin_unlock(&task->pfetch_state.spinlock);
                }
        }

err:
        return;
}
EXPORT_SYMBOL(update_ra_orig_nr_pages);


/*
 * updates the number of pages being fetched asynchronously for a given task
 * Assumes that readahead functions are fetching pages asynchronously.
 *
 * XXX: Our recent sensitivity study has shown that readaheads are not async,
 * so this metric is not completely correct
 */
void update_async_pages(struct task_struct *task, struct inode *inode, 
                struct readahead_control *ractl, unsigned long nr_pages)
{
        if(!ractl || !task || !inode)
                goto err;

        if(!task->mm)
                goto err;

        if(task->pfetch_state.enable_f_stats){
                inode->pfetch_state.enable_f_stats = true;
                ractl->pfetch_state.enable_f_stats = true;

                if(!ractl->pfetch_state.is_app_readahead){
                        ractl->pfetch_state.async_pages += nr_pages;

                        spin_lock(&inode->pfetch_state.spinlock);
                        inode->pfetch_state.async_pages += nr_pages;
                        spin_unlock(&inode->pfetch_state.spinlock);

                        spin_lock(&task->pfetch_state.spinlock);
                        task->pfetch_state.async_pages += nr_pages;
                        spin_unlock(&task->pfetch_state.spinlock);
                }
        }

err:
        return;
}
EXPORT_SYMBOL(update_async_pages);


void update_final_async_pages(struct task_struct *task, struct inode *inode, 
                struct readahead_control *ractl, unsigned long nr_pages)
{
        if(!ractl || !task || !inode)
                goto err;

        if(!task->mm)
                goto err;

        if(task->pfetch_state.enable_f_stats){
                inode->pfetch_state.enable_f_stats = true;
                ractl->pfetch_state.enable_f_stats = true;

                if(!ractl->pfetch_state.is_app_readahead){
                        ractl->pfetch_state.final_async_pages += nr_pages;

                        spin_lock(&inode->pfetch_state.spinlock);
                        inode->pfetch_state.final_async_pages += nr_pages;
                        spin_unlock(&inode->pfetch_state.spinlock);

                        spin_lock(&task->pfetch_state.spinlock);
                        task->pfetch_state.final_async_pages += nr_pages;
                        spin_unlock(&task->pfetch_state.spinlock);
                }
        }

err:
        return;
}
EXPORT_SYMBOL(update_final_async_pages);


/*
 * updates how many times: complete pfetch was taken vs not
 * @ task - task doing the readahead/fadvice
 * @ ractl - concerned ractl for this readahead/fadvice
 * @ final_nr_pages - nr_pages finally sent for bio to fs
 */
void update_pfetch_success(struct task_struct *task, struct inode *inode,
                struct readahead_control *ractl, unsigned long final_nr_pages){

        if(!ractl || !task || !inode)
                goto err;

        if(!task->mm || !task->pfetch_state.enable_f_stats)
                goto err;

        if(ractl->pfetch_state.is_app_readahead){

                /*equal*/
                if(ractl->pfetch_state.ra_orig_nr_pages == final_nr_pages)// ||
                        //ractl->pfetch_state.ra_orig_nr_pages == (final_nr_pages + 256))
                {
                        spin_lock(&task->pfetch_state.spinlock);
                        task->pfetch_state.full_pfetches += 1;
                        spin_unlock(&task->pfetch_state.spinlock);

                        spin_lock(&inode->pfetch_state.spinlock);
                        inode->pfetch_state.full_pfetches += 1;
                        spin_unlock(&inode->pfetch_state.spinlock);
                        goto err;
                }

                if((ractl->pfetch_state.ra_orig_nr_pages - final_nr_pages) <= 256){
                        spin_lock(&task->pfetch_state.spinlock);
                        task->pfetch_state.less256_pfetches += 1;
                        spin_unlock(&task->pfetch_state.spinlock);

                        spin_lock(&inode->pfetch_state.spinlock);
                        inode->pfetch_state.less256_pfetches += 1;
                        spin_unlock(&inode->pfetch_state.spinlock);
                        goto err;
                }

                /*No final_pages*/
                if(final_nr_pages == 0){
                        spin_lock(&task->pfetch_state.spinlock);
                        task->pfetch_state.failed_pfetches += 1;
                        spin_unlock(&task->pfetch_state.spinlock);

                        spin_lock(&inode->pfetch_state.spinlock);
                        inode->pfetch_state.failed_pfetches += 1;
                        spin_unlock(&inode->pfetch_state.spinlock);
                        goto err;
                }

                if(ractl->pfetch_state.ra_orig_nr_pages > final_nr_pages){
                        spin_lock(&task->pfetch_state.spinlock);
                        task->pfetch_state.partial_pfetches += 1;
                        spin_unlock(&task->pfetch_state.spinlock);

                        spin_lock(&inode->pfetch_state.spinlock);
                        inode->pfetch_state.partial_pfetches += 1;
                        spin_unlock(&inode->pfetch_state.spinlock);
                }
        }
        else{ //noractl
                spin_lock(&task->pfetch_state.spinlock);
                task->pfetch_state.os_pfetches += 1;
                spin_unlock(&task->pfetch_state.spinlock);

                spin_lock(&inode->pfetch_state.spinlock);
                inode->pfetch_state.os_pfetches += 1;
                spin_unlock(&inode->pfetch_state.spinlock);
        }

err:
        return;
}


void print_ractl_stats(struct readahead_control *ractl){
        return;
        if(!ractl)
                goto err;

        struct file_pfetch_state *pfstate = &ractl->pfetch_state; 

        /*
           if(!pfstate->is_app_readahead)
           goto err;
           */
        if(!current->mm || !current->pfetch_state.enable_f_stats)
                goto err;



        char *f_name = kmalloc(NAME_MAX+1, GFP_KERNEL);
        char *name = dentry_path_raw(ractl->file->f_path.dentry, f_name, NAME_MAX);

        if(pfstate->is_app_readahead){
                printk("RA_FinalRactlReport: %s - ra_orig_nr_pages:%lu, ra_final_nr_pages:%lu\n \
                                async_pages:%lu, final_async_pages:%lu\n \
                                full_pfetches:%lu, partial_pfetches:%lu, failed_pfetches:%lu\n", 
                                name, pfstate->ra_orig_nr_pages, pfstate->ra_final_nr_pages,
                                pfstate->async_pages, pfstate->final_async_pages,
                                pfstate->full_pfetches, pfstate->partial_pfetches, pfstate->failed_pfetches);
        }
        else
                printk("NORA_FinalRactlReport: %s - ra_orig_nr_pages:%lu, ra_final_nr_pages:%lu\n \
                                async_pages:%lu, final_async_pages:%lu\n \
                                full_pfetches:%lu, partial_pfetches:%lu, failed_pfetches:%lu\n", 
                                name, pfstate->ra_orig_nr_pages, pfstate->ra_final_nr_pages,
                                pfstate->async_pages, pfstate->final_async_pages,
                                pfstate->full_pfetches, pfstate->partial_pfetches, pfstate->failed_pfetches);


        kfree(f_name);

err:
        return;
}
EXPORT_SYMBOL(print_ractl_stats);


void print_inode_stats(struct inode *inode){
        return;
        if(!inode)
                goto err;

        if(!inode->pfetch_state.enable_f_stats)
                goto err;

        if(!current->mm || !current->pfetch_state.enable_f_stats)
                goto err;

        struct file_pfetch_state *pfstate = &inode->pfetch_state; 

        char *f_name = kmalloc(NAME_MAX+1, GFP_KERNEL);
        char *name = dentry_path_raw(inode->i_sb->s_root, f_name, NAME_MAX);

        printk("FinalFileReport: %s - ra_orig_nr_pages:%lu, ra_final_nr_pages:%lu\n \
                        async_pages:%lu, final_async_pages:%lu\n \
                        full_pfetches:%lu, less256_pfetches:%lu, partial_pfetches:%lu\n \
                        failed_pfetches:%lu, os_pfetches:%lu\n", 
                        name, pfstate->ra_orig_nr_pages, pfstate->ra_final_nr_pages,
                        pfstate->async_pages, pfstate->final_async_pages, pfstate->full_pfetches,
                        pfstate->less256_pfetches, pfstate->partial_pfetches, 
                        pfstate->failed_pfetches, pfstate->os_pfetches);

        kfree(f_name);
err:
        return;
}
EXPORT_SYMBOL(print_inode_stats);


void print_task_stats(struct task_struct *task){
        if(!task)
                goto err;

        if(!task->mm || !task->pfetch_state.enable_f_stats)
                goto err;


        struct file_pfetch_state *pfstate = &task->pfetch_state; 

        printk("FinalTaskReport: %s:%d - ra_orig_nr_pages:%lu, ra_final_nr_pages:%lu\n \
                        async_pages:%lu, final_async_pages:%lu\n \
                        full_pfetches:%lu, less256_pfetches:%lu, partial_pfetches:%lu\n \
                        failed_pfetches:%lu, total_pfetches:%lu, os_pfetches:%lu\n \
                        nr_pages_read:%lu, nr_pages_hit:%lu, nr_do_read_fault:%lu\n", 
                        task->comm, task->pid, pfstate->ra_orig_nr_pages, pfstate->ra_final_nr_pages,
                        pfstate->async_pages, pfstate->final_async_pages, pfstate->full_pfetches,
                        pfstate->less256_pfetches, pfstate->partial_pfetches,
                        pfstate->failed_pfetches, pfstate->total_pfetches, pfstate->os_pfetches,
                        pfstate->nr_pages_read, pfstate->nr_pages_hit, pfstate->nr_do_read_fault);

err:
        return;
}
EXPORT_SYMBOL(print_task_stats);


/*
 * Prints the final total global stats; at the end of the app run
 */
void print_final_global_stats(void){
        printk("Final GlobalReport: nr_pages_read:%lu, nr_pages_hit:%lu, nr_do_read_fault:%lu, nr_pages_miss:%lu\n", 
                        global_counts.nr_pages_read, global_counts.nr_pages_hit, 
                        global_counts.nr_do_read_fault, global_counts.nr_pages_miss);

        return;
}
EXPORT_SYMBOL(print_final_global_stats);


/*
 * Prints the intermediate global stats
 * Prints stats from last_jiffies timestamp
 */
void print_inter_global_stats(void){
        printk("Intermediate GlobalReport: nr_pages_read:%lu, nr_pages_hit:%lu, nr_pages_miss:%lu\n", 
                        global_counts._nr_pages_read, global_counts._nr_pages_hit, global_counts._nr_pages_miss);
        return;
}
EXPORT_SYMBOL(print_inter_global_stats);


void init_global_pfetch_state(void){
        init_file_pfetch_state(&global_counts);
}


//Syscall Nr: 448
SYSCALL_DEFINE2(start_cross_trace, int, flag, int, val){
#ifdef CONFIG_ENABLE_CROSSLAYER
        switch(flag){

                case ENABLE_FILE_STATS:
                        current->pfetch_state.enable_f_stats = true;
                        /* Enable per-process cross-layer flag */
                        current->is_crosslayer = true;
                        printk("Enabled file stats for %s:%d\n", current->comm, current->pid);
                        break;
                case DISABLE_FILE_STATS:
                        current->pfetch_state.enable_f_stats = false;
                        printk("Disabled file stats for %s:%d\n", current->comm, current->pid);
                        break;
                case RESET_GLOBAL_STATS:
                        //init_file_pfetch_state(&global_counts);
                        printk("%s: RESET_GLOBAL_STATS \n", __func__);
                        init_global_pfetch_state();
                        break;
                case PRINT_GLOBAL_STATS:
                        printk("%s: PRINT_GLOBAL_STATS \n", __func__);
                        print_final_global_stats();
                        break; 
#ifdef CONFIG_CACHE_LIMITING
                case CACHE_USAGE_CONS:
                        cache_limit_cons();
                        printk("%s:Enabled cache limiting for %s:%d\n", __func__, current->comm, current->pid);
                        break;
                case CACHE_USAGE_DEST:
                        cache_limit_dest();
                        printk("%s: Disabled cache limiting for %s:%d\n", __func__, current->comm, current->pid);
                        break;
                case CACHE_USAGE_RET:
                        return cache_usage_ret();
                        break;
                case CACHE_USAGE_RESET:
                        cache_limit_reset();
                        printk("%s: Resetting the values\n", __func__);
                        break;
                case WALK_PAGECACHE:
                        //This will walk the page cache for a given fd and return the
                        //number of populated pages in the page cache
                        printk("%s: NR of pages in PC for FD=%d = %ld \n", __func__, val, 
                                        filemap_walk_pagecache(val));
                        break;
#endif
                default:
                        /* Enable per-process cross-layer flag */
                        current->is_crosslayer = true;
                        printk("Flag value undefined %d\n", flag);
                        /* 
                         * BUG FIX: We cannot return and break!!!
                         */
                        return -1;
        }
#endif
        return 0;
}
