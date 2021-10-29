#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd)"
cd $DIR

BASE_DIR="$DIR""/../../../MySQL"
DATA_DIR="$BASE_DIR""/data"
INST_DIR="$BASE_DIR""/inst"
CONF_DIR="$BASE_DIR""/config"

# Initialize data directory
cd $BASE_DIR
rm -rf ./data/

cd $INST_DIR
rm -f ./logfile.err

# Initialize server
./bin/mysqld --defaults-file="$INST_DIR""/my.cnf" --initialize-insecure --datadir=$DATA_DIR

cd $DIR
