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
#define NUMA_FAST_NODE 0
#define NUMA_HETERO_NODE 1
#define HETERO_PROC 1
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
#define hetero_err(sb, s, args ...)       pmfs_error_mng(sb, s, ## args)
#define hetero_warn(s, args ...)          pr_warning(s, ## args)
#define hetero_info(s, args ...)          pr_info(s, ## args)


int is_hetero_pgcache_set(void);
int is_hetero_buffer_set(void);
int is_hetero_journ_set(void);
int is_hetero_radix_set(void);
int is_hetero_kernel_set(void);
int is_hetero_pgtbl_set(void);
int is_hetero_exit(void);
inline int is_hetero_obj(void *obj);
int is_hetero_page(struct page *page, int nodeid);

void set_curr_hetero_obj(void *obj);
void set_fsmap_hetero_obj(void *mapobj);
void set_hetero_obj_page(struct page *page, void *obj);

#ifdef CONFIG_HETERO_STATS
void update_hetero_pgcache(int node, struct page *);
void update_hetero_pgbuff_stat(int nodeid, struct page *page);
#endif

#endif /* _LINUX_NUMA_H */


