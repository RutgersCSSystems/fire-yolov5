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
#define HETERO_SET_FASTMEM_NODE 16
#define HETERO_MIGRATE_FREQ 100

/* Hetero Stats information*/
int global_flag = 0;
int radix_cnt = 0;
int hetero_dbgmask = 0;

int enbl_hetero_pgcache=0;
int enbl_hetero_buffer=0;
int enbl_hetero_journal=0;
int enbl_hetero_radix=0;
int enbl_hetero_kernel=0;
int hetero_fastmem_node=0;
int enbl_hetero_objaff=0;

int hetero_pid = 0;
int hetero_usrpg_cnt = 0;
int hetero_kernpg_cnt = 0;
char procname[TASK_COMM_LEN];

void print_hetero_stats(struct task_struct *task) {
       printk("Curr %d Currname %s HeteroProcname %s " 
		"page_cache_hits %lu page_cache_miss %lu " 
	      	"buff_page_hits %lu buff_page_miss %lu " 
		"pages migrated %lu \n ", 
	  	current->pid, current->comm, procname, 
              	task->mm->pgcache_hits_cnt, task->mm->pgcache_miss_cnt, 
	      	task->mm->pgbuff_hits_cnt, task->mm->pgbuff_miss_cnt, 
		task->mm->pages_migrated);
}
EXPORT_SYMBOL(print_hetero_stats);

void reset_hetero_stats(struct task_struct *task) {
        task->mm->pgcache_hits_cnt = 0;
	task->mm->pgcache_miss_cnt = 0;
	task->mm->pgbuff_miss_cnt = 0;
	task->mm->pgbuff_hits_cnt = 0;
	/* Represents pages migrated and 
	* frequency of page migration attempts
	*/
	task->mm->pages_migrated = 0;
	task->mm->migrate_attempt = 0;
}
EXPORT_SYMBOL(reset_hetero_stats);


inline int check_hetero_proc (struct task_struct *task) 
{
#ifdef CONFIG_HETERO_ENABLE
    //f(current->pid == hetero_pid && hetero_pid){
    if (task && task->mm && (task->mm->hetero_task == HETERO_PROC)){
	return 1;
    }
#endif
    return 0; 	
}

inline int check_hetero_page(struct mm_struct *mm, struct page *page) {

	int rc = -1;


	if(mm && (mm->hetero_task == HETERO_PROC) && page) {
		//printk(KERN_ALERT "%s:%d \n", __func__, __LINE__);
		if(page->hetero == HETERO_PG_FLAG) {
			rc = 0;
		}
	}
	return rc;
}
EXPORT_SYMBOL(check_hetero_page);


/* Exit function called during process exit */
int is_hetero_exit(struct task_struct *task) 
{
    if(check_hetero_proc(task)) {
	/*printk("hetero_pid %d Curr %d Currname %s HeteroProcname %s " 
		"user pages %d kern pages %d\n",
		hetero_pid, current->pid, current->comm, procname,  
	        hetero_usrpg_cnt, hetero_kernpg_cnt);*/
	print_hetero_stats(task);
        //reset_hetero_stats(task);
    }
    return 0;
}
EXPORT_SYMBOL(is_hetero_exit);


void debug_hetero_obj(void *obj) {

#ifdef CONFIG_HETERO_DEBUG
        struct dentry *dentry, *curr_dentry = NULL;
	struct inode *inode = (struct inode *)obj;
	struct inode *currinode = (struct inode *)current->mm->hetero_obj;
	if(inode && currinode) {
		dentry = d_find_any_alias(inode);
		curr_dentry = d_find_any_alias(currinode);
		if(current->mm->hetero_obj != obj) {
			printk(KERN_ALERT "%s:%d Proc %s Inode %lu FNAME %s "
			 "current->heterobj_name %s Write access? %d \n",
		 	__func__,__LINE__,current->comm, inode->i_ino, 
			dentry->d_iname, curr_dentry->d_iname, get_write_access(currinode));
		}
	}
#endif
}
EXPORT_SYMBOL(debug_hetero_obj);

inline int is_hetero_obj(void *obj) 
{
	if(enbl_hetero_objaff)
		return 1;

#ifdef CONFIG_HETERO_ENABLE
	if(obj && current && current->mm && 
		current->mm->hetero_obj && current->mm->hetero_obj == obj){
		return 1;
	}
#endif
	return 0;
}
EXPORT_SYMBOL(is_hetero_obj);

