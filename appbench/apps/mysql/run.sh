set -x
MYSQL_USER=root
MYSQL_PASSWD=password
PREFIX=numactl --membind=1

#CREATE sbtest DATABASE
CREATE_DB() {
	mysql -u root -p $MYSQL_PASSWD -e "CREATE DATABASE sbtest;"
	mysql -u root -p $MYSQL_PASSWD -e "CREATE USER sbtest@localhost;"
	mysql -u root -p $MYSQL_PASSWD -e "GRANT ALL PRIVILEGES ON sbtest.* TO sbtest@localhost;"
}

#Prepare sysbench
PREPARE_SYSBENCH() {
	sysbench --db-driver=mysql --mysql-user=$MYSQL_USER --mysql-password=$MYSQL_PASSWD --mysql-db=sbtest --table_size=10000000 --threads=16 /usr/share/sysbench/oltp_read_only.lua prepare
}

#CREATE_DB
#PREPARE_SYSBENCH

#Run read only
for each in 1 2 4 8 16 32 64; do 
export LD_PRELOAD=$SHARED_LIBS/construct/libmigration.so
$PREFIX sysbench --db-driver=mysql --mysql-user=$MYSQL_USER --mysql-password=$MYSQL_PASSWD --mysql-db=sbtest --table_size=10000000 --events=0 --time=60  --threads=$each /usr/share/sysbench/oltp_read_only.lua run; sleep 5;
export LD_PRELOAD=""
done


#Run write only
for each in 1 2 4 8 16 32 64; do
export LD_PRELOAD=$SHARED_LIBS/construct/libmigration.so
$PREFIX sysbench --db-driver=mysql --mysql-user=$MYSQL_USER --mysql-password=$MYSQL_PASSWD --mysql-db=sbtest --table_size=10000000 --events=0 --time=60  --threads=$each /usr/share/sysbench/oltp_write_only.lua run; sleep 5;
export LD_PRELOAD=""
done

#Run read-write
for each in 1 2 4 8 16 32 64; do
export LD_PRELOAD=$SHARED_LIBS/construct/libmigration.so
$PREFIX sysbench --db-driver=mysql --mysql-user=$MYSQL_USER --mysql-password=$MYSQL_PASSWD --mysql-db=sbtest --table_size=10000000 --events=0 --time=60  --threads=$each /usr/share/sysbench/oltp_read_write.lua run; sleep 5;
export LD_PRELOAD=""
done

exit
