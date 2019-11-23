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
#include <net/sock.h>
#include <linux/migrate.h>
//#include <sys/time.h>
#include <linux/time64.h>

#include "internal.h"

/* start_trace flag option */
#define CLEAR_GLOBALCOUNT 0
#define COLLECT_TRACE 1
#define PRINT_GLOBAL_STATS 2
#define DUMP_STACK 3
#define PFN_TRACE 4
#define PFN_STAT 5
#define TIME_TRACE 6
#define TIME_STATS 7
#define TIME_RESET 8
#define COLLECT_ALLOCATE 9
#define PRINT_ALLOCATE 10

/* 
Flags to enable hetero allocations.
Move this to header file later.
*/
#define HETERO_PGCACHE 11
#define HETERO_BUFFER 12
#define HETERO_JOURNAL 13
#define HETERO_RADIX 14
#define HETERO_FULLKERN 15
#define HETERO_SET_FASTMEM_NODE 16
#define HETERO_MIGRATE_FREQ 17
#define HETERO_OBJ_AFF 18
#define HETERO_DISABLE_MIGRATE 19
#define HETERO_MIGRATE_LISTCNT 20
#define HETERO_SET_CONTEXT 21
#define HETERO_NET 22
#define HETERO_PGCACHE_READAHEAD 23

/* Collect life time of page 
*/
#define HETERO_COLLECT_LIFETIME

#ifdef HETERO_COLLECT_LIFETIME
unsigned int g_avg_cachepage_life = 0;
unsigned int g_avg_kbufpage_life = 0;
unsigned int g_cache_pages_deleted = 0;
unsigned int g_buff_pages_deleted = 0;
#endif

//#define _ENABLE_HETERO_THREAD
#ifdef _ENABLE_HETERO_THREAD
#define MAXTHREADS 10
struct migrate_threads {
	struct task_struct *thrd;
};
struct migrate_threads THREADS[MAXTHREADS] = {0};

volatile int thrd_idx = 0;
volatile int migration_thrd_active=0;
volatile int spinlock=0;
DEFINE_SPINLOCK(kthread_lock);
#endif

/* Hetero Stats information*/
int global_flag = 0;
int radix_cnt = 0;
int hetero_dbgmask = 0;

int enbl_hetero_pgcache=0;
int enbl_hetero_buffer=0;
int enbl_hetero_journal=0;
int enbl_hetero_radix=0;
int enbl_hetero_kernel=0;
int enbl_hetero_set_context=0;
int hetero_fastmem_node=0;
int enbl_hetero_objaff=0;
int disabl_hetero_migrate=0;
int enbl_hetero_net=0;
int enbl_hetero_pgcache_readahead=0;

//Frequency of migration
int g_migrate_freq=0;
//Migration list threshold
int min_migrate_cnt=0;


int hetero_pid=0;
int hetero_usrpg_cnt=0;
int hetero_kernpg_cnt=0;
long migrate_time=0;

unsigned long g_cachehits=0;
unsigned long g_cachemiss=0;
unsigned long g_buffhits=0;
unsigned long g_buffmiss=0;
unsigned long g_migrated=0;
unsigned long g_cachedel=0;
unsigned long g_buffdel=0;

#ifdef CONFIG_HETERO_STATS
unsigned long g_tot_cache_pages=0;
unsigned long g_tot_buff_pages=0;
unsigned long g_tot_app_pages=0;
#endif

DEFINE_SPINLOCK(stats_lock);

#ifdef CONFIG_HETERO_STATS
void incr_tot_cache_pages(void) 
{
	if(!is_hetero_pgcache_set())
		return;

	//spin_lock(&stats_lock);
	g_tot_cache_pages++;
	//spin_unlock(&stats_lock);
}

void incr_tot_buff_pages(void) 
{
	if(!is_hetero_buffer_set())
		return;

	//spin_lock(&stats_lock);
	g_tot_buff_pages++;
	//spin_unlock(&stats_lock);
}