/* Functions to test different allocation strategies */
int is_hetero_pgcache_set(void)
{
        if(check_hetero_proc(current)) 
	        return enbl_hetero_pgcache;
        return 0;
}
EXPORT_SYMBOL(is_hetero_pgcache_set);

int is_hetero_buffer_set(void)
{
        if(check_hetero_proc(current)) 
                return enbl_hetero_buffer;
    return 0;
}
EXPORT_SYMBOL(is_hetero_buffer_set);



/*Sets current task with hetero obj*/
void set_curr_hetero_obj(void *obj) 
{
#ifdef CONFIG_HETERO_ENABLE
        current->mm->hetero_obj = obj;
#endif
}
EXPORT_SYMBOL(set_curr_hetero_obj);

/*Sets page with hetero obj*/
void set_hetero_obj_page(struct page *page, void *obj)                          
{
#ifdef CONFIG_HETERO_ENABLE
        page->hetero_obj = obj;
#endif
}
EXPORT_SYMBOL(set_hetero_obj_page);


void set_fsmap_hetero_obj(void *mapobj)                                        
{
#ifdef CONFIG_HETERO_ENABLE
        struct address_space *mapping = NULL;
	struct inode *inode = NULL;
	mapping = (struct address_space *)mapobj;
        mapping->hetero_obj = NULL;
	inode = (struct inode *)mapping->host;

        if((is_hetero_buffer_set() || is_hetero_pgcache_set())){
		struct dentry *res;
                mapping->hetero_obj = (void *)inode;
                current->mm->hetero_obj = (void *)inode;
#ifdef CONFIG_HETERO_DEBUG
		if(mapping->host) {
			res = d_find_any_alias(inode);
			printk(KERN_ALERT "%s:%d Proc %s Inode %lu FNAME %s\n",
			 __func__,__LINE__,current->comm, mapping->host->i_ino, 
		         res->d_iname);
		}
#endif
        }
#endif
}
EXPORT_SYMBOL(set_fsmap_hetero_obj);

/* Mark the socket to Hetero target object */
void set_sock_hetero_obj(void *socket_obj, void *inode)                                        
{
#ifdef CONFIG_HETERO_ENABLE
        struct sock *sock = NULL;
	struct socket *socket = (struct socket *)socket_obj;
	sock = (struct sock *)socket->sk;

	if(!sock) {
		printk(KERN_ALERT "%s:%d SOCK NULL \n", __func__,__LINE__);
		return;
	}

        if((is_hetero_buffer_set() || is_hetero_pgcache_set())){

		sock->hetero_obj = (void *)inode;
		current->mm->hetero_obj = (void *)inode;
		sock->__sk_common.hetero_obj = (void *)inode;
#ifdef CONFIG_HETERO_DEBUG
		printk(KERN_ALERT "%s:%d Proc %s \n", __func__,__LINE__,
			current->comm);
#endif
	}
#endif
}
EXPORT_SYMBOL(set_sock_hetero_obj);



#ifdef CONFIG_HETERO_STATS
void update_hetero_pgcache(int nodeid, struct page *page, int delpage) 
{
	if(delpage && page->hetero == HETERO_PG_FLAG && 
		 enbl_hetero_objaff) {	
		//spin_lock(&current->mm->objaff_cache_lock);
		//hetero_erase_cpage_rbtree(current, page);
		//spin_unlock(&current->mm->objaff_cache_lock);
		return;
	}

        if(page && page_to_nid(page) == nodeid) {
		if(enbl_hetero_objaff) {
			//spin_lock(&current->mm->objaff_cache_lock);
		        hetero_insert_cpage_rbtree(current, page);
			//spin_unlock(&current->mm->objaff_cache_lock);	
		}
		page->hetero = HETERO_PG_FLAG;
		current->mm->pgcache_hits_cnt += 1;
		/*if(current->mm->objaff_cache_len && 
		    current->mm->objaff_cache_len % HETERO_MIGRATE_FREQ == 0) {
			migrate_pages_slowmem(current);
		}*/
	}else {
		page->hetero = 0;
        	current->mm->pgcache_miss_cnt += 1;
	}
}
EXPORT_SYMBOL(update_hetero_pgcache);

