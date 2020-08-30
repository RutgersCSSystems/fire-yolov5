/* SPDX-License-Identifier: GPL-2.0 */
#ifndef _LINUX_HETERO_H
#define _LINUX_HETERO_H

#include <linux/vmalloc.h>

/* HeteroOS code */
//#define CONFIG_HETERO_ENABLE
//#define _HETERO_MIGRATE
//#define _HETERO_ZSMALLOC

#ifdef CONFIG_HETERO_ENABLE

#define HETERO_PG_FLAG 1
#define HETERO_PG_DEL_FLAG 2
#define HETERO_PG_MIG_FLAG 3

#define _USE_HETERO_PG_FLAG
#define NUMA_FAST_NODE 0
#define NUMA_HETERO_NODE 1
#define HETERO_PROC 4

#ifdef CONFIG_HETERO_STATS

enum {
        HETERO_APP_PAGE    = 1000,
        HETERO_KBUFF_PAGE  = 1001,
        HETERO_CACHE_PAGE  = 1002
};
#endif

/* Page cache allocation */
#define _ENABLE_PAGECACHE
/* Buffer allocation */
#define CONFIG_HETERO_ENABLE_BUFFER
/* Journal allocation */
#define _ENABLE_JOURNAL
/* Radix tree allocation */
#define CONFIG_HETERO_ENABLE_RADIX
/* Page table allocation */
#define CONFIG_HETERO_ENABLE_PGTBL
#else
#define NUMA_HETERO_NODE 0
#endif

/*
 * Debug code
 */
#ifdef pr_fmt
#undef pr_fmt
#define pr_fmt(fmt) KBUILD_MODNAME ": " fmt
#endif

extern int hetero_dbgmask;

#define hetero_dbg(s, args ...)              \
        ((1 & hetero_dbgmask) ? pr_warning(s, ## args) : 0)
#define hetero_force_dbg(s, args ...)     pr_warning(s, ## args)
#define hetero_err(sb, s, args ...)       pmfs_error_mng(sb, s, ## args)
#define hetero_warn(s, args ...)          pr_warning(s, ## args)
#define hetero_info(s, args ...)          pr_info(s, ## args)

struct vm_area_struct;

int check_hetero_proc (struct task_struct *task);
int check_listcnt_threshold(unsigned int listcount);
extern int page_list_count(struct list_head *pagelist);

int is_hetero_pgcache_set(void);
int is_hetero_buffer_set(void);
int is_hetero_journ_set(void);
int is_hetero_radix_set(void);
int is_hetero_kernel_set(void);
int is_hetero_pgtbl_set(void);
int is_hetero_exit(struct task_struct *task);
int is_hetero_obj(void *obj);
int is_hetero_cacheobj(void *obj);
int is_hetero_vma(struct vm_area_struct *);
int is_hetero_page(struct page *page, int nodeid);
int is_hetero_pgcache_readahead_set(void);

int get_fastmem_node(void);
int get_slowmem_node(void);
void set_curr_hetero_obj(void *obj);
void set_fsmap_hetero_obj(void *mapobj);
void set_hetero_obj_page(struct page *page, void *obj);
void debug_hetero_obj(void *obj);
void print_hetero_stats(struct task_struct *task);
void incr_global_stats(unsigned long *counter);
void set_sock_hetero_obj(void *socket, void *inode);
int hetero_init_rbtree(struct task_struct *task);
void set_sock_hetero_obj_netdev(void *socket, void *inode);


int check_hetero_page(struct mm_struct *mm, struct page *page);
void update_hetero_pgcache(int node, struct page *, int delpage);
void update_hetero_pgbuff_stat(int nodeid, struct page *page, int delpage);
void try_hetero_migration(void *map, gfp_t gfp_mask);

/* rbtree */
int 
hetero_insert_cpage_rbtree(struct task_struct *task, struct page *page);
int 
hetero_insert_kpage_rbtree(struct task_struct *task, struct page *page);
void hetero_erase_cpage_rbtree(struct task_struct *task, struct page *page);
void hetero_erase_kpage_rbtree(struct task_struct *task, struct page *page);
struct page *hetero_search_pg_rbtree(struct task_struct *task, 
				     struct page *page);
/* Erase full rbtree */
void hetero_erase_cache_rbree(struct task_struct *task);
void hetero_erase_kbuff_rbree(struct task_struct *task);
int hetero_reset_rbtree(struct task_struct *task);
int migrate_pages_slowmem(struct task_struct *task);

void
hetero_replace_cache(gfp_t gfp_mask, struct page *oldpage);


/*Private LRU*/
void pvt_active_lru_insert(struct page *page);
void pvt_inactive_lru_insert(struct page *page);
void pvt_active_lru_remove(struct page *page);
void pvt_inactive_lru_remove(struct page *page);


#ifdef CONFIG_HETERO_STATS
void incr_tot_cache_pages(void);
void incr_tot_buff_pages(void);
void incr_tot_app_pages(void);
#endif

#endif /* _LINUX_NUMA_H */