void incr_tot_app_pages(void) 
{
	if(!is_hetero_pgcache_set()) 
		return;

	//spin_lock(&stats_lock);
	g_tot_app_pages++;
	/*if(g_tot_app_pages) {
		g_tot_app_pages = (g_tot_app_pages - g_tot_cache_pages  -
					g_tot_buff_pages);
	}*/
	//spin_unlock(&stats_lock);
}
#endif


#ifdef CONFIG_HETERO_ENABLE
void incr_global_stats(unsigned long *counter){
	//spin_lock(&stats_lock);
	*counter = *counter + 1;	
	//spin_unlock(&stats_lock);
}

void print_global_stats(void) {

       printk("cache-hits %lu cache-miss %lu " 
	      "buff-hits %lu buff-miss %lu " 
	      "migrated %lu cache-del %lu " 
	      "buff-del %lu \n", 
		g_cachehits, g_cachemiss, g_buffhits, 
		g_buffmiss, g_migrated, g_cachedel,
		g_buffdel);

#ifdef CONFIG_HETERO_STATS
  	printk("ANALYSIS STAT CACHE-PAGES %lu, BUFF-PAGES %lu, APP-PAGES %lu \n",
		g_tot_cache_pages, g_tot_buff_pages, g_tot_app_pages);
#endif

#ifdef HETERO_COLLECT_LIFETIME
	//buffpgs = mm->pgbuffdel;
	//cachepgs = mm->pgcachedel;
	if(g_avg_cachepage_life && g_avg_kbufpage_life && g_buff_pages_deleted && g_cache_pages_deleted) {
		  printk("ANALYSIS LIFESTAT  CACHE-PAGE-LIFE %lu, BUFF-PAGE-LIFE %lu CACHE_PAGES_ALLOC_DELETE %lu " 
			" BUFF_PAGES_ALLOC_DELETE %lu g_avg_cachepage_life %lu, g_avg_kbufpage_life %lu \n",
			  jiffies_to_msecs(g_avg_cachepage_life/g_cache_pages_deleted), jiffies_to_msecs(g_avg_kbufpage_life/g_buff_pages_deleted), 
			  g_cache_pages_deleted, g_buff_pages_deleted, g_avg_cachepage_life/g_cache_pages_deleted, g_avg_kbufpage_life/g_buff_pages_deleted);
	}
#endif
}
EXPORT_SYMBOL(print_global_stats);


struct mm_struct* 
getmm(struct task_struct *task) 
{
        struct mm_struct *mm = NULL;

        if(task->mm) {
                mm = task->mm;
	}
        else if(task->active_mm) {
                mm = task->active_mm;
	}
	return mm;
}


void 
print_hetero_stats(struct task_struct *task) 
{
#ifdef CONFIG_HETERO_STATS
	unsigned long buffpgs = 0;
	unsigned long cachepgs = 0;
	struct mm_struct *mm = NULL;

	mm = getmm(task);
	if(!mm)
		return;

#if 0
        printk("EXITING PROCESS PID %d Currname %s " 
		"cache-hits %lu cache-miss %lu " 
	      	"buff-hits %lu buff-miss %lu " 
		"migrated %lu migrate_time %ld " 
                "avg_buff_life(us) %ld pgbuff-del %lu " 
		"avg_cache_life(us) %ld pgcache-del %lu " 
		"active-cache %lu\n ", 
	  	task->pid, task->comm, mm->pgcache_hits_cnt, 
		mm->pgcache_miss_cnt, 
	      	mm->pgbuff_hits_cnt, mm->pgbuff_miss_cnt, 
		mm->pages_migrated, migrate_time, 
                avgbuff_life, mm->pgbuffdel, avgcache_life, 
		mm->pgcachedel, 
		(mm->pgcache_hits_cnt - mm->pgcachedel)
       );
#endif
#endif
}
EXPORT_SYMBOL(print_hetero_stats);


void reset_hetero_stats(struct task_struct *task) {

#ifdef CONFIG_HETERO_STATS
	g_cachehits = 0;
	g_cachemiss = 0;
	g_buffhits = 0;
	g_buffmiss = 0;
	g_migrated = 0;
	g_cachedel = 0;
	g_buffdel = 0;

	g_tot_cache_pages = 0;
	g_tot_buff_pages = 0;
	g_tot_app_pages = 0;
#endif
}
EXPORT_SYMBOL(reset_hetero_stats);

