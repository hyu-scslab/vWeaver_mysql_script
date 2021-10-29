#!/bin/bash

# current directory path
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd)"
cd $DIR

BASE_DIR="$DIR""/../../../MySQL"
BUILD_DIR="$BASE_DIR""/build"

cd $BUILD_DIR

make -j80 --silent
make install --silent

cd $DIR
