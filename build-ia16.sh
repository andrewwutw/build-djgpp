#!/usr/bin/env bash

PACKAGE_SOURCES="ia16 binutils"
source script/init.sh

TARGET="ia16-elf"

prepend BINUTILS_CONFIGURE_OPTIONS "--disable-werror
                                    --disable-nls
                                    --disable-gdb
                                    --disable-sim
                                    --enable-x86-hpa-segelf=yes
                                    --enable-ld=default
                                    --enable-gold=yes"

prepend GCC_CONFIGURE_OPTIONS "--disable-nls
                               --enable-fat
                               --disable-libstdcxx-dual-abi
                               --disable-extern-template
                               --disable-wchar_t
                               --disable-libstdcxx-verbose"

prepend GDB_CONFIGURE_OPTIONS "--disable-werror
                               --disable-nls"

prepend NEWLIB_CONFIGURE_OPTIONS "--enable-newlib-elix-level=2 --disable-elks-libc
                                  --disable-newlib-wide-orient --enable-newlib-nano-malloc
                                  --disable-newlib-multithread --enable-newlib-global-atexit
                                  --enable-newlib-reent-small --disable-newlib-fseek-optimization
                                  --disable-newlib-unbuf-stream-opt --enable-target-optspace
                                  --enable-newlib-io-c99-formats --enable-newlib-mb --enable-newlib-iconv
                                  --enable-newlib-iconv-encodings=utf_8,utf_16,cp850,cp852,koi8_uni"

DEPS=""
[ ! -z ${GCC_VERSION} ] && DEPS+=" newlib binutils"
[ ! -z ${NEWLIB_VERSION} ] && DEPS+=" gcc binutils"

source ${BASE}/script/check-deps-and-confirm.sh
source ${BASE}/script/download.sh
source ${BASE}/script/build-tools.sh

cd ${BASE}/build/ || exit 1
if [ "$BINUTILS_VERSION" = "ia16" ]; then
  cd binutils-${BINUTILS_VERSION} || exit 1
  source ${BASE}/script/build-binutils.sh
else
  source ${BASE}/script/unpack-build-binutils.sh
fi

if [ ! -z ${GCC_VERSION} ]; then
  cd ${BASE}/build/gcc-ia16/
  patch -p1 -u < ../../patch/patch-gcc-ia16.txt || exit 1
  cd -
fi

source ${BASE}/script/build-newlib-gcc.sh
source ${BASE}/script/build-gdb.sh
source ${BASE}/script/finalize.sh