#if 0
long 
timediff (struct timeval *start, struct timeval *end) 
{
	long diff = 0;

	if(start->tv_sec*1000000 + start->tv_usec == 0) {
		return 0;
	}
	diff = (end->tv_sec*1000000 + end->tv_usec) - 
			(start->tv_sec*1000000 + start->tv_usec);
	return diff;
}
#endif

unsigned long 
timediff (unsigned long start, unsigned long end) 
{
	return (end - start);
}


int 
check_listcnt_threshold (unsigned int count)
{

	if(min_migrate_cnt > count) 
		return 0;
	else
		return 1;
}
EXPORT_SYMBOL(check_listcnt_threshold);

/*
* Callers responsibility to check mm is not NULL
*/
int
check_parent_hetero (struct task_struct *task, struct mm_struct *mm) 
{
	struct task_struct *realp = NULL;
	struct task_struct *parent = NULL;
	struct task_struct *group_leader = NULL;
	struct mm_struct *parent_mm = NULL;



	realp  = task->real_parent;
	parent = task->parent;
	group_leader = task->group_leader;
	if(realp) {
		parent_mm = getmm(realp); 
	}/*else if (parent) {
		parent_mm = getmm(parent);
	}else if (group_leader) {
		parent_mm = getmm(group_leader);
	}*/

	if(strcmp(realp->comm, "java")) {
		return 0;
        }

	if(parent_mm && parent_mm->hetero_task == HETERO_PROC) {
		mm->hetero_task = HETERO_PROC;
		return 1;
	}
	return 0;
}


/*
 * Check whether is a hetero process 
 */
int 
check_hetero_proc (struct task_struct *task) 
{
    struct mm_struct *mm = NULL; 
    
    mm = getmm(task);
    if(!mm ) 
	return 0;

    if (mm->hetero_task == HETERO_PROC) {
	return 1;
    }

    /*if (check_parent_hetero(task, mm)) {
	return 1;
    }*/

    if(!strcmp(task->comm, "java")) {
	mm->hetero_task = HETERO_PROC;
	return 1;
    }

    return 0; 	
}
EXPORT_SYMBOL(check_hetero_proc);


int 
check_hetero_page(struct mm_struct *mm, struct page *page) 
{

	int rc = -1;

	if(mm && (mm->hetero_task == HETERO_PROC) && page) {
		if(page->hetero == HETERO_PG_FLAG) {
			rc = 0;
		}
	}
	return rc;
}
EXPORT_SYMBOL(check_hetero_page);


static int 
stop_threads(struct task_struct *task, int force) 
{

#ifdef _ENABLE_HETERO_THREAD
	int idx = 0;

        spin_lock(&kthread_lock);
        for(idx = 0; idx < MAXTHREADS; idx++) {
		/*if(force && THREADS[idx].thrd) {
			kthread_stop(THREADS[idx].thrd);
			THREADS[idx].thrd = NULL;
			thrd_idx--;
		}else if(THREADS[idx].thrd == task) {
			kthread_stop(THREADS[idx].thrd);
			THREADS[idx].thrd = NULL;
			if(thrd_idx > 0)
	                        thrd_idx--;
			break;
		}*/
		if(thrd_idx)
			thrd_idx--;
        }
        spin_unlock(&kthread_lock);
#endif
	return 0;
}


/* 
* Exit function called during process exit 
*/
int 
is_hetero_exit(struct task_struct *task) 
{
    if(task && check_hetero_proc(task)) {
	print_hetero_stats(task);
#ifdef _ENABLE_HETERO_THREAD
	spin_lock(&kthread_lock);
	if(thrd_idx)
		thrd_idx--;
	spin_unlock(&kthread_lock);

#endif
    }
    return 0;
}
EXPORT_SYMBOL(is_hetero_exit);


