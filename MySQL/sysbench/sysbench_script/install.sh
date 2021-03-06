#!/bin/bash

# Change to this-file-exist-path.
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"/
cd $DIR

# Default
BASE_DIR="$DIR""../sysbench/"

# Parse parameters.
for i in "$@"
do
case $i in
    -b=*|--base_dir=*)
    BASE_DIR="${i#*=}"
    shift
    ;;

    *)
          # unknown option
    ;;
esac
done

cd $BASE_DIR
make clean -j40 --silent

./autogen.sh
./configure --silent
make -j40 --silent

cd $DIR