void update_hetero_pgbuff_stat(int nodeid, struct page *page, int delpage) 
{
	int correct_node = 0; 
	if(!page) 
		return;
	if(page_to_nid(page) == nodeid)
		correct_node = 1;


	//Check if page is in the write node and 
	//we are not deleting and only inserting the page
	if(correct_node && !delpage) {
		current->mm->pgbuff_hits_cnt += 1;
		page->hetero = HETERO_PG_FLAG;
	}else if(!delpage) {
		current->mm->pgbuff_miss_cnt += 1;
		page->hetero = 0;
	}else if(delpage) {
		if( page->hetero != HETERO_PG_FLAG)
			return;
	}

	//Either if object affinity is disabled or page node is 
	//incorrect, then return
	if(!correct_node || !enbl_hetero_objaff)
		goto ret_pgbuff_stat;
	
	//spin_lock(&current->mm->objaff_kbuff_lock);

	//Not a page delete, then insert into kpage rbtree
	if(!delpage) {
		hetero_insert_kpage_rbtree(current, page);
	}else {
		//page delete, remove from kpage.
		//printk(KERN_ALERT "remove page \n");
		hetero_erase_kpage_rbtree(current, page);
	}
	//spin_unlock(&current->mm->objaff_kbuff_lock);

ret_pgbuff_stat:
	return;
}
EXPORT_SYMBOL(update_hetero_pgbuff_stat);


/*Simple miss increment; called specifically from 
functions that do not explicity aim to place pages 
on heterogeneous memory
*/
void update_hetero_pgbuff_stat_miss(void) 
{
        current->mm->pgbuff_miss_cnt += 1;
}
EXPORT_SYMBOL(update_hetero_pgbuff_stat_miss);
#endif

/* Check if the designed node and current page location 
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


/* start trace system call */
SYSCALL_DEFINE2(start_trace, int, flag, int, val)
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
	    reset_hetero_stats(current);	

	    if(enbl_hetero_objaff)		
	    	hetero_reset_rbtree(current);	

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
	    is_hetero_exit(current);
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
	    print_hetero_stats(current);
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

	default:
#ifdef CONFIG_HETERO_DEBUG
	   hetero_dbgmask = 1;	
#endif
	    hetero_pid = flag;
#ifdef CONFIG_HETERO_ENABLE
	    current->mm->hetero_task = HETERO_PROC;
#endif
#ifdef CONFIG_HETERO_OBJAFF
	    hetero_init_rbtree(current);
	    enbl_hetero_objaff = 1;
#else
	    enbl_hetero_objaff = 0;
#endif 
            memcpy(procname, current->comm, TASK_COMM_LEN);
	    printk("hetero_pid set to %d %d procname %s\n", hetero_pid, current->pid, procname);			
	    break;
    }
    return 0;
}



#ifdef CONFIG_HETERO_OBJAFF

/*Initialize hetero object pool*/
int hetero_init_rbtree(struct task_struct *task) {

	if(!task->mm->objaff_root_init) {
		task->mm->objaff_cache_rbroot = RB_ROOT;
		task->mm->objaff_cache_rbroot = RB_ROOT;
		task->mm->objaff_root_init = 1;
	}
}
EXPORT_SYMBOL(hetero_init_rbtree);


int hetero_reset_rbtree(struct task_struct *task) {
        //hetero_erase_cache_rbree(task);
	//hetero_erase_kbuff_rbree(task);
	task->mm->objaff_root_init = 0;
	return 0;
}
EXPORT_SYMBOL(hetero_reset_rbtree);


int hetero_insert_pg_rbtree(struct task_struct *task, struct page *page, 
			struct rb_root *root){

        struct rb_node **new = &(root->rb_node), *parent = NULL;

	if(!page) {
		printk("%s:%d page is NULL \n", __func__, __LINE__);
		return 0;
	}

	if(!task->mm->objaff_root_init) {
		printk("%s:%d root_init %d\n", __func__, __LINE__, 
			task->mm->objaff_root_init);
		return 0;
	}
	
        /* Figure out where to put new node */
        while (*new) {
                struct page *this = rb_entry(*new, struct page, rb_node);
                parent = *new;
                if(!this) {
                        printk("%s : %d page NULL \n", __func__, __LINE__);
                        goto insert_fail_pg;
                }

		if(this->mapping == NULL) {
			return -1;
		}

		//if(this->hetero == HETERO_PG_DEL_FLAG)
		//	rb_erase(&this->rb_node, root);

                if ((unsigned long)page < (unsigned long)this) {
                        new = &((*new)->rb_left);
                }else if ((unsigned long)page > (unsigned long)this){
                        new = &((*new)->rb_right);
                }else{
                        goto insert_success_pg;
                }
        }
        /* Add new node and rebalance tree. */
        rb_link_node(&page->rb_node, parent, new);
        rb_insert_color(&page->rb_node, root);
insert_success_pg:
#ifdef CONFIG_HETERO_DEBUG
        printk("%s : %d SUCCESS \n", __func__, __LINE__);
#endif
        return 0;

insert_fail_pg:
        printk("%s : %d FAIL \n", __func__, __LINE__);
        return -1;
}
EXPORT_SYMBOL(hetero_insert_pg_rbtree);