void 
debug_hetero_obj(void *obj) 
{
#ifdef CONFIG_HETERO_DEBUG
        struct dentry *dentry, *curr_dentry = NULL;
	struct inode *inode = (struct inode *)obj;

	//struct inode *currinode = (struct inode *)current->mm->hetero_obj;
	struct inode *currinode = (struct inode *)current->hetero_obj;
	if(inode && currinode) {

		if(execute_ok(inode))
			return;

		dentry = d_find_any_alias(inode);
		curr_dentry = d_find_any_alias(currinode);
		printk(KERN_ALERT "%s:%d Proc %s Hetero Proc? %d Inode %lu FNAME %s "
		 "current->heterobj_name %s Write access? %d \n",
		__func__,__LINE__,current->comm, current->mm->hetero_task, inode->i_ino, 
		dentry->d_iname, curr_dentry->d_iname, get_write_access(currinode));
	}
#endif
}
EXPORT_SYMBOL(debug_hetero_obj);


int 
is_hetero_cacheobj(void *obj)
{
	if(!enbl_hetero_net)
		return 0;

	return enbl_hetero_net;
}
EXPORT_SYMBOL(is_hetero_cacheobj);


/*
* Checked only for object affinity 
* when CONFIG_HETERO_OBJAFF is enabled
*/
int 
is_hetero_vma(struct vm_area_struct *vma) 
{
#ifdef CONFIG_HETERO_OBJAFF
	if(!enbl_hetero_objaff)
		return 1;
        if(!vma || !vma->vm_file) {
		//printk(KERN_ALERT "%s : %d NOT HETERO \n", __func__,
		//__LINE__);
                return 0;
        }
#endif
	return 1;
}


int 
is_hetero_obj(void *obj) 
{
#ifdef CONFIG_HETERO_OBJAFF
        /*If we do not enable object affinity then we simply 
	return true for all the case*/
	if(!enbl_hetero_objaff)
		return 1;
#endif

	if(obj && current && current->mm && 
		current->hetero_obj && current->hetero_obj == obj){
		//debug_hetero_obj(obj);
		return 1;
	//}else if(obj && current && current->mm && current->mm->hetero_obj) {
	}else if(obj && current && current->hetero_obj) {
		//dump_stack();
       		//debug_hetero_obj(obj);
        }
	return 0;
}
EXPORT_SYMBOL(is_hetero_obj);

/* 
* Functions to test different allocation strategies 
*/
int 
is_hetero_pgcache_set(void)
{
        if(check_hetero_proc(current)) 
	        return enbl_hetero_pgcache;
        return 0;
}
EXPORT_SYMBOL(is_hetero_pgcache_set);


int 
is_hetero_pgcache_readahead_set(void)
{
	if(check_hetero_proc(current))
		return enbl_hetero_pgcache_readahead;
	return 0;
}
EXPORT_SYMBOL(is_hetero_pgcache_readahead_set);


int 
is_hetero_buffer_set(void)
{
        if(check_hetero_proc(current)) 
                return enbl_hetero_buffer;
    return 0;
}
EXPORT_SYMBOL(is_hetero_buffer_set);


/*
* Sets current task with hetero obj
*/
void set_curr_hetero_obj(void *obj) 
{
#ifdef CONFIG_HETERO_OBJAFF
        //current->mm->hetero_obj = obj;
	current->hetero_obj = obj;
#endif
}
EXPORT_SYMBOL(set_curr_hetero_obj);


/*
* Sets page with hetero obj
*/
void 
set_hetero_obj_page(struct page *page, void *obj)                          
{
#ifdef CONFIG_HETERO_OBJAFF
        page->hetero_obj = obj;
#endif
}
EXPORT_SYMBOL(set_hetero_obj_page);


