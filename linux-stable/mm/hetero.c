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
#include <asm/atomic.h>
#include <asm/mmu_context.h>
#include <linux/pfn_trace.h>
#include <net/sock.h>
#include <linux/migrate.h>
//#include <sys/time.h>
#include <linux/time64.h>

#include "internal.h"

#define HETERO_HPC

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
#define PRINT_PPROC_PAGESTATS 10

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
#define ENABLE_PVT_LRU 24
#define PRINT_PVT_LRU_STATS 25

//PVT lru accounting for function calls
#define ACC_DOANON 101
#define ACC_LRUCACHEADD 102
#define ACC_ACTIVATEPAGE 103
#define ACC_HANDLE_MM_FAULT 104
#define ACC_HANDLE_PTE_FAULT 105

//#define page_to_virt(page) (char *)pfn_to_virt(page_to_pfn(page))

/* Collect life time of page 
*/
//#define HETERO_COLLECT_LIFETIME

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

#ifdef CONFIG_PVT_LRU
unsigned long nr_global_active_anon_lru = 0;
unsigned long nr_global_active_cache_lru = 0;
unsigned long nr_global_inactive_anon_lru = 0;
unsigned long nr_global_inactive_cache_lru = 0;
unsigned long nr_readahead = 0; //Number of pages readhead

bool start_global_accounting = false;

int accnt_do_anonymous_page = 0;
int accnt_handle_mm_fault = 0;
int accnt_handle_pte_fault = 0;
#endif

//PVT Overheads accounting
//the below struct stores a unique pointer to current &
// the number of active and inactive pages
//
struct overhead_owner{
	struct task_struct *task;
	int nr_active;
	int nr_inactive;
	struct overhead_owner *next;
};


DEFINE_SPINLOCK(stats_lock);


#ifdef HETERO_HPC

#define K(x) ((x) << (PAGE_SHIFT - 10))
#define THRESHOLD 100000
#define FREQCHECK 1000000
//static unsigned int node_checkfreq = 0;
//static unsigned int node_checkfreq_default = 0;

#define MAXPROCS 48

unsigned int max_file_pages[MAXPROCS];
unsigned int max_anon_pages[MAXPROCS];
unsigned int max_shmem_pages[MAXPROCS];

unsigned int max_rss_file_pages[MAXPROCS];
unsigned int max_rss_anon_pages[MAXPROCS];
unsigned int max_rss_shmem_pages[MAXPROCS];

unsigned int max_rss_total[MAXPROCS];
unsigned int max_total[MAXPROCS];

unsigned int init_anon_pages = 0; //Just anon pages
unsigned int init_file_pages = 0;
unsigned int init_other_pages = 0;

unsigned int max_sys_file_pages = 0;
unsigned int max_sys_anon_pages = 0;
unsigned int max_sys_other_pages = 0;


DEFINE_SPINLOCK(hpcstat_lock);


int pidlist[MAXPROCS];
int total_pids = 0;
int min_pidx = -1;
int hpc_stats_init = 0;

void reset_hpc_stats(void) {

	int idx = 0;

	for (idx = 0; idx < MAXPROCS; idx++) 
	{
		pidlist[idx] = -1;

		max_file_pages[idx] = 0;
		max_anon_pages[idx] = 0;
		max_shmem_pages[idx] = 0;

		max_rss_file_pages[idx] = 0;
		max_rss_anon_pages[idx] = 0;
		max_rss_shmem_pages[idx] = 0;

		max_rss_total[idx] = 0;
		max_total[idx] = 0;
	}
	total_pids = 0;
	min_pidx = -1;

	hpc_stats_init = 0;
}


void sys_mem_init(void) 
{
	struct sysinfo i;
	int lru;
	unsigned long pages[NR_LRU_LISTS];
	si_meminfo(&i);
	si_swapinfo(&i);

	si_meminfo(&i);
	si_swapinfo(&i);

	max_sys_file_pages = 0;
	max_sys_anon_pages = 0;
	max_sys_other_pages = 0;

	for (lru = LRU_BASE; lru < NR_LRU_LISTS; lru++)
		pages[lru] = global_node_page_state(NR_LRU_BASE + lru);

	init_anon_pages = pages[LRU_ACTIVE_ANON] + pages[LRU_INACTIVE_ANON];
	max_sys_anon_pages = init_anon_pages;

	init_file_pages = pages[LRU_ACTIVE_FILE] + pages[LRU_INACTIVE_FILE];
	max_sys_file_pages = init_file_pages;

	init_other_pages = pages[LRU_UNEVICTABLE] + global_zone_page_state(NR_MLOCK) 
		+ total_swapcache_pages() + i.bufferram;
	max_sys_other_pages = init_other_pages;
}


