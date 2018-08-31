/* SPDX-License-Identifier: GPL-2.0 */
#ifndef _LINUX_NUMA_H
#define _LINUX_NUMA_H


#ifdef CONFIG_NODES_SHIFT
#define NODES_SHIFT     CONFIG_NODES_SHIFT
#else
#define NODES_SHIFT     0
#endif

#define MAX_NUMNODES    (1 << NODES_SHIFT)

#define	NUMA_NO_NODE	(-1)

/* HeteroOS code */
/*
#define _ENABLE_HETERO
#define NUMA_HETERO_NODE   0
*/

/* Page cache allocation */
#define _ENABLE_PAGECACHE
#define NUMA_PAGECACHE_HETERO_NODE   0

/* Buffer allocation */
#define _ENABLE_BUFFER
#define NUMA_BUFFER_HETERO_NODE   0

/* Journal allocation */
#define _ENABLE_JOURNAL
#define NUMA_JOURNAL_HETERO_NODE   0

/* Radix tree allocation */
#define _ENABLE_RADIXTREE
#define NUMA_RADIXTREE_HETERO_NODE   0

#endif /* _LINUX_NUMA_H */