void 
set_fsmap_hetero_obj(void *mapobj)                                        
{

        struct address_space *mapping = NULL;
	struct inode *inode = NULL;
	void *current_obj = current->hetero_obj;

#ifdef CONFIG_HETERO_DEBUG
	struct dentry *res = NULL;
#endif

#ifdef CONFIG_HETERO_OBJAFF
        /*If we do not enable object affinity then we simply 
	return true for all the case*/
	if(!enbl_hetero_objaff)
		return;
#endif

	mapping = (struct address_space *)mapobj;
        mapping->hetero_obj = NULL;
	inode = (struct inode *)mapping->host;

	/*if(execute_ok(inode)) {
		mapping->hetero_obj = NULL;
		return;
	}*/
	if(!inode)
		return;

	if(current_obj && current_obj == (void *)inode)
		return;

        if((is_hetero_buffer_set() || is_hetero_pgcache_set())){

                mapping->hetero_obj = (void *)inode;

                //current->mm->hetero_obj = (void *)inode;
		current->hetero_obj = (void *)inode;

#ifdef CONFIG_HETERO_DEBUG
		if(mapping->host) {
			res = d_find_any_alias(inode);
			printk(KERN_ALERT "%s:%d Proc %s Inode %lu FNAME %s\n",
			 __func__,__LINE__,current->comm, mapping->host->i_ino, 
		         res->d_iname);
		}
#endif
        }
}
EXPORT_SYMBOL(set_fsmap_hetero_obj);


/* 
* Mark the socket to Hetero target object 
*/
void set_sock_hetero_obj(void *socket_obj, void *inode)                                        
{
        struct sock *sock = NULL;
	struct socket *socket = (struct socket *)socket_obj;
	sock = (struct sock *)socket->sk;

	if(!sock) {
		printk(KERN_ALERT "%s:%d SOCK NULL \n", __func__,__LINE__);
		return;
	}

        if((is_hetero_buffer_set() || is_hetero_pgcache_set())){

		sock->hetero_obj = (void *)inode;

		//current->mm->hetero_obj = (void *)inode;
		current->hetero_obj = (void *)inode;

		sock->__sk_common.hetero_obj = (void *)inode;
#ifdef CONFIG_HETERO_DEBUG
		printk(KERN_ALERT "%s:%d Proc %s \n", __func__,__LINE__,
			current->comm);
#endif
	}
}
EXPORT_SYMBOL(set_sock_hetero_obj);


void set_sock_hetero_obj_netdev(void *socket_obj, void *inode)                                        
{
#ifdef CONFIG_HETERO_NET_ENABLE
    struct sock *sock = NULL;
	struct socket *socket = (struct socket *)socket_obj;
	sock = (struct sock *)socket->sk;

	if(!sock) {
		printk(KERN_ALERT "%s:%d SOCK NULL \n", __func__,__LINE__);
		return;
	}

    if((is_hetero_buffer_set() || is_hetero_pgcache_set())){
		sock->hetero_obj = (void *)inode;
		//current->mm->hetero_obj = (void *)inode;
		current->hetero_obj = (void *)inode;
		sock->__sk_common.hetero_obj = (void *)inode;
		if (sock->sk_dst_cache && sock->sk_dst_cache->dev) {
			hetero_dbg("net device is 0x%lx | %s:%d\n", 
				sock->sk_dst_cache->dev, __FUNCTION__, __LINE__);
			if (!sock->sk_dst_cache->dev->hetero_sock)
				sock->sk_dst_cache->dev->hetero_sock = sock;
		}
	}
#endif
}
EXPORT_SYMBOL(set_sock_hetero_obj_netdev);

#ifdef HETERO_COLLECT_LIFETIME
void update_page_life_time(struct page *page, int delpage, int kbuff) {

	if(!delpage) {

		//if(!page->hetero_create_time)
		page->hetero_create_time = jiffies;
		//if(!(page->hetero_create_time.tv_sec + page->hetero_create_time.tv_usec))
		//	do_gettimeofday(&page->hetero_create_time);
	}else {
	
		//do_gettimeofday(&page->hetero_del_time);
		//if(page->hetero_create_time)
			page->hetero_del_time = jiffies;
		//else
		//	return;

		if(kbuff) {

			//g_avg_kbufpage_life += timediff(&page->hetero_create_time, &page->hetero_del_time);
			g_avg_kbufpage_life += (page->hetero_del_time - page->hetero_create_time);
			g_buff_pages_deleted++;

		} else  {
			g_avg_cachepage_life += (page->hetero_del_time - page->hetero_create_time);
			g_cache_pages_deleted++;
			/*if(g_cache_pages_deleted) {
				printk(KERN_ALERT "start %ld, end %ld del_pages %lu life_sum %u avg %ld life_msec %lu\n", 
					page->hetero_create_time, page->hetero_del_time,
					g_cache_pages_deleted, g_avg_cachepage_life, 
					g_avg_cachepage_life/g_cache_pages_deleted, jiffies_to_msecs(g_avg_cachepage_life/g_cache_pages_deleted));
			}*/
		}
		page->hetero_del_time = 0;  //(struct timeval){0};
                page->hetero_create_time = 0; //(struct timeval){0};
	}
}
#endif