void init_hpc_stats(void) 
{
	if(hpc_stats_init)
		return;

	reset_hpc_stats();
	hpc_stats_init = 1;
	sys_mem_init();
}


void sys_mem_interval_diff(void) 
{
	struct sysinfo i;
	int lru;
	unsigned int m_anonpages = 0;
	unsigned int m_filepages = 0;
	unsigned int m_otherpages = 0;
#if 0
	unsigned long committed;
	long cached;
	long available;
#endif
	unsigned long pages[NR_LRU_LISTS];
	si_meminfo(&i);
	si_swapinfo(&i);

	si_meminfo(&i);
	si_swapinfo(&i);

	for (lru = LRU_BASE; lru < NR_LRU_LISTS; lru++)
		pages[lru] = global_node_page_state(NR_LRU_BASE + lru);

	m_anonpages = pages[LRU_ACTIVE_ANON] + pages[LRU_INACTIVE_ANON];
	m_filepages = pages[LRU_ACTIVE_FILE] + pages[LRU_INACTIVE_FILE];
	m_otherpages = pages[LRU_UNEVICTABLE] + global_zone_page_state(NR_MLOCK) + 
		total_swapcache_pages() + i.bufferram;

	/*Calculate the difference */ 
	if(m_anonpages > max_sys_anon_pages)
		max_sys_anon_pages = m_anonpages - init_anon_pages;

	if(m_filepages > max_sys_file_pages)
		max_sys_file_pages = m_filepages - init_file_pages;

	if(m_otherpages > max_sys_other_pages)
		max_sys_other_pages = m_otherpages - init_other_pages;


#if 0
	committed = percpu_counter_read_positive(&vm_committed_as);

	cached = global_node_page_state(NR_FILE_PAGES) -
		total_swapcache_pages() - i.bufferram;
	if (cached < 0)
		cached = 0;

	available = si_mem_available();

	show_val_kb(m, "MemTotal:       ", i.totalram);
	show_val_kb(m, "MemFree:        ", i.freeram);
	show_val_kb(m, "MemAvailable:   ", available);
	show_val_kb(m, "Buffers:        ", i.bufferram);
	show_val_kb(m, "Cached:         ", cached);
	show_val_kb(m, "SwapCached:     ", total_swapcache_pages());
	show_val_kb(m, "Active:         ", pages[LRU_ACTIVE_ANON] +
			pages[LRU_ACTIVE_FILE]);
	show_val_kb(m, "Inactive:       ", pages[LRU_INACTIVE_ANON] +
			pages[LRU_INACTIVE_FILE]);
	show_val_kb(m, "Active(anon):   ", pages[LRU_ACTIVE_ANON]);
	show_val_kb(m, "Inactive(anon): ", pages[LRU_INACTIVE_ANON]);
	show_val_kb(m, "Active(file):   ", pages[LRU_ACTIVE_FILE]);
	show_val_kb(m, "Inactive(file): ", pages[LRU_INACTIVE_FILE]);
	show_val_kb(m, "Unevictable:    ", pages[LRU_UNEVICTABLE]);
	show_val_kb(m, "Mlocked:        ", global_zone_page_state(NR_MLOCK));
#endif
}



