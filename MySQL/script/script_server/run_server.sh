#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd)"
cd $DIR

BASE_DIR="$DIR""/../../../MySQL"
DATA_DIR="$BASE_DIR""/data"
INST_DIR="$BASE_DIR""/inst"
CONF_DIR="$BASE_DIR""/conf"

rm $BASE_DIR/logfile.err

cd $INST_DIR

ARGS="--defaults-file=$INST_DIR/my.cnf "
ARGS+="--log_error=$BASE_DIR/logfile.err "
ARGS+="--datadir=$DATA_DIR "
ARGS+="--user=root"
ARGS+="--flush "

(./bin/mysqld $ARGS &)

cd $DIR