/* Update STAT
* TODO: Currently not setting HETERO_PG_FLAG for testing
*/
void 
update_hetero_pgcache(int nodeid, struct page *page, int delpage) 
{
	int correct_node = 0; 
	struct mm_struct *mm = NULL;

	if(!page) 
		return;

	if(page_to_nid(page) == nodeid)
		correct_node = 1;

	if (!current)
		return;

	mm = getmm(current);
	if(!mm)
		return;

#ifdef HETERO_COLLECT_LIFETIME
	page->hetero = HETERO_PG_FLAG;
	update_page_life_time(page, delpage, 0);
#else
	if(page->hetero != HETERO_PG_FLAG)
		return;
#endif

	/*Check if page is in the correct node and 
	we are not deleting and only inserting the page*/
	if(correct_node && !delpage) {
		mm->pgcache_hits_cnt += 1;
		page->hetero = HETERO_PG_FLAG;
		incr_global_stats(&g_cachehits);
	} else if(!correct_node && !delpage) {
		mm->pgcache_miss_cnt += 1;
		page->hetero = 0;
		incr_global_stats(&g_cachemiss);
	}else if(correct_node && (page->hetero == HETERO_PG_FLAG) 
			&& delpage) {
		mm->pgcachedel++;
		incr_global_stats(&g_cachedel);
	}
	/* Either if object affinity is disabled or page node is 
	incorrect, then return */
	if(!correct_node || !enbl_hetero_objaff)
		goto ret_pgcache_stat;

ret_pgcache_stat:
	return;
}
EXPORT_SYMBOL(update_hetero_pgcache);




/* 
* Update STAT 
* TODO: Currently not setting HETERO_PG_FLAG for testing 
*/
void update_hetero_pgbuff_stat(int nodeid, struct page *page, int delpage) 
{
	int correct_node = 0; 
	struct mm_struct *mm = NULL;

	if(!page) 
		return;

	if(page_to_nid(page) == nodeid)
		correct_node = 1;

	mm = getmm(current);
	if(!mm)
		return;

#ifdef HETERO_COLLECT_LIFETIME
	page->hetero = HETERO_PG_FLAG;
	update_page_life_time(page, delpage, 1);
#else
	if(page->hetero != HETERO_PG_FLAG)
		return;
#endif
	//Check if page is in the correct node and 
	//we are not deleting and only inserting the page
	if(correct_node && !delpage) {

		mm->pgbuff_hits_cnt += 1;
		incr_global_stats(&g_buffhits);

		//page->hetero = HETERO_PG_FLAG;
	}else if(!correct_node && !delpage) {

		incr_global_stats(&g_buffmiss);
		mm->pgbuff_miss_cnt += 1;
		page->hetero = 0;
	}else if(correct_node && (page->hetero == HETERO_PG_FLAG) 
			&& delpage) {

#ifdef CONFIG_HETERO_STATS
		mm->pgbuffdel++;
#endif		
	}
	//Either if object affinity is disabled or page node is 
	//incorrect, then return
	if(!correct_node || !enbl_hetero_objaff)
		goto ret_pgbuff_stat;

ret_pgbuff_stat:
	return;
}
EXPORT_SYMBOL(update_hetero_pgbuff_stat);


/* 
* Simple miss increment; called specifically from 
* functions that do not explicity aim to place pages 
* on heterogeneous memory
*/
void update_hetero_pgbuff_stat_miss(void) 
{
        current->mm->pgbuff_miss_cnt += 1;
}
EXPORT_SYMBOL(update_hetero_pgbuff_stat_miss);