unsigned long check_node_memsize(struct mm_struct *mm) 
{
	unsigned int m_filepages = 0;
	unsigned int m_anonpages = 0;
	unsigned int m_shmempages = 0;
	unsigned int m_totalpages = 0;


	unsigned int m_rss_filepages = 0;
	unsigned int m_rss_anonpages = 0;
	unsigned int m_rss_shmempages = 0;
	unsigned int m_rss_swapents = 0;

	unsigned int m_rss_totalpages = 0;
	unsigned int m_rss_totalanon = 0;
	unsigned int m_rss_totalfile = 0;
	unsigned int m_rss_totalother = 0;

	int PID = -1;
	int CURR_PIDX = -1;
	int iter = 0;

	//initialize if not initialized
	init_hpc_stats();

	PID = current->pid;
	CURR_PIDX = PID % MAXPROCS;

	if(!mm) 
		return 0;

	spin_lock(&hpcstat_lock);

	if(pidlist[CURR_PIDX] == -1) {
		pidlist[CURR_PIDX] = PID;
		total_pids++;
	}

	spin_unlock(&hpcstat_lock);

	//Get the total stats for this process (CURR_PIDX)
	m_filepages = get_mm_counter(mm, MM_FILEPAGES);
	m_anonpages = get_mm_counter(mm, MM_ANONPAGES);
	m_shmempages = get_mm_counter(mm, MM_SHMEMPAGES);
	m_totalpages = m_filepages + m_anonpages + m_shmempages;

	spin_lock(&hpcstat_lock);

	if(max_file_pages[CURR_PIDX] < m_filepages)
		max_file_pages[CURR_PIDX] = m_filepages;

	if(max_anon_pages[CURR_PIDX] < m_anonpages)
		max_anon_pages[CURR_PIDX] = m_anonpages;

	if(max_shmem_pages[CURR_PIDX] < m_shmempages)
		max_shmem_pages[CURR_PIDX] = m_shmempages;

	if(max_total[CURR_PIDX]  < m_totalpages)
		max_total[CURR_PIDX] = m_totalpages;

	spin_unlock(&hpcstat_lock);

	m_rss_filepages = atomic_long_read(&mm->rss_stat.count[MM_FILEPAGES]);
	m_rss_anonpages = atomic_long_read(&mm->rss_stat.count[MM_ANONPAGES]);
	m_rss_swapents = atomic_long_read(&mm->rss_stat.count[MM_SWAPENTS]);
	m_rss_shmempages = atomic_long_read(&mm->rss_stat.count[MM_SHMEMPAGES]);
	m_rss_totalpages = m_rss_filepages + m_rss_anonpages + 
		m_rss_swapents + m_rss_shmempages;

	spin_lock(&hpcstat_lock);

	if(max_rss_file_pages[CURR_PIDX] < m_rss_filepages)
		max_rss_file_pages[CURR_PIDX] = m_rss_filepages;

	if(max_rss_anon_pages[CURR_PIDX] < m_rss_anonpages)
		max_rss_anon_pages[CURR_PIDX] = m_rss_anonpages;

	if(max_rss_shmem_pages[CURR_PIDX] < m_rss_shmempages)
		max_rss_shmem_pages[CURR_PIDX] = m_rss_shmempages;

	if(max_rss_total[CURR_PIDX]  < m_rss_totalpages)
		max_rss_total[CURR_PIDX] = m_rss_totalpages;

	//Find the process in out list with minimum PID
	if(min_pidx > CURR_PIDX || (min_pidx == -1))
		min_pidx = CURR_PIDX;

	spin_unlock(&hpcstat_lock);

	//Only print for smallest PID in our list
	if(CURR_PIDX == min_pidx) {

		m_rss_totalpages = 0;
		m_rss_totalanon = 0;
		m_rss_totalfile = 0;
		m_rss_totalother = 0;

		printk(KERN_ALERT "\n\n");

		for (iter =0; iter < MAXPROCS; iter++) 
		{
			if(pidlist[iter] != -1) {
				printk(KERN_ALERT "PID %d "
						"MAX-F %u, MAX-A %u, MAX-SH %u MAX-TOT %u " 
						"MAX-RSS-F %u, MAX-RSS-A %u, MAX-RSS-SH %u  OVERALL MAX-RSS-TOT %u" 
						"\n", 
						pidlist[iter], 
						max_file_pages[iter],  max_anon_pages[iter], max_shmem_pages[iter], 
						max_total[iter], max_rss_file_pages[iter], max_rss_anon_pages[iter], 
						max_rss_shmem_pages[iter], max_rss_total[iter]);

				m_rss_totalpages += max_rss_total[iter];
				m_rss_totalanon += max_rss_anon_pages[iter];
				m_rss_totalfile += max_rss_file_pages[iter];
				m_rss_totalother += max_rss_shmem_pages[iter];
			}
		}

		sys_mem_interval_diff();


		printk(KERN_ALERT "AppUse(pages): Total:%u = Anon:%u + File:%u + Other:%u\n",
				m_rss_totalpages, m_rss_totalanon, m_rss_totalfile,
				m_rss_totalother);

		printk(KERN_ALERT "SystemUseAVG: Total: %u", max_sys_anon_pages + max_sys_file_pages);

		//unsigned int Filepages = max_sys_pages - max_sys;
		printk(KERN_ALERT "SystemUseMAX: Total(SYS+SWAPCACHE+BUFF): %u"
				"= Anon(SYS):%u + File:%u + Other:%u \n",
				max_sys_file_pages + max_sys_anon_pages + max_sys_other_pages, 
				max_sys_anon_pages,  max_sys_file_pages, max_sys_other_pages);
	}
	return 0;

#if 0	
	printk(KERN_ALERT "-----TOT: MAX PAGES(ALL PIDS): %u, OVERALL SYS %u, "
			"SYS+SWAPCACHE %u, SYS+SWAPCACHE+BUFF %u -----\n", 
			m_rss_totalpages, max_sys_pages, max_sys_pages_swapcache, 
			max_sys_pages_swapcache_buffers);
	struct sysinfo i;
	int nid = get_fastmem_node();
	unsigned long memsize = 0;

	si_meminfo_node(&i, nid);
	memsize = i.freeram;
	return memsize;
#endif
}



