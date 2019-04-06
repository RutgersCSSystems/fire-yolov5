#!/bin/bash
set -x
SOCKETBENCH="$APPBENCH/apps/socket/"

#LD_PRELOAD=../../shared_libs/construct/libmigration.so ${@}

LD_PRELOAD=$SHARED_LIBS/construct/libmigration.so $APPPREFIX_SERVER $SOCKETBENCH/socket_server_multi & $APPPREFIX_CLIENT $SOCKETBENCH/socket_client_multi

#./socket_server_multi & ./socket_client_multi