/* 
 * Check if the designed node and current page location 
 * match. Responsibility of the requester to pass nodeid
 */
int is_hetero_page(struct page *page, int nodeid){

   if(page_to_nid(page) == nodeid) {
	return 1;
   }
   return 0;
}
EXPORT_SYMBOL(is_hetero_page);


int is_hetero_journ_set(void){

    //if(hetero_pid && current->pid == hetero_pid)
    return enbl_hetero_journal;
    return 0;
}
EXPORT_SYMBOL(is_hetero_journ_set);


int is_hetero_radix_set(void){
    if(check_hetero_proc(current))
    	return enbl_hetero_radix;
    return 0;
}
EXPORT_SYMBOL(is_hetero_radix_set);


int is_hetero_kernel_set(void){
    return enbl_hetero_kernel;
    return 1;
}
EXPORT_SYMBOL(is_hetero_kernel_set);

int get_fastmem_node(void) {
        return hetero_fastmem_node;
}

int get_slowmem_node(void) {
        return NUMA_HETERO_NODE;
}


static int migration_thread_fn(void *arg) {

        unsigned long count = 0;
        struct mm_struct *mm = (struct mm_struct *)arg;
        //struct timeval start, end;

        //do_gettimeofday(&start);
        //migration_thrd_active = 1;
        if(!mm) {
#ifdef _ENABLE_HETERO_THREAD
		thrd_idx--;
#endif
                return 0;
        }
        count = migrate_to_node_hetero(mm, get_fastmem_node(),
                        get_slowmem_node(),MPOL_MF_MOVE_ALL);

#ifdef _ENABLE_HETERO_THREAD
        spin_lock(&kthread_lock);
	if(thrd_idx)
		thrd_idx--;
        spin_unlock(&kthread_lock); 
#endif
        //do_gettimeofday(&end);
        //migrate_time += timediff(&start, &end);
	//stop_threads(current, 0);
	//if(kthread_should_stop()) {
	//	do_exit(0);
	//}
	//spin_lock(&kthread_lock);
	//spin_unlock(&kthread_lock);
	//printk(KERN_ALERT "%s:%d THREAD %d EXITING %d\n", 
	//	__func__, __LINE__, current->pid, thrd_idx);
        return 0;
}

#if 0
static int migration_thread_fn(void *arg) {

	unsigned long count = 0;
	struct mm_struct *mm = (struct mm_struct *)arg;
	struct timeval start, end;

        //do_gettimeofday(&start);
	 migration_thrd_active = 1;

	hetero_force_dbg("%s:%d MIGRATE_THREAD_FUNC \n", __func__, __LINE__);
	while(migration_thrd_active) {

		while(!spinlock) {
			if (kthread_should_stop())
                        	break;
		}
		//migration_thrd_active = 1;
		if(!mm) {
			return 0;
		}	
		count = migrate_to_node_hetero(mm, get_fastmem_node(), 
			get_slowmem_node(),MPOL_MF_MOVE_ALL);
		//migration_thrd_active = 0;
		//do_gettimeofday(&end);
		//migrate_time += timediff(&start, &end);
		spinlock = 0;
	}

	hetero_force_dbg("%s:%d THREAD EXITING \n", __func__, __LINE__);
	return 0;
}
#endif


void 
try_hetero_migration(void *map, gfp_t gfp_mask){

	//int threshold=0;
	unsigned long *target=0;
	unsigned long *cachemiss=0;
        unsigned long *buffmiss=0;

	if(disabl_hetero_migrate) {
		return;
	}

	if(!current->mm || (current->mm->hetero_task != HETERO_PROC))
		return;

	if(!g_cachemiss) {
		return;
	}

	cachemiss = &current->mm->pgcache_miss_cnt;
        buffmiss = &current->mm->pgbuff_miss_cnt;
	target = &current->mm->migrate_attempt;

	if((*cachemiss +  *buffmiss) <  *target) {
		return;
	}else {
		*target = *target + g_migrate_freq;
	}

#ifdef _ENABLE_HETERO_THREAD
	print_hetero_stats(current);
	THREADS[thrd_idx].thrd = kthread_run(migration_thread_fn,
				current->mm, "HETEROTHRD");	

	spin_lock(&kthread_lock);
	thrd_idx++;
	spin_unlock(&kthread_lock);
#else
	print_hetero_stats(current);
	migrate_to_node_hetero(current->mm, get_fastmem_node(),
				get_slowmem_node(), MPOL_MF_MOVE_ALL);
#endif
        return;
}
EXPORT_SYMBOL(try_hetero_migration);
#endif

