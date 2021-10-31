

cat 10-September-ssd_oldnix_rocksdb-BW-readseq-8_appth-4096_valsz-1000_keysz-4000000_num-67108864_writebufsz_pred.dat | awk -F"," '{$1=""; print $0}' | sed 's/ /,/g' > ssd_oldnix_rocksdb-BW-readseq-8_appth-4096_valsz-1000_keysz-4000000_num-67108864_writebufsz_pred.dat
cat 10-September-ssd_oldnix_rocksdb-BW-readseq-16_appth-4096_valsz-1000_keysz-4000000_num-67108864_writebufsz_pred.dat | awk -F"," '{$1=""; print $0}' | sed 's/ /,/g' > ssd_oldnix_rocksdb-BW-readseq-16_appth-4096_valsz-1000_keysz-4000000_num-67108864_writebufsz_pred.dat
cat 10-September-ssd_oldnix_rocksdb-BW-readseq-32_appth-4096_valsz-1000_keysz-4000000_num-67108864_writebufsz_pred.dat | awk -F"," '{$1=""; print $0}' | sed 's/ /,/g' > ssd_oldnix_rocksdb-BW-readseq-32_appth-4096_valsz-1000_keysz-4000000_num-67108864_writebufsz_pred.dat

i=8
paste -d "," 09-September-ssd_oldnix_rocksdb-BW-readseq-${i}_appth-4096_valsz-1000_keysz-4000000_num-67108864_writebufsz.dat ssd_oldnix_rocksdb-BW-readseq-${i}_appth-4096_valsz-1000_keysz-4000000_num-67108864_writebufsz_pred.dat > ssd_oldnix_rocksdb-BW-readseq-${i}_appth-4096_valsz-1000_keysz-4000000_num-67108864_writebufsz_both.dat

i=16
paste -d "," 09-September-ssd_oldnix_rocksdb-BW-readseq-${i}_appth-4096_valsz-1000_keysz-4000000_num-67108864_writebufsz.dat ssd_oldnix_rocksdb-BW-readseq-${i}_appth-4096_valsz-1000_keysz-4000000_num-67108864_writebufsz_pred.dat > ssd_oldnix_rocksdb-BW-readseq-${i}_appth-4096_valsz-1000_keysz-4000000_num-67108864_writebufsz_both.dat

i=32
paste -d "," 09-September-ssd_oldnix_rocksdb-BW-readseq-${i}_appth-4096_valsz-1000_keysz-4000000_num-67108864_writebufsz.dat ssd_oldnix_rocksdb-BW-readseq-${i}_appth-4096_valsz-1000_keysz-4000000_num-67108864_writebufsz_pred.dat > ssd_oldnix_rocksdb-BW-readseq-${i}_appth-4096_valsz-1000_keysz-4000000_num-67108864_writebufsz_both.dat