/*add pages to rbtree node */
int hetero_insert_cpage_rbtree(struct task_struct *task, struct page *page){

	int ret = 0;
        struct rb_root *root = &task->mm->objaff_cache_rbroot;
	
        //if (unlikely(!trylock_page(page)))
          //      goto out_putpage;

	//ret = hetero_insert_pg_rbtree(task, page, root);
	if(!ret) {
		task->mm->objaff_cache_len++;
	}
	//unlock_page(page);

out_putpage:
	return 0;
}
EXPORT_SYMBOL(hetero_insert_cpage_rbtree);

/*add pages to rbtree node */
int hetero_insert_kpage_rbtree(struct task_struct *task, struct page *page){

	int ret = -1;
        struct rb_root *root = &task->mm->objaff_pgbuff_rbroot;
	ret = hetero_insert_pg_rbtree(task, page, root);
	if(!ret) {
		task->mm->objaff_kbuff_len++;
		//printk(KERN_ALERT "%s:%d Kbuff enteries %lu\n",
		//	__func__, __LINE__,task->mm->objaff_kbuff_len);
	}
}
EXPORT_SYMBOL(hetero_insert_kpage_rbtree);



/*Search for page. BUGGY currently */
struct page *hetero_search_pg_rbtree(struct task_struct *task, struct page *page){

	struct rb_root *root = &task->mm->objaff_cache_rbroot;
        struct rb_node *node = root->rb_node;
        unsigned long srcobj = (unsigned long)page;
	struct page *new = NULL;

        while (node) {
                struct page *this = rb_entry(node, struct page, rb_node);
                if(!this) {
                        printk("%s : %d page search failed \n", __func__, __LINE__);
                        return 0;
                }
                if( srcobj == (unsigned long)this) {
			new = this;
                        goto ret_search_page;
                }
                if ( srcobj < (unsigned long)this)
                        node = node->rb_left;
                else if (srcobj > (unsigned long)this)
                        node = node->rb_right;
        }
        return 0;
ret_search_page:
#ifdef CONFIG_HETERO_DEBUG
        printk("%s : %d page search SUCCESS \n", 
		__func__, __LINE__);
#endif
        return new;
}
EXPORT_SYMBOL(hetero_search_pg_rbtree);

void hetero_add_to_list(struct page *page, struct list_head *list_pages){
        list_add(&page->hetero_list, list_pages);
}

void hetero_del_from_list(struct page *page)
{
        unsigned long flags;
        //raw_spin_lock_irqsave(&undef_lock, flags);
        list_del(&page->hetero_list);
        //raw_spin_unlock_irqrestore(&undef_lock, flags);
}

void hetero_erase_cpage_rbtree(struct task_struct *task, struct page *page)
{
        struct rb_root *root = &task->mm->objaff_cache_rbroot;

	if(!task->mm->objaff_root_init) {
		printk("%s:%d root_init %d\n", __func__, __LINE__, 
			task->mm->objaff_root_init);
		return;
	}

	if(root && page) {

	        if (unlikely(!trylock_page(page)))
                	goto out_erasepage;

		rb_erase(&page->rb_node, root);
		unlock_page(page);	
		printk(KERN_ALERT "%s:%d erase complete \n", __func__, __LINE__);
	
		if(task->mm->objaff_cache_len)
			task->mm->objaff_cache_len--;
	}
out_erasepage:
	/* Just mark for deletion*/
	page->hetero = HETERO_PG_DEL_FLAG;
	return;
}
EXPORT_SYMBOL(hetero_erase_cpage_rbtree);


