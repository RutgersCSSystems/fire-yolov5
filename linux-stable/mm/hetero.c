/*
 * mm/mmap.c
 *
 * Written by obz.
 *
 * Address space accounting code	<alan@lxorguk.ukuu.org.uk>
 */
#define pr_fmt(fmt) KBUILD_MODNAME ": " fmt

#include <linux/kernel.h>
#include <linux/slab.h>
#include <linux/backing-dev.h>
#include <linux/mm.h>
#include <linux/vmacache.h>
#include <linux/shm.h>
#include <linux/mman.h>
#include <linux/pagemap.h>
#include <linux/swap.h>
#include <linux/syscalls.h>
#include <linux/capability.h>
#include <linux/init.h>
#include <linux/file.h>
#include <linux/fs.h>
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

#include <linux/btree.h>
#include <linux/radix-tree.h>

#include <linux/buffer_head.h>
#include <linux/jbd2.h>

#include <linux/uaccess.h>
#include <asm/cacheflush.h>
#include <asm/tlb.h>
#include <asm/mmu_context.h>

#include <linux/pfn_trace.h>

#include "internal.h"

/* start_trace flag option */
#define CLEAR_COUNT	0
#define COLLECT_TRACE 1
#define PRINT_STATS 2
#define DUMP_STACK 3
#define PFN_TRACE 4
#define PFN_STAT 5
#define TIME_TRACE 6
#define TIME_STATS 7
#define TIME_RESET 8
#define COLLECT_ALLOCATE 9
#define PRINT_ALLOCATE 10


/* Flags to enable hetero allocations */
#define HETERO_PGCACHE 11
#define HETERO_BUFFER 12
#define HETERO_JOURNAL 13
#define HETERO_RADIX 14
#define HETERO_FULLKERN 15

/* Hetero Stats information*/
int global_flag = 0;
int pgcache_cnt = 0;
int radix_cnt = 0;
int heterobuff_pgs = 0;


int enbl_hetero_pgcache=0;
int enbl_hetero_buffer=0;
int enbl_hetero_journal=0;
int enbl_hetero_radix=0;
int enbl_hetero_kernel=0;

int hetero_pid = 0;
int hetero_usrpg_cnt = 0;
int hetero_kernpg_cnt = 0;
char procname[TASK_COMM_LEN];


void print_hetero_stats(void) {
       printk("hetero_pid %d Curr %d Currname %s HeteroProcname %s "
		"page cache %d page buffer %d \n", hetero_pid, current->pid, 
		current->comm, procname, pgcache_cnt, heterobuff_pgs);
}
EXPORT_SYMBOL(print_hetero_stats);

void reset_hetero_stats(void) {
        pgcache_cnt = 0;
        heterobuff_pgs = 0;
}
EXPORT_SYMBOL(reset_hetero_stats);


inline int check_hetero_proc (void) 
{
    //f(current->pid == hetero_pid && hetero_pid){
    if (current->hetero_task == HETERO_PROC){
	return 1;
    }
    return 0; 	
}


/* Exit function called during process exit */
int is_hetero_exit(void) 
{
    if(check_hetero_proc()) {
	printk("hetero_pid %d Curr %d Currname %s HeteroProcname %s  user pages %d kern pages %d\n",
		hetero_pid, current->pid, current->comm, procname,  hetero_usrpg_cnt, hetero_kernpg_cnt);
    }
    return 0;
}
EXPORT_SYMBOL(is_hetero_exit);

inline int is_hetero_obj(void *obj) 
{
	if(obj && current->hetero_obj && current->hetero_obj == obj){
		return 1;
	}
	return 0;
}
EXPORT_SYMBOL(is_hetero_obj);


void set_curr_hetero_obj(void *obj) 
{
        current->hetero_obj = obj;
}
EXPORT_SYMBOL(set_curr_hetero_obj);


void set_fsmap_hetero_obj(void *mapobj) 
{
       struct address_space *mapping = NULL;

	mapping = (struct address_space *)mapobj;
        mapping->hetero_obj = NULL;
        if(is_hetero_buffer_set()){
		struct dentry *res;
                mapping->hetero_obj = (void *)mapping->host;
                current->hetero_obj = (void *)mapping->host;
		if(mapping->host) {
			res = d_find_any_alias(mapping->host);
			printk(KERN_ALERT "\n %s:%d Inode %lu FNAME %s \n",
			 __func__,__LINE__,mapping->host->i_ino, res->d_iname);
		}
        }
}
EXPORT_SYMBOL(set_fsmap_hetero_obj);


/* Functions to test different allocation strategies */
int is_hetero_pgcache_set(void){

      if(check_hetero_proc()) 
	if(enbl_hetero_pgcache) { 	
	    	return enbl_hetero_pgcache;
    	}		
    return 0;
}
EXPORT_SYMBOL(is_hetero_pgcache_set);

