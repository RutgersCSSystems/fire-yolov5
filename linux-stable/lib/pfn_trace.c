#include <linux/rbtree_augmented.h>
#include <linux/export.h>
#include <asm/page.h>
#include <linux/bootmem.h>
#include <linux/slab.h>
#include <linux/mm.h>
#include <linux/mm_inline.h>
#include <linux/pfn_trace.h>
#include <linux/hashtable.h>


#define PFN_BIT 21

DEFINE_HASHTABLE(pfn_table, PFN_BIT);
/*
struct pfn_node {
	unsigned long pfn_val;
	struct hlist_node next;
}
*/
void insert_pfn_hashtable(unsigned long pfn) {
	unsigned long key;

	struct pfn_node *p_node = (struct pfn_node *)kmalloc(sizeof(*p_node), GFP_KERNEL);
	if (!p_node)
		printk("Allocation error! \n");
	
	p_node->pfn_val = pfn;

	key = pfn % max_pfn;
	hash_add(pfn_table, &p_node->next, key);
}
EXPORT_SYMBOL(insert_pfn_hashtable);

void print_pfn_hashtable(void) {
	unsigned long bkt;

	struct pfn_node *cur;
	int cnt;

	for ((bkt) = 0, cur = NULL; cur==NULL && (bkt) < HASH_SIZE(pfn_table); (bkt)++) {
		cnt = 0;
		hlist_for_each_entry(cur, &pfn_table[bkt], next) {
			cnt++;
		}
		printk("pfn %lu: %d\n", bkt, cnt);
	}
}
EXPORT_SYMBOL(print_pfn_hashtable);
