/* SPDX-License-Identifier: GPL-2.0 */
#ifndef _LINUX_HETERO_H
#define _LINUX_HETERO_H

/* HeteroOS code */
#define _ENABLE_HETERO

#ifdef _ENABLE_HETERO
#define NUMA_HETERO_NODE 1
/* Page cache allocation */
#define _ENABLE_PAGECACHE
/* Buffer allocation */
#define _ENABLE_BUFFER
/* Journal allocation */
#define _ENABLE_JOURNAL
/* Radix tree allocation */
#define _ENABLE_RADIXTREE
#endif


int is_hetero_pgcache_set(void);
int is_hetero_buffer_set(void);
int is_hetero_journ_set(void);
int is_hetero_radix_set(void);

#endif /* _LINUX_NUMA_H */