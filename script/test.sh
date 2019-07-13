#!/usr/bin/env bash
set -e

PREFIX="`pwd`/install"

[ $TRAVIS_OS_NAME = 'linux' ] && MAKE_JOBS=`nproc`
[ $TRAVIS_OS_NAME = 'osx' ] && MAKE_JOBS=`sysctl -n hw.ncpu`
MAKE_JOBS+=" --quiet"

CFLAGS="-w"
CXXFLAGS="-w"

export PREFIX MAKE_JOBS CFLAGS CXXFLAGS

case $TARGET in
*-msdosdjgpp) SCRIPT=./build-djgpp.sh ;;
ia16*)        SCRIPT=./build-ia16.sh ;;
avr)          SCRIPT=./build-avr.sh ;;
*)            SCRIPT=./build-newlib.sh ;;
esac

echo | ${SCRIPT} ${PACKAGES}
