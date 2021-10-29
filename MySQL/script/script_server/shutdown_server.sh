#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd)"
cd $DIR

BASE_DIR="$DIR""/../../../MySQL"
DATA_DIR="$BASE_DIR""/data"
INST_DIR="$BASE_DIR""/inst"
CONF_DIR="$BASE_DIR""/conf"

cd $INST_DIR

./bin/mysqladmin --socket="$INST_DIR""/mysql.sock" -uroot shutdown

cd $DIR
