set -x
MYSQL_USER="root"
MYSQL_DBUSER="mysql"
MYSQL_PASSWD="pass"
PREFIX="numactl --membind=1"
DBNAME="s3"
#PREFIX=""
MYSQL_OPTIONS="--db-driver=mysql --mysql-user=$MYSQL_USER --mysql-password=$MYSQL_PASSWD --mysql-db=$DBNAME --table_size=10000000 --events=0 --time=60"

#CREATE $DBNAME DATABASE
CREATE_DB() {
	mysql -u $MYSQL_USER -p $MYSQL_DBUSER -e "CREATE DATABASE $DBNAME;"
	mysql -u $MYSQL_USER -p $MYSQL_DBUSER -e "CREATE USER $DBNAME@localhost;"
	mysql -u $MYSQL_USER -p $MYSQL_DBUSER -e "GRANT ALL PRIVILEGES ON $DBNAME.* TO $DBNAME@localhost;"
}

#Prepare sysbench
PREPARE_SYSBENCH() {
	sysbench --db-driver=mysql --mysql-user=$MYSQL_USER --mysql-password=$MYSQL_PASSWD --mysql-db=$DBNAME --table_size=10000000 --threads=16 /usr/share/sysbench/oltp_read_only.lua prepare
}


#Run read only
READ_ONLY() {
	#for each in 1 2 4 8 16 32 64; do 
	for each in 16; do
	#export LD_PRELOAD=/ssd/NVM/appbench/shared_libs/construct/libmigration.so
	$PREFIX sysbench $MYSQL_OPTIONS --threads=$each /usr/share/sysbench/oltp_read_only.lua run; sleep 5;
	export LD_PRELOAD=""
	done
}


#Run write only
WRITE_ONLY() {
	for each in 1 2 4 8 16 32 64; do
	#export LD_PRELOAD=/ssd/NVM/appbench/shared_libs/construct/libmigration.so
	$PREFIX sysbench $MYSQL_OPTIONS --threads=$each /usr/share/sysbench/oltp_write_only.lua run; sleep 5;
	export LD_PRELOAD=""
	done
}

#Run read-write
READ_WRITE() {
	#for each in 1 2 4 8 16 32 64; do
	for each in 32; do
	#export LD_PRELOAD=/ssd/NVM/appbench/shared_libs/construct/libmigration.so
	$PREFIX sysbench $MYSQL_OPTIONS --threads=$each /usr/share/sysbench/oltp_read_write.lua run; sleep 5;
	export LD_PRELOAD=""
	done
}

#CREATE_DB
#PREPARE_SYSBENCH
#exit

#READ_ONLY
#WRITE_ONLY
READ_WRITE

exit