#endif




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

void print_global_stats(struct task_struct *task) {

	printk("PID %d: cache-hits %lu cache-miss %lu " 
			"buff-hits %lu buff-miss %lu " 
			"migrated %lu cache-del %lu " 
			"buff-del %lu \n", 
			task->pid,
			g_cachehits, g_cachemiss, g_buffhits, 
			g_buffmiss, g_migrated, g_cachedel,
			g_buffdel);

#ifdef CONFIG_HETERO_STATS
	printk("ANALYSIS STAT PID %d, CACHE-PAGES %lu, BUFF-PAGES %lu, APP-PAGES %lu \n",
			current->pid, g_tot_cache_pages, g_tot_buff_pages, g_tot_app_pages);
#endif

#ifdef HETERO_COLLECT_LIFETIME
	//buffpgs = mm->pgbuffdel;
	//cachepgs = mm->pgcachedel;
	if(g_avg_cachepage_life && g_avg_kbufpage_life && g_buff_pages_deleted && g_cache_pages_deleted) {
		printk("ANALYSIS LIFESTAT PID %d, CACHE-PAGE-LIFE %lu, BUFF-PAGE-LIFE %lu CACHE_PAGES_ALLOC_DELETE %lu " 
				" BUFF_PAGES_ALLOC_DELETE %lu g_avg_cachepage_life %lu, g_avg_kbufpage_life %lu \n",
				current->pid, jiffies_to_msecs(g_avg_cachepage_life/g_cache_pages_deleted), jiffies_to_msecs(g_avg_kbufpage_life/g_buff_pages_deleted), 
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
	struct mm_struct *mm = NULL;

	mm = getmm(task);
	if(!mm)
		return;

	//check_node_memsize(mm); //THIS HAS BEEN REMOVED TEMP FIXME
	
	print_ownership_stats();
	return;

#ifdef CONFIG_HETERO_STATS
	printk(KERN_ALERT "PID %d Proc-name %s " 
			"page cache %lu " 
			"kernel buffs %lu " 
			"app pages %lu \n",
			task->pid, task->comm, 
			//mm->pgcache_hits_cnt + mm->pgcache_miss_cnt, 
			//mm->pgbuff_hits_cnt + mm->pgbuff_miss_cnt, 
			mm->pgcache_hits_cnt, 
			mm->pgbuff_hits_cnt, 
			g_tot_app_pages
	      );

	printk(KERN_ALERT "ATOMICs PID %d Proc-name %s "
			"FilePages %ld "
			"AnonPages %ld "
			"SwapEntries %ld "
			"SharedPages %ld \n",
			task->pid, task->comm,
			atomic_long_read(&mm->rss_stat.count[MM_FILEPAGES]),
			atomic_long_read(&mm->rss_stat.count[MM_ANONPAGES]),
			atomic_long_read(&mm->rss_stat.count[MM_SWAPENTS]),
			atomic_long_read(&mm->rss_stat.count[MM_SHMEMPAGES])
	      );

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
		//print_hetero_stats(task);
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




#if 0
if(!node_checkfreq) {
	if(K(i.freeram) < THRESHOLD) {
		node_checkfreq = FREQCHECK;
		printk(KERN_ALERT "%s : %d  \n", __func__, __LINE__);
		printk(KERN_ALERT "%s : %d Node: %d, Free pages %8lu kB  \n", 
				__func__, __LINE__, nid,  K(i.freeram));
		memsize = K(i.freeram);
	}
	node_checkfreq = FREQCHECK;
}else {
	node_checkfreq--;
}
#endif



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


	mm->pgcache_hits_cnt++;

#if 0
	//check_node_memsize();
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
		//printk(KERN_ALERT "Page hits %d Node free mem %8lu kB\n", 
		//			page_to_nid(page), check_node_memsize());
		mm->pgcache_hits_cnt += 1;
		page->hetero = HETERO_PG_FLAG;
		incr_global_stats(&g_cachehits);
	} else if(!correct_node && !delpage) {
		printk(KERN_ALERT "Page miss %d Node free mem %8lu kB\n", 
				page_to_nid(page), check_node_memsize());
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
#endif

}
EXPORT_SYMBOL(update_hetero_pgcache);


/*
 * adds to global readahead page counter
 * Only for enabled pids
 */
void add_global_readahead(int pages){
    if(start_global_accounting && current->enable_pvt_lru && pages){
        nr_readahead += pages;
    }
}
EXPORT_SYMBOL(add_global_readahead);


/*
 *The next set of functions take care of a Pvt LRU per process.
 * pvt_* is the function fingerprint
 * the pages are stored in an RB tree
 */
void pvt_active_lru_insert(struct page *page)
{
	if(start_global_accounting)
	{
		if(page_is_file_cache(page))
		{
			current->nr_owned_pages[3] += 1;
			nr_global_active_cache_lru += 1;
		}
		else
		{
			current->nr_owned_pages[1] += 1;
			nr_global_active_anon_lru +=1;
		}

	}

	if(!current->mm)
		return;

	if(current->enable_pvt_lru)
	{
#ifdef CONFIG_PVT_LRU_DEBUG
		printk("%s pid=%d pvt_active_lru_insert addr=%lu\n", 
				current->comm, current->pid, page_to_virt(page));
#endif
		//pvt_lru_rb_remove(&current->mm->inactive_rbroot, page);
		pvt_lru_rb_insert(&current->mm->active_rbroot, page);

		if(page_is_file_cache(page))
		{
			current->mm->nr_lru[3] += 1;
			if(current->mm->nr_max_lru[3] < current->mm->nr_lru[3])
				current->mm->nr_max_lru[3] = current->mm->nr_lru[3];
		}
		else
		{
			current->mm->nr_lru[1] += 1;
			if(current->mm->nr_max_lru[1] < current->mm->nr_lru[1])
				current->mm->nr_max_lru[1] = current->mm->nr_lru[1];
		}
	}
}
EXPORT_SYMBOL(pvt_active_lru_insert);


void pvt_inactive_lru_insert(struct page *page)
{

	if(start_global_accounting)
	{
		if(page_is_file_cache(page))
		{
			current->nr_owned_pages[2] += 1;
			nr_global_inactive_cache_lru += 1;
		}
		else
		{
			current->nr_owned_pages[0] += 1;
			nr_global_inactive_anon_lru +=1;
		}
	}

	if(!current->mm) //Dont do it for kernel procs
		return;

	if(current->enable_pvt_lru)
	{
#ifdef CONFIG_PVT_LRU_DEBUG
		printk("%s pid=%d pvt_inactive_lru_insert addr=%lu\n", 
				current->comm, current->pid, page_to_virt(page));
#endif
		pvt_lru_rb_remove(&current->mm->active_rbroot, page);
		if(pvt_lru_rb_insert(&current->mm->inactive_rbroot, page))
		{
			if(page_is_file_cache(page))
			{
				current->mm->nr_lru[2] += 1;
				if(current->mm->nr_max_lru[2] < current->mm->nr_lru[2])
					current->mm->nr_max_lru[2] = current->mm->nr_lru[2];
			}
			else
			{
				current->mm->nr_lru[0] += 1;
				if(current->mm->nr_max_lru[0] < current->mm->nr_lru[0])
					current->mm->nr_max_lru[0] = current->mm->nr_lru[0];
			}
		}
	}
}
EXPORT_SYMBOL(pvt_inactive_lru_insert);


void pvt_active_lru_remove(struct page *page)
{
	if(start_global_accounting)
	{
		if(page_is_file_cache(page))
		{
			current->nr_owned_pages[3] -= 1;
		}
		else
		{
			current->nr_owned_pages[1] -= 1;
		}
	}

	if(!current->mm)
		return;

	if(current->enable_pvt_lru)
	{
#ifdef CONFIG_PVT_LRU_DEBUG
		printk("%s pid=%d pvt_active_lru_remove addr=%lu\n", 
				current->comm, current->pid, page_to_virt(page));
#endif
		pvt_lru_rb_remove(&current->mm->active_rbroot, page);
		if(page_is_file_cache(page))
			current->mm->nr_lru[3] -= 1;
		else
			current->mm->nr_lru[1] -= 1;

	}
}
EXPORT_SYMBOL(pvt_active_lru_remove);


/*
 * TODO: Not thread safe
 */
void pvt_inactive_lru_remove(struct page *page)
{
	if(start_global_accounting)
	{
		if(page_is_file_cache(page))
		{
			current->nr_owned_pages[2] -= 1;
		}
		else
		{
			current->nr_owned_pages[0] -= 1;
		}
	}

	if(!current->mm)
		return;

	if(current->enable_pvt_lru)
	{
#ifdef CONFIG_PVT_LRU_DEBUG
		printk("%s pid=%d pvt_inactive_lru_remove addr=%lu\n", 
				current->comm, current->pid, page_to_virt(page));
#endif
		pvt_lru_rb_remove(&current->mm->inactive_rbroot, page);
		if(page_is_file_cache(page))
		{
			current->mm->nr_lru[2] -= 1;
		}
		else
		{
			current->mm->nr_lru[0] -= 1;
		}
	}
}
EXPORT_SYMBOL(pvt_inactive_lru_remove);


/* This function is just a page accounting function
 * Flag is an identified for the function
 * nr is the number of pages to be added
 */
void pvt_lru_accnt_nr(int flag, int nr)
{
	switch(flag){
		case ACC_DOANON:
			accnt_do_anonymous_page += nr;
			break;
		case ACC_HANDLE_MM_FAULT:
			accnt_handle_mm_fault += nr;
			break;
		case ACC_HANDLE_PTE_FAULT:
			accnt_handle_pte_fault += nr;
			break;
		default:
			return;
	}
}
EXPORT_SYMBOL(pvt_lru_accnt_nr);


bool pvt_lru_rb_insert(struct rb_root *root, struct page *page)
{
	struct pvt_lru_rbnode *data = kmalloc(sizeof(struct pvt_lru_rbnode), GFP_KERNEL);

	data->page = page;
	struct rb_node **link = &(root->rb_node), *parent=NULL;
	struct pvt_lru_rbnode *this_node = NULL;
	while(*link)
	{
		parent = *link;
		this_node = rb_entry(parent, struct pvt_lru_rbnode, lru_node);

		if(page_to_virt(this_node->page) > page_to_virt(page))
		{
			link = &(*link)->rb_left;
		}
		else if (page_to_virt(this_node->page) == page_to_virt(page)) 
		{
#ifdef CONFIG_PVT_LRU_DEBUG
			printk(KERN_ALERT "!!Duplicate Page in pvt LRU PID:%d at add:%lu\n"
					, current->pid, page_to_virt(page));
#endif
			return false;
		}
		else
			link = &(*link)->rb_right;
	}
	rb_link_node(&data->lru_node, parent, link);
	rb_insert_color(&data->lru_node, root);
	return true;
}


/*
 * Searches and returns a page from pvt rb tree
 */
struct pvt_lru_rbnode *pvt_lru_rb_search(struct rb_root *root, struct page *page)
{
	if(root == NULL)
	{
		printk("pid:%d, comm:%s, pvt_lru_rb_search, root==NULL\n",
				current->pid, current->comm);
		return NULL;
	}
	struct rb_node *node = root->rb_node;
	struct pvt_lru_rbnode *this_node = NULL;
	while(node){
		this_node = rb_entry(node, struct pvt_lru_rbnode, lru_node);
		if(page_to_virt(this_node->page) > page_to_virt(page))
		{
			node = node->rb_left;
		}
		else if(page_to_virt(this_node->page) < page_to_virt(page))
		{
			node = node->rb_right;
		}
		else /*==*/
		{
			return this_node;
		}
	}
	return NULL;
}


void pvt_lru_rb_remove(struct rb_root *root, struct page *page)
{
	struct pvt_lru_rbnode *node = pvt_lru_rb_search(root, page);
	if(node == NULL)
	{
		return;
	}
	rb_erase(&node->lru_node, root);
}


/*This function prints all the task > 0 pages
*/
void print_ownership_stats(void)
{
	struct task_struct *p, *proc;

	int nr_procs_covered = 0;

	int all_nr_owned_pages[4];
	int all_nr_unmapped_pages[1];
	all_nr_owned_pages[0] = 0;
	all_nr_owned_pages[1] = 0;
	all_nr_owned_pages[2] = 0;
	all_nr_owned_pages[3] = 0;
	all_nr_unmapped_pages[0] = 0;
	all_nr_unmapped_pages[1] = 0;

	if(start_global_accounting)
	{
		//for_each_process_thread(p, proc)
		for_each_process(proc)
		{
			nr_procs_covered += 1;
			if(proc->enable_pvt_lru) //User program
			{
				if(proc->nr_owned_pages[0] > 0 || proc->nr_owned_pages[1] > 0
					|| proc->nr_owned_pages[2] > 0 || proc->nr_owned_pages[3] > 0
					|| proc->nr_unmapped_pages[0] > 0 || proc->nr_unmapped_pages[1] > 0)

				{
					all_nr_owned_pages[0] += proc->nr_owned_pages[0];
					all_nr_owned_pages[1] += proc->nr_owned_pages[1];
					all_nr_owned_pages[2] += proc->nr_owned_pages[2];
					all_nr_owned_pages[3] += proc->nr_owned_pages[3];
					all_nr_unmapped_pages[0] += proc->nr_unmapped_pages[0];
					all_nr_unmapped_pages[1] += proc->nr_unmapped_pages[2];
				}
			}
			else //Other kernel procs
			{
				if(proc->nr_owned_pages[0] > 0 || proc->nr_owned_pages[1] > 0
					|| proc->nr_owned_pages[2] > 0 || proc->nr_owned_pages[3] > 0
					|| proc->nr_unmapped_pages[0] > 0 || proc->nr_unmapped_pages[1] > 0)
				{
					printk(KERN_ALERT "PID: %d-%s OWNED: INACTIVE_Anon: %d, ACTIVE_Anon: %d "
						"INACTIVE_Cache: %d, ACTIVE_Cache: %d "
						"DEL_Anon: %d, DEL_Cache: %d\n",
						proc->pid,
						proc->comm,
						proc->nr_owned_pages[0],
						proc->nr_owned_pages[1],
						proc->nr_owned_pages[2],
						proc->nr_owned_pages[3],
						proc->nr_unmapped_pages[0],
						proc->nr_unmapped_pages[1]);
				}
			}
		}
		printk(KERN_ALERT "ALL_USER_OWNED: INACTIVE_Anon: %d, ACTIVE_Anon: %d "
				"INACTIVE_Cache: %d, ACTIVE_Cache: %d "
				"DEL_Anon: %d, DEL_Cache: %d\n",
				all_nr_owned_pages[0],
				all_nr_owned_pages[1],
				all_nr_owned_pages[2],
				all_nr_owned_pages[3],
				all_nr_unmapped_pages[0],
				all_nr_unmapped_pages[1]);
#ifdef CONFIG_PVT_LRU_DEBUG
		printk(KERN_ALERT "Number of Procs covered %d\n", nr_procs_covered);
#endif
	}

	return;
}
EXPORT_SYMBOL(print_ownership_stats);

void reset_ownership_stats(void)
{
	struct task_struct *p, *proc;

	for_each_process_thread(p, proc)
	{
		proc->nr_owned_pages[0] = 0;
		proc->nr_owned_pages[1] = 0;
		proc->nr_owned_pages[2] = 0;
		proc->nr_owned_pages[3] = 0;
		proc->nr_unmapped_pages[0] = 0;
		proc->nr_unmapped_pages[1] = 0;
	}
}


void reset_pvt_lru_counters(void)
{
	current->mm->nr_lru[0] = 0;
	current->mm->nr_lru[1] = 0;
	current->mm->nr_lru[2] = 0;
	current->mm->nr_lru[0] = 0;
	current->mm->nr_max_lru[0] = 0;
	current->mm->nr_max_lru[1] = 0;
	current->mm->nr_max_lru[2] = 0;
	current->mm->nr_max_lru[3] = 0;
	nr_global_active_anon_lru = 0;
	nr_global_active_cache_lru = 0;
	nr_global_inactive_anon_lru = 0;
	nr_global_inactive_cache_lru = 0;

     nr_readahead = 0;
}


//Not all unmapped pages goto LRU immediately
//so we need another probe to get this info
//type = 0 -> anon, type = 1 -> cache
void pvt_unmapped_page_accnt(int nr_pages, int type)
{
	if(start_global_accounting)
	{
		current->nr_unmapped_pages[type] += nr_pages;
	}
}
EXPORT_SYMBOL(pvt_unmapped_page_accnt);

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

	mm->pgbuff_hits_cnt++;

#if 0	

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
#endif
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
	//print_hetero_stats(current);
	THREADS[thrd_idx].thrd = kthread_run(migration_thread_fn,
			current->mm, "HETEROTHRD");	

	spin_lock(&kthread_lock);
	thrd_idx++;
	spin_unlock(&kthread_lock);
#else
	//print_hetero_stats(current);
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
#ifdef HETERO_HPC
			reset_hpc_stats();
#endif
			break;

		case COLLECT_TRACE:
			printk("flag is set to collect trace %d\n", flag);
			global_flag = COLLECT_TRACE;
			return global_flag;
			break;
		case PRINT_GLOBAL_STATS:
			printk("flag is set to print stats %d\n", flag);
			global_flag = PRINT_GLOBAL_STATS;
			print_global_stats(current);
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
		case PRINT_PPROC_PAGESTATS:
			//printk("flag is set to print hetero allocate stat %d \n", flag);
			global_flag = PRINT_PPROC_PAGESTATS;
			print_hetero_stats(current);
			//print_global_stats(current);	
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

#ifdef CONFIG_PVT_LRU
		case ENABLE_PVT_LRU:
			printk("flag to set enable_pvt_lru with\n");
			current->enable_pvt_lru = true;
			current->mm->active_rbroot = RB_ROOT;
			current->mm->inactive_rbroot = RB_ROOT;

			reset_pvt_lru_counters();
			reset_ownership_stats();

			accnt_do_anonymous_page = 0;
			accnt_handle_mm_fault = 0;
			accnt_handle_pte_fault = 0;

			start_global_accounting = true;
			printk("Pvt LRU initialized for %d\n", current->pid);
			break;

		case PRINT_PVT_LRU_STATS:
			if(current->enable_pvt_lru)
			{
				printk(KERN_ALERT "PVT_LRU: PID:%d; max_inactive_anon:%d, max_active_anon:%d "
						"max_inactive_cache:%d, max_active_cache:%d pages\n",
						current->pid, current->mm->nr_max_lru[0], 
						current->mm->nr_max_lru[1], current->mm->nr_max_lru[2],
						current->mm->nr_max_lru[3]);

				printk(KERN_ALERT "GLOBAL_LRU: max_inactive_anon:%lu, max_active_anon:%lu "
						"max_inactive_cache:%lu, max_active_cache:%lu pages\n",
						nr_global_inactive_anon_lru, nr_global_active_anon_lru,
						nr_global_inactive_cache_lru, nr_global_active_cache_lru);

				printk(KERN_ALERT "FunctionAcc: do_anon: %d, handle_pte: %d, handle_mm: %d\n",
						accnt_do_anonymous_page, 
						accnt_handle_pte_fault,
						accnt_handle_mm_fault);
			}
			else
				printk("pid:%d, Did not enable_pvt_lru\n", current->pid);

			start_global_accounting = false;

			nr_global_active_anon_lru = 0;
			nr_global_inactive_anon_lru = 0;
			nr_global_active_cache_lru = 0;
			nr_global_inactive_cache_lru = 0;

			accnt_do_anonymous_page = 0;
			accnt_handle_mm_fault = 0;
			accnt_handle_pte_fault = 0;
			reset_ownership_stats();
			break;
#endif

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
