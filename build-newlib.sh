#!/usr/bin/env bash

PACKAGE_SOURCES="newlib binutils common"
source script/init.sh

prepend BINUTILS_CONFIGURE_OPTIONS "--disable-werror
                                    --disable-nls"

prepend GCC_CONFIGURE_OPTIONS "--disable-nls
                               --enable-libquadmath-support
                               --enable-version-specific-runtime-libs
                               --enable-fat"

prepend GDB_CONFIGURE_OPTIONS "--disable-werror
                               --disable-nls"

DEPS=""
[ ! -z ${GCC_VERSION} ] && DEPS+=" newlib binutils"
[ ! -z ${NEWLIB_VERSION} ] && DEPS+=" gcc binutils"

source ${BASE}/script/check-deps-and-confirm.sh
source ${BASE}/script/download.sh
source ${BASE}/script/build-tools.sh
source ${BASE}/script/unpack-build-binutils.sh
source ${BASE}/script/build-newlib-gcc.sh
source ${BASE}/script/build-gdb.sh
source ${BASE}/script/finalize.sh