/* start trace system call */
SYSCALL_DEFINE2(start_trace, int, flag, int, val)
{

#ifdef _ENABLE_HETERO_THREAD
	int idx = 0;
#endif
        /*if(strcmp(current->comm, "java"))
	        return;*/

#ifdef CONFIG_HETERO_ENABLE
    switch(flag) {
	case CLEAR_GLOBALCOUNT:
	    printk("flag set to clear count %d\n", flag);
	    global_flag = CLEAR_GLOBALCOUNT;
	    /*reset hetero allocate flags */
	    enbl_hetero_pgcache = 0;
	    enbl_hetero_buffer = 0; 
	    enbl_hetero_radix = 0;
	    enbl_hetero_journal = 0; 
            enbl_hetero_kernel = 0;
	    enbl_hetero_net = 0;
	    enbl_hetero_pgcache_readahead=0;
	    /* Enable application defined context */
	    enbl_hetero_set_context = 0;
	    enbl_hetero_objaff = 0;	
	    hetero_pid = 0;
	    hetero_kernpg_cnt = 0;
	    hetero_usrpg_cnt = 0;
	    reset_hetero_stats(current);	
	    break;

	case COLLECT_TRACE:
	    printk("flag is set to collect trace %d\n", flag);
	    global_flag = COLLECT_TRACE;
	    return global_flag;
	    break;
	case PRINT_GLOBAL_STATS:
	    printk("flag is set to print stats %d\n", flag);
	    global_flag = PRINT_GLOBAL_STATS;
	    print_global_stats();
	    break;
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
	    //print_hetero_stats(current);
	    print_global_stats();	
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
	case HETERO_SET_FASTMEM_NODE:
	    printk("flag to set FASTMEM node to %d \n", val);
	    hetero_fastmem_node = val;
	    break;
	case HETERO_MIGRATE_FREQ:
	     g_migrate_freq = val;
	     printk("flag to set MIGRATION FREQ to %d \n", g_migrate_freq);
	     break;	
	case HETERO_OBJ_AFF:
#ifdef CONFIG_HETERO_OBJAFF
	    enbl_hetero_objaff = 1;
	    printk("flag enables HETERO_OBJAFF %d \n", enbl_hetero_objaff);
#endif 
	    break;	
	case HETERO_DISABLE_MIGRATE:
	     printk("flag to disable migration %d \n", val);
	     disabl_hetero_migrate = 1;
	     break;	
	case HETERO_MIGRATE_LISTCNT:
	     printk("flag to MIGRATE_LISTCNT %d \n", val);
	     min_migrate_cnt = val;
	     break;	

	/* Set current file context */
	case HETERO_SET_CONTEXT:
	     printk("flag to set HETERO_SET_CONTEXT with fd %d \n", val);
	     enbl_hetero_set_context = 1;
	     break;

	case HETERO_NET:
	     printk("flag to set HETERO_NET with %d \n", val);
	     enbl_hetero_net = 1;
	     break;		

	case HETERO_PGCACHE_READAHEAD:
	     printk("flag to set HETERO_PGCACHE_READAHEAD with %d \n", val);
	     enbl_hetero_pgcache_readahead = 1;	
	     break;	

	default:
#ifdef CONFIG_HETERO_DEBUG
	   hetero_dbgmask = 1;	
#endif
	    hetero_pid = flag;
	    current->mm->hetero_task = HETERO_PROC;
	    printk("hetero_pid set to %d %d procname %s\n", hetero_pid,
		current->pid, current->comm);			
	    break;
    }
#endif

    return 0;
}