int is_hetero_buffer_set(void){

    if(check_hetero_proc()) 
    {
	if(enbl_hetero_buffer) {
	    	return enbl_hetero_buffer;
    	}
    } 
   return 0;
}
EXPORT_SYMBOL(is_hetero_buffer_set);


int is_hetero_journ_set(void){

    //if(hetero_pid && current->pid == hetero_pid)
    return enbl_hetero_journal;
    return 0;
}
EXPORT_SYMBOL(is_hetero_journ_set);


int is_hetero_radix_set(void){
    if(check_hetero_proc())
    	return enbl_hetero_radix;
    return 0;
}
EXPORT_SYMBOL(is_hetero_radix_set);


int is_hetero_kernel_set(void){
    return enbl_hetero_kernel;
    return 1;
}
EXPORT_SYMBOL(is_hetero_kernel_set);


/* start trace system call */
SYSCALL_DEFINE1(start_trace, int, flag)
{

    switch(flag) {
	case CLEAR_COUNT:
	    printk("flag set to clear count %d\n", flag);
	    global_flag = CLEAR_COUNT;
	    //rbtree_reset_counter();
	    //btree_reset_counter();
	    //radix_tree_reset_counter();

	    /*reset hetero allocate flags */
	    enbl_hetero_pgcache = 0;
	    enbl_hetero_buffer = 0; 
	    enbl_hetero_radix = 0;
	    enbl_hetero_journal = 0; 
            enbl_hetero_kernel = 0;

	    reset_hetero_stats();	
	    is_hetero_exit();

	    hetero_pid = 0;
	    hetero_kernpg_cnt = 0;
	    hetero_usrpg_cnt = 0;
            memset(procname,'0', TASK_COMM_LEN);
	    break;

	case COLLECT_TRACE:
	    printk("flag is set to collect trace %d\n", flag);
	    global_flag = COLLECT_TRACE;
	    return global_flag;
	    break;
	case PRINT_STATS:
	    printk("flag is set to print stats %d\n", flag);
	    global_flag = PRINT_STATS;
	    print_rbtree_stat();
	    //print_btree_stat();
	    print_radix_tree_stat();
	    break;
	//case DUMP_STACK:
	//	printk("flag is set to dump stack %d\n", flag);
	//	global_flag = DUMP_STACK;
	//	return global_flag;
	//	break;
	
	case PFN_TRACE:
	    printk("flag is set to collect pfn trace %d\n", flag);
	    global_flag = PFN_TRACE;
	    return global_flag;
	    break;
	case PFN_STAT:
	    printk("flag is set to print pfn stats %d\n", flag);
	    print_pfn_hashtable();
	    break;
	case TIME_TRACE:
	    printk("flag is set to collect time %d \n", flag);
	    global_flag = TIME_TRACE;
	    return global_flag;
	    break;
	case TIME_STATS:
	    printk("flag is set to print time stats %d \n", flag);
	    global_flag = TIME_STATS;
	    print_rbtree_time_stat();
	    break;
	case TIME_RESET:
	    printk("flag is set to reset time %d \n", flag);
	    global_flag = TIME_RESET;
	    rbtree_reset_time();
	    break;
	case COLLECT_ALLOCATE:
	    printk("flag is set to collect hetero allocate  %d \n", flag);
	    global_flag = COLLECT_ALLOCATE;
	    return global_flag;
	    break;
	case PRINT_ALLOCATE:
	    printk("flag is set to print hetero allocate stat %d \n", flag);
	    global_flag = PRINT_ALLOCATE;
	    print_hetero_stats();
	    break;
	case HETERO_PGCACHE:
	    printk("flag is set to enable HETERO_PGCACHE %d \n", flag);
	    enbl_hetero_pgcache = 1;
	    break;
	case HETERO_BUFFER:
	    printk("flag is set to enable HETERO_BUFFER %d \n", flag);
	    enbl_hetero_buffer = 1;
	    break;
	case HETERO_JOURNAL:
	    printk("flag is set to enable HETERO_JOURNAL %d \n", flag);
	    enbl_hetero_journal = 1;
	    break;
	case HETERO_RADIX:
	    printk("flag is set to enable HETERO_RADIX %d \n", flag);
	    enbl_hetero_radix = 1;
	    break;
	case HETERO_FULLKERN:
	    printk("flag is set to enable HETERO_FULLKERN %d \n", flag);
	    enbl_hetero_kernel = 1;
	    break;
	default:
	    hetero_pid = flag;
	    current->hetero_task = HETERO_PROC;
            memcpy(procname, current->comm, TASK_COMM_LEN);
	    printk("hetero_pid set to %d %d procname %s\n", hetero_pid, current->pid, procname);			
	    break;
    }
    return 0;
}



