FILE=$1

cd $SHARED_LIBS/construct
cp "migration_"$1".c" migration.c
make clean 
make
sudo make install
