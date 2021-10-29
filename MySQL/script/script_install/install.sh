#!/bin/bash

# current directory path
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd)"
cd $DIR

BASE_DIR="$DIR""/../../../MySQL"
BUILD_DIR="$BASE_DIR""/build"

bash ./cmake_script.sh "${1}"

bash ./make_script.sh
