#!/usr/bin/env bash
DIR=$1
shift
GCC=$1
shift
${GCC} -B${DIR}/lib/ -isystem ${DIR}/include/ -isystem ${DIR}/sys-include/ "$@"
exit $?
