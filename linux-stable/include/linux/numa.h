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
#define NUMA_HETERO_NODE   1
*/

/* Page cache allocation */
/*
#define _ENABLE_PAGECACHE
#define NUMA_HETERO_NODE   1
*/

/* Buffer allocation */
/*
#define _ENABLE_BUFFER
#define NUMA_HETERO_NODE   1
*/

/* Journal allocation */
/*
#define _ENABLE_JOURNAL
#define NUMA_HETERO_NODE   1
*/

/* Radix tree allocation */

#define _ENABLE_RADIXTREE
#define NUMA_HETERO_NODE   1


#endif /* _LINUX_NUMA_H */
