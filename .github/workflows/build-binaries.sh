#!/bin/bash
set -x -e
DEBUG=$1  # Value is '' or 'debug'
RUNNER_OS=$2  #  ${{ runner.os }} is Linux, Windiws, maxOS
prefix=/tmp/ADALIB_DIR

if [ $RUNNER_OS = Windows ]; then
    prefix=/opt/ADALIB_DIR
    mount `cmd /c cd | cut -d\: -f1`:/opt /opt
fi

export GPR_PROJECT_PATH=$prefix/share/gpr:\
$PWD/subprojects/VSS/gnat:\
$PWD/subprojects/markdown/gnat:\
$PWD/subprojects/gpr-unit-provider

export CPATH=/usr/local/include:/mingw64/include
export LIBRARY_PATH=/usr/local/lib:/mingw64/lib
export DYLD_LIBRARY_PATH=/usr/local/lib
export PATH=`ls -d $PWD/cached_gnat/*/bin |tr '\n' ':'`$PATH
echo PATH=$PATH

BRANCH=master

# Get libadalang binaries
mkdir -p $prefix
FILE=libadalang-$RUNNER_OS-$BRANCH${DEBUG:+-dbg}-static.tar.gz
aws s3 cp s3://adacore-gha-tray-eu-west-1/libadalang/$FILE . --sse=AES256
tar xzf $FILE -C $prefix
rm -f -v $FILE

if [ "$DEBUG" = "debug" ]; then
    export BUILD_MODE=dev
else
    export BUILD_MODE=prod
fi

pip install --user subprojects/langkit/

# Python used in GitHub CI on Windows can't understand
# make's notation of absolute path in form of /d/PATH,
# where /d is drive D: Let's use relative path instead
sed -i -e '/langkit/s/.{CURDIR}/../' subprojects/gpr/Makefile

make -C subprojects/gpr setup prefix=$prefix \
 GPR2KBDIR=./gprconfig_kb/db ENABLE_SHARED=no \
 ${DEBUG:+BUILD=debug} build-lib-static install-lib-static

make

tar cfz gnatdoc-$RUNNER_OS.tar.gz bin share
