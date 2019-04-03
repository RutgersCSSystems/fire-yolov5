#!/bin/bash

#LD_PRELOAD=../../shared_libs/construct/libmigration.so ${@}
#LD_PRELOAD=../../shared_libs/construct/libmigration.so /usr/bin/time -v ./socket_server_multi & LD_PRELOAD=../../shared_libs/construct/libmigration.so /usr/bin/time -v ./socket_client_multi

./socket_server_multi & ./socket_client_multi
