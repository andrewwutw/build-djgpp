#!/usr/bin/env bash

source script/init.sh

PACKAGE_SOURCES="ia16 binutils"
source script/parse-args.sh

TARGET="ia16-elf"

prepend BINUTILS_CONFIGURE_OPTIONS "--disable-werror
                                    --disable-nls"

prepend GCC_CONFIGURE_OPTIONS "--disable-nls
                               --enable-fat"

prepend GDB_CONFIGURE_OPTIONS "--disable-werror
                               --disable-nls"

prepend NEWLIB_CONFIGURE_OPTIONS "--enable-newlib-nano-malloc
                                  --disable-newlib-multithread"

DEPS=""
[ ! -z ${GCC_VERSION} ] && DEPS+=" newlib binutils"
[ ! -z ${NEWLIB_VERSION} ] && DEPS+=" gcc binutils"

source ${BASE}/script/download.sh

source ${BASE}/script/build-tools.sh

cd ${BASE}/build/ || exit 1

if [ ! -z ${GCC_VERSION} ]; then
  download_git https://github.com/tkchia/gcc-ia16.git gcc-6_3_0-ia16-tkchia
  cd gcc-ia16/
  patch -p1 -u < ../../patch/patch-gcc-ia16.txt || exit 1
  cd ..
fi

if [ ! -z ${NEWLIB_VERSION} ]; then
  download_git https://github.com/tkchia/newlib-ia16.git newlib-2_4_0-ia16-tkchia
fi

if [ "$BINUTILS_VERSION" = "ia16" ]; then
  download_git https://github.com/tkchia/binutils-ia16.git binutils-ia16-tkchia
  cd binutils-${BINUTILS_VERSION} || exit 1
  source ${BASE}/script/build-binutils.sh
else
  source ${BASE}/script/unpack-build-binutils.sh
fi

source ${BASE}/script/build-newlib-gcc.sh

source ${BASE}/script/build-gdb.sh

source ${BASE}/script/finalize.sh
