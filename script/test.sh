#!/usr/bin/env bash
set -e

case $TARGET in
*-msdosdjgpp) SCRIPT=./build-djgpp.sh ;;
ia16*)        SCRIPT=./build-ia16.sh ;;
avr)          SCRIPT=./build-avr.sh ;;
*)            SCRIPT=./build-newlib.sh ;;
esac

${SCRIPT} --batch --prefix=`pwd`/install --target=${TARGET} ${PACKAGES}
