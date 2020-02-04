#!/usr/bin/env bash
set -e

PREFIX="`pwd`/install"

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