void hetero_erase_kpage_rbtree(struct task_struct *task, struct page *page)
{
        struct rb_root *root = &task->mm->objaff_pgbuff_rbroot;

	if(!task->mm->objaff_root_init) {
		printk("%s:%d root_init %d\n", __func__, __LINE__, 
			task->mm->objaff_root_init);
		return;
	}
	if(root && page) {
	   //rb_erase(&page->rb_node, root);
	   page->hetero = HETERO_PG_DEL_FLAG;
	   if(task->mm->objaff_kbuff_len)
	   	task->mm->objaff_kbuff_len--;
	}
}
EXPORT_SYMBOL(hetero_erase_kpage_rbtree);


void hetero_erase_cache_rbree(struct task_struct *task) {

	struct rb_root *root = &task->mm->objaff_cache_rbroot;
        unsigned int count = 0;
	struct rb_node *n;
	struct page *new = NULL;

	//spin_lock(&task->mm->objaff_lock);
        for (n = rb_first(root); n != NULL; n = rb_next(n)) {
		new = rb_entry(n, struct page, rb_node);
		if(new) {
			rb_erase(&new->rb_node, root);
			count++;
		}
	}
	//spin_unlock(&task->mm->objaff_lock);
        if (count)
                printk("%s : %d page erase SUCCESS count %d \n", 
			__func__, __LINE__, count);
}


void hetero_erase_kbuff_rbree(struct task_struct *task) {

	struct rb_root *root = &task->mm->objaff_pgbuff_rbroot;
        struct rb_node *n, *next;
        unsigned int count = 0;
	struct page *new = NULL;
        int i;

	if(!task->mm->objaff_root_init) {
		printk("%s:%d root_init %d\n", __func__, __LINE__, 
			task->mm->objaff_root_init);
		return;
	}
	//spin_lock(&task->mm->objaff_lock);
        for (n = rb_first(root); n != NULL; n = rb_next(n)) {

		if(n == NULL) {	
			break;	
		}
		new = rb_entry(n, struct page, rb_node);
		if(new) {
			rb_erase(&new->rb_node, root);
			count++;
		}
	}
	//spin_unlock(&task->mm->objaff_lock);
        if (count)
                printk("%s : %d page erase SUCCESS count %d \n", 
			__func__, __LINE__, count);
}



/* Generate page list from RB tree */
int 
gen_list_from_rbtree(struct rb_root *root, struct list_head *list_pages) {

	struct rb_node *n, *next;
	unsigned long count = 0;
	struct page *new = NULL;

	if(!list_pages || !root) {
		printk("%s:%d NULL \n", __func__, __LINE__);
	}

        for (n = rb_first(root); n != NULL; n = rb_next(n)) {

		if(n == NULL) {	
			break;	
		}
		new = rb_entry(n, struct page, rb_node);
		if(new) {
			if (trylock_page(new)) {
				hetero_add_to_list(new, list_pages);
				unlock_page(new);
				count++;
			}
			//printk("%s:%d page to PFN: %lu \n", 
			//	 __func__, __LINE__, page_to_pfn(new));
		}
		if(count > 10) 
			break;
		//new = NULL;
	}
	printk("%s:%d Num pages added to list %lu \n", 
		__func__, __LINE__, count);
	return 0;
}


/* Generate page list from RB tree */
int 
del_list_from_rbtree(struct rb_root *root, struct list_head *list_pages){

	struct rb_node *n, *next;
	unsigned long count = 0;
	struct page *new = NULL;

	if(!list_pages || !root) {
		printk("%s:%d NULL \n", __func__, __LINE__);
	}

        for (n = rb_first(root); n != NULL; n = rb_next(n)) {

		if(n == NULL) {	
			break;	
		}
		new = rb_entry(n, struct page, rb_node);
		if(new) {
			hetero_del_from_list(new);
			//printk("%s:%d page to PFN: %lu \n", 
			//	 __func__, __LINE__, page_to_pfn(new));
			count++;
		}
		new = NULL;
	}
	printk("%s:%d Num pages deleted from list %lu \n", 
		__func__, __LINE__, count);
	return 0;
}


int delme_counter = 0;

