#ifndef _PREDICTOR_HPP
#define _PREDICTOR_HPP

#include "util.hpp"
#include "utils/thpool.h"
#include "utils/bitarray.h"

#define DEFNSEQ (-8) //Not seq or strided(since off_t is ulong)
#define LIKELYNSEQ (-4) /*possibly not seq */
#define POSSNSEQ 0 /*possibly not seq */
#define MAYBESEQ 1 /*maybe seq */
#define POSSSEQ 2 /* possibly seq? */
#define LIKELYSEQ 4 /* likely seq? */
#define DEFSEQ 8 /* definitely seq */

void hello_predictor();

///////////////////////////////////////////////////////////////
//This portion is used to keep track of per file prefetching
///////////////////////////////////////////////////////////////


class file_predictor{
	public:
		int fd;
		size_t filesize;

		/*
		 * The file is divided into FILESIZE/(PORTION_SIZE*PAGESIZE) portions
		 * Each such portions is represented with a bit in access_history
		 * Accesses to an area represented by a set bit increases sequentiality
		 * else increases Non sequentiality
		 */
		bit_array_t *access_history;
		size_t nr_portions;
		size_t portion_sz;

		/*
		 * This is the difference between the last access
		 * and this access.
		 * XXX: ASSUMPTION for now: Stride doesnt change for a file
		 * the read_size doesnt change either
		 */
		size_t stride; //in nr_portions
		size_t read_size; //in bytes

		/*
		 * For each file doing readahead_info, the syscall
		 * returns the page cache state in its return struct
		 * We will be using this to update the access_history
		 * based on the PORTION_PAGES.
		 */
		bit_array_t *page_cache_state;

		/*
		 * This variable summarizes if the file is reasonably
		 * sequential/strided for prefetching to happen.
		 */
		long sequentiality;

		/*
		 * Returns true if readahead has been issued
		 * for this file
		 */
		std::atomic_flag already_prefetched;

		/*Constructor*/
		file_predictor(int this_fd, size_t size){


			fd = this_fd;
			filesize = size;


			portion_sz = PAGESIZE * PORTION_PAGES;
			nr_portions = size/portion_sz;

			//Imperfect division of filesize with portion_sz
			//add one bit to accomodate for the last portion in file
			if(size % portion_sz){
				nr_portions += 1;
			}

			access_history = BitArrayCreate(nr_portions);
			BitArrayClearAll(access_history);

#if defined(READAHEAD_INFO_PC_STATE) && !defined(PER_INODE_BITMAP)
			page_cache_state = BitArrayCreate(NR_BITS_PREALLOC_PC_STATE);
			BitArrayClearAll(page_cache_state);
#else
			page_cache_state = NULL;
#endif

			//Assume any opened file is probably not sequential
			sequentiality = POSSNSEQ;
			stride = 0;
			read_size = 0;
		}

		/*Destructor*/
		~file_predictor(){
			BitArrayDestroy(access_history);

#ifdef READAHEAD_INFO_PC_STATE
			BitArrayDestroy(page_cache_state);
#endif
		}

		/*
		 * If offset being accessed is from an Unset file portion, set it,
		 * 1. Set that file portion in access_history
		 * 2. reduce the sequentiality
		 *
		 * else increase the sequentiality
		 *
		 */
		void predictor_update(off_t offset, size_t size){

#if 0
			/*
			 * Once the file is sent for prefetching
			 * there is no point in keeping the prefetcher running for this file
			 * TODO: test only works for C++20
			 */
			if(already_prefetched.test()){
				goto exit;
			}
#endif


			size_t portion_num = offset/portion_sz; //which portion
			size_t num_portions = size/portion_sz; //how many portions in this req
			size_t pn = 0; //used for adjacency check

			if(portion_num > nr_portions){
				printf("%s: ERR : portion_num > nr_portions, has the filesize changed ?\n", __func__);
				goto exit;
			}

			/*
			 * Go through the bit array, setting ones portions associated
			 * with this read request
			 */
			for(long i=0; i<=num_portions; i++)
				BitArraySetBit(access_history, portion_num+i);

			/*
			 * Determine if this sequential or strided
			 * TODO: Convert this to a bit operation, this is heavy
			 * Develop a bit mask and test the corresponding bits
			 */
			for(long i = 1; i <= NR_ADJACENT_CHECK; i++){

				pn = portion_num - i;

				/*bounds check*/
				if((long)pn < 0){
					goto exit;
				}

				if(BitArrayTestBit(access_history, pn)){
					stride = portion_num - pn - 1;
					if(stride > 0)
						read_size = size;
					//debug_printf("%s: stride=%ld\n", __func__, stride);
					goto is_seq;
				}

			}

is_not_seq:
			//sequentiality -= 1;
			//sequentiality %= (DEFNSEQ-1); //Keeps from underflowing
                        sequentiality = (std::max<long>)(DEFNSEQ, sequentiality-1); //keeps from underflowing
			goto exit;

is_seq:
			//if(sequentiality < DEFSEQ)
			//sequentiality += 1;
			//sequentiality %= (DEFSEQ+1); //Keeps from overflowing
                        sequentiality = (std::min<long>)(DEFSEQ, sequentiality+1); //keeps from overflowing

exit:
			return;
		}


		//Returns the current Sequentiality value
		long is_sequential(){
			return sequentiality;
		}

		//returns the approximate stride in pages
		//0 if not strided. doesnt mean its not sequential
		long is_strided(){
			return stride*PORTION_PAGES;
		}

};

#endif //_PREDICTOR_HPP
