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
#include <linux/jiffies.h>
#include <linux/vmalloc.h>
#include <linux/rwsem.h>

#include <linux/btree.h>
#include <linux/radix-tree.h>
#include <linux/bitmap.h>

#include <linux/buffer_head.h>
#include <linux/jbd2.h>

#include <linux/uaccess.h>
#include <asm/cacheflush.h>
#include <asm/tlb.h>
#include <asm/atomic.h>
#include <asm/mmu_context.h>
//#include <linux/pfn_trace.h>
#include <net/sock.h>
#include <linux/migrate.h>
//#include <sys/time.h>
#include <linux/time64.h>
#include <linux/fs.h>

#include "internal.h"



/*
 * ptr : address where to allocate the bitmap
 * nr_pages : nr of pages in the file. 
 * nr_portion : How many pages would each bit represent
 */
void alloc_cross_bitmap(struct inode *inode, unsigned long nr_pages){

        if(!inode || !nr_pages){
                goto exit;
        }

        unsigned long start, end;

        start = jiffies;

        unsigned long prealloc_pg;
        long nr_longs;

	/*
	 * Check if cross_bitmap_shift is not set
	 * Set to default
	 */
	if(cross_bitmap_shift <= 0){
		cross_bitmap_shift = CONFIG_CROSS_PREALLOC_SHIFT;
	}

        prealloc_pg = 1UL << (cross_bitmap_shift - PAGE_SHIFT);

        nr_longs = BITS_TO_LONGS(prealloc_pg);

        //printk("%s: Bitmap being allocated of size=%ld\n", __func__, sizeof(unsigned long)*nr_longs);

        //spin_lock(&inode->bitmap_spinlock);
        down_write(&inode->bitmap_rw_sem);

        if(!inode->bitmap){
                //printk("%s: curr=%d, inode=%ld bitmap allocated\n", __func__, current->pid, inode->i_ino);
                inode->bitmap = vmalloc(sizeof(unsigned long)*nr_longs);
        }

        if(!inode->bitmap){
                printk("ERR:%s unable to allocate bitmap\n", __func__);
                spin_unlock(&inode->bitmap_spinlock);
                return;
        }

	//Set the flag that indicates bitmap is set
	atomic_set(&inode->i_bitmap_freed, 0);

        //spin_unlock(&inode->bitmap_spinlock);
        up_write(&inode->bitmap_rw_sem);
        
        inode->nr_bits_used = nr_pages;
        inode->nr_longs_used = BITS_TO_LONGS(nr_pages);

        inode->nr_bits_tot = prealloc_pg;
        inode->nr_longs_tot = nr_longs;

        bitmap_zero(inode->bitmap, prealloc_pg);


        //bitmap_set(inode->bitmap, 0, 1);

#if 0
        end = jiffies;
        printk("%s: preallocate %ld pg, nr_longs=%ld in %ld millisec\n", __func__, prealloc_pg, nr_longs,
                        (((end-start)*1000)/HZ));
#endif

exit:
        return;
}
EXPORT_SYMBOL(alloc_cross_bitmap);


/*
 * Frees the bitmap
 * TODO: Check if this works, and place it in relevant functions
 * something like destroy inode
 */
void free_cross_bitmap(struct inode *inode){

        if(!inode || !inode->bitmap)
                goto exit;

        //spin_lock(&inode->bitmap_spinlock);
        down_write(&inode->bitmap_rw_sem);
	if(inode->bitmap) {

		//printk(KERN_ALERT "%s: releasing mem for inode with i_count "
		//		"%d\n", __func__, atomic_read(&inode->i_count));

		atomic_set(&inode->i_bitmap_freed, 1);
        	vfree(inode->bitmap);
		inode->bitmap = NULL;
	}
        //spin_unlock(&inode->bitmap_spinlock);
        up_write(&inode->bitmap_rw_sem);
exit:
        return;
}
EXPORT_SYMBOL(free_cross_bitmap);


/*
 */
void remove_pg_cross_bitmap(struct inode *inode, pgoff_t index){

        if(!inode || !inode->bitmap)
                goto exit;

	/*bitmap for the inode is not cleared */
	if (atomic_read(&inode->i_bitmap_freed) == 1)
		goto exit;

        bitmap_clear(inode->bitmap, index, 1);

        //printk("%s: i_ino=%ld, pg_off=%ld\n", __func__, inode->i_ino, index);
exit:
        return;
}
EXPORT_SYMBOL(remove_pg_cross_bitmap);


/*
 */
void add_pg_cross_bitmap(struct inode *inode, pgoff_t index){

        if(!inode || !inode->bitmap)
                goto exit;

	/*bitmap for the inode is not cleared */
	if (atomic_read(&inode->i_bitmap_freed) == 1){
                //printk("%s: bitmap_freed inode=%ld\n", __func__, inode->i_ino);
		goto exit;
        }


        //printk("%s: i_ino=%ld, pg_off=%ld\n", __func__, inode->i_ino, index);

        bitmap_set(inode->bitmap, index, 1);

exit:
        return;
}
EXPORT_SYMBOL(add_pg_cross_bitmap);


/*
 * Returns true if that that index is set in bitmap
 */
bool is_set_cross_bitmap(struct inode *inode, pgoff_t index){

        if(!inode)
                goto exit;

        if(!inode->bitmap)
                goto exit;

        return test_bit(index, inode->bitmap);
exit:
        return false;
}
EXPORT_SYMBOL(is_set_cross_bitmap);



/*
 * Initializes cross data for inode
 */
void init_inode_cross(struct inode *inode){
        if(!inode)
                goto exit;

        //spin_lock_init(&inode->bitmap_spinlock);
        init_rwsem(&inode->bitmap_rw_sem);

        /*
         * Set it to 1 to make sure no one tries to access
         * the bitmap without allocation
         */
	atomic_set(&inode->i_bitmap_freed, 1);

        inode->nr_bits_used = 0;
        inode->nr_longs_used = 0;
        inode->nr_bits_tot = 0;
        inode->nr_longs_tot = 0;

exit:
        return;
}

#if 0
void *cross_test(void){

        //DECLARE_BITMAP(bitmap, 64);
        unsigned long *bitmap = NULL;
        
        alloc_cross_bitmap(&bitmap, 129);

        bitmap_zero(bitmap, 129);

        bitmap_set(bitmap, 3, 5);
        bitmap_set(bitmap, 56, 5);

        //free_cross_bitmap(&bitmap);
        //vfree(bitmap);

        //printk("%s: test: %lX\n", __func__, bitmap[0]);
        return (void*)bitmap;
}
EXPORT_SYMBOL(cross_test);
#endif