void 
try_hetero_migration(void *map, gfp_t gfp_mask){

        struct rb_node *n, *next;
        unsigned long count = 0;
        struct page *newpg = NULL;
	struct page *oldpage = NULL;
	struct rb_root *root;
	struct address_space *mapping = (struct address_space *)map;
	int destnode = get_slowmem_node();

	if(!current->mm || (current->mm->hetero_task != HETERO_PROC))
		return;

	if(!mapping) 
		return;

	if(!current->mm->objaff_cache_len || 
		(current->mm->objaff_cache_len % HETERO_MIGRATE_FREQ != 0)) {
		return;
	}else {
		//printk("%s:%d Cache length %lu \n", __func__, __LINE__, 
		//	current->mm->objaff_cache_len);
	}
	root = &current->mm->objaff_cache_rbroot;
        if(!root) {
                printk("%s:%d NULL \n", __func__, __LINE__);
        }

	count = migrate_to_node_hetero(current->mm, get_fastmem_node(), get_slowmem_node(),
		   MPOL_MF_MOVE_ALL);
	//printk("%s:%d migrate_to_node_hetero returned %lu \n", __func__, __LINE__, 
	//		count);
	return;

        for (n = rb_first(root); n != NULL; n = rb_next(n)) {

                if(n == NULL) 
                        break;

                oldpage = rb_entry(n, struct page, rb_node);
		if(!oldpage) {
			 goto out_try_migration;
		}
		
                if(!oldpage->mapping) {
			//hetero_erase_cpage_rbtree(current, oldpage);
			goto out_try_migration;
		}

		newpg = page_cache_alloc(mapping);
                if (!newpg) 
                        goto out_try_migration;


		/*if (WARN_ON(page_mapped(oldpage))) {
			printk("%s:%d NULL \n", __func__, __LINE__);
			continue;
		}*/
		if (WARN_ON(page_has_private(oldpage))) {
			printk("%s:%d NULL \n", __func__, __LINE__);
			continue;
		}
		if (WARN_ON(PageDirty(oldpage) || PageWriteback(oldpage))) {
			printk("%s:%d NULL \n", __func__, __LINE__);	
			continue;
		}
		if (WARN_ON(PageMlocked(oldpage))) {
			printk("%s:%d NULL \n", __func__, __LINE__);
			continue;
		}

#if 0
		//if(migrate_onepage_hetero(oldpage, alloc_new_node_page, NULL, destnode,
                  //       MIGRATE_SYNC, MR_SYSCALL, current)) {
		//if (replace_page_cache_page_hetero(oldpage, newpg, gfp_mask)) {
		if(migrate_page(oldpage->mapping, newpg, oldpage, MIGRATE_SYNC)) {
			put_page(oldpage);
		}else {
			printk("%s:%d SUCCESS \n",__func__, __LINE__);
			hetero_erase_cpage_rbtree(current, oldpage);
			oldpage->mapping = NULL;
			delme_counter++;
		}
#endif
                newpg = NULL;
        }
out_try_migration:
        //printk("%s:%d Num pages deleted from list %lu \n",
        //        __func__, __LINE__, count);
        return 0;
}
EXPORT_SYMBOL(try_hetero_migration);





int migrate_pages_slowmem(struct task_struct *task) {

	//page list with pages to migrate.
	static LIST_HEAD(pagelist);
	//destination node
	int destnode = get_slowmem_node();
	//migration error flag
	int err = -1;
	//spin lock
	spinlock_t migrate_lock;
	struct rb_root *root = &task->mm->objaff_cache_rbroot;

	if(delme_counter)
		return;
	delme_counter++;

	//Intialize list
	//INIT_LIST_HEAD(&pagelist);

	//generate linked list from page_cache rb tree
	//if(gen_list_from_rbtree(root, &pagelist)) {
	//	printk("%s:%d gen_list_from_rbtree failed \n", 
	//		__func__, __LINE__);
	//}

	//migrate_prep();
#if 0
	//spin_lock(&migrate_lock);
        //if (!list_empty(&pagelist)) {

	printk(KERN_ALERT "Number of pages before migration %u \n", 
		task->mm->objaff_cache_len);

	if(task->mm->objaff_cache_len) {

		//replace_page_cache_page(struct page *old, struct page *new, gfp_t gfp_mask);

		err = migrate_pages_hetero_rbtree(root, alloc_new_node_page, NULL, destnode,
			MIGRATE_SYNC, MR_SYSCALL, task);	

	        if (err) {
			printk("%s:%d migrate_pages failed \n", 
				__func__, __LINE__);			
			putback_movable_pages(&pagelist);
	        }else {
			 printk("%s:%d migrate_pages succeeded \n",
				 __func__, __LINE__);
                }
        }
#endif
	//spin_unlock(&migrate_lock);

	msleep(10000);

        //delete linked list from page_cache rb tree
        //if(del_list_from_rbtree(root, &pagelist)) {
          //      printk("%s:%d gen_list_from_rbtree failed \n",
            //            __func__, __LINE__);
        //}
	return 0;
}
#endif
