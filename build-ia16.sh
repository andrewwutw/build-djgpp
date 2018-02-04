#!/usr/bin/env bash

unset CDPATH

# target directory
PREFIX=${PREFIX-/usr/local/cross}

# enabled languages
#ENABLE_LANGUAGES=${ENABLE_LANGUAGES-c,c++,f95,objc,obj-c++}
ENABLE_LANGUAGES=${ENABLE_LANGUAGES-c,c++}

# number of parallel build threads
MAKE_JOBS=${MAKE_JOBS-4}

TARGET="ia16-elf"

BINUTILS_CONFIGURE_OPTIONS="--disable-werror
                            --disable-nls
                            ${BINUTILS_CONFIGURE_OPTIONS}"

GCC_CONFIGURE_OPTIONS="--disable-nls
                       --enable-fat
                       ${GCC_CONFIGURE_OPTIONS}"

GDB_CONFIGURE_OPTIONS="--disable-werror
                       --disable-nls
                       ${GDB_CONFIGURE_OPTIONS}"

NEWLIB_CONFIGURE_OPTIONS="--enable-newlib-nano-malloc
                          --disable-newlib-multithread
                          ${NEWLIB_CONFIGURE_OPTIONS}"

BASE=`pwd`

if [ -z ${TARGET} ]; then
  echo "Please specify a target with: export TARGET=..."
  exit 1
fi

if [ -z $1 ]; then
  echo "Usage: $0 [packages...]"
  echo "Supported packages:"
  ls ia16/
  exit 1
fi

while [ ! -z $1 ]; do
  if [ ! -x ia16/$1 ]; then
    echo "Unsupported package: $1"
    exit 1
  fi

  [ -e ia16/$1 ] && source ia16/$1
  shift
done

if [ -z ${IGNORE_DEPENDENCIES} ]; then
  DEPS=""
  
  [ ! -z ${GCC_VERSION} ] && DEPS+=" newlib binutils"
  [ ! -z ${BINUTILS_VERSION} ] && DEPS+=" "
  [ ! -z ${GDB_VERSION} ] && DEPS+=" "
  [ ! -z ${NEWLIB_VERSION} ] && DEPS+=" gcc binutils"
  
  for DEP in ${DEPS}; do
    case $DEP in
      newlib)
        [ -z ${NEWLIB_VERSION} ] \
          && source ia16/newlib
        ;;
      binutils)
        [ -z "`ls ${PREFIX}/${TARGET}/etc/binutils-*-installed 2> /dev/null`" ] \
          && [ -z ${BINUTILS_VERSION} ] \
          && source ia16/binutils
        ;;
      gcc)
        [ -z ${GCC_VERSION} ] \
          && source ia16/gcc
        ;;
      gdb)
        [ -z "`ls ${PREFIX}/${TARGET}/etc/gdb-*-installed 2> /dev/null`" ] \
          && [ -z ${GDB_VERSION} ] \
          && source common/gdb
        ;;
    esac
  done
fi

source ${BASE}/script/begin.sh

source ${BASE}/script/build-tools.sh

cd ${BASE}/build/ || exit 1

[ -d gcc-ia16 ] || git clone https://github.com/tkchia/gcc-ia16.git --depth 1 --branch gcc-6_3_0-ia16-tkchia
cd gcc-ia16
git reset --hard HEAD
git pull || exit 1
patch -p1 -u < ${BASE}/patch/patch-gcc-ia16.txt || exit 1
cd ..

[ -d newlib-ia16 ] || git clone https://github.com/tkchia/newlib-ia16.git --depth 1 --branch newlib-2_4_0-ia16-tkchia
cd newlib-ia16
git reset --hard HEAD
git pull || exit 1
patch -p1 -u < ${BASE}/patch/patch-newlib-ia16.txt || exit 1
cd ..

#[ -d binutils-ia16 ] || git clone https://github.com/crtc-demos/binutils-ia16.git --depth 1 --branch master
#cd binutils-ia16 && git pull && cd .. || exit 1

if [ ! -z ${BINUTILS_VERSION} ]; then
  echo "Building binutils"
  if [ ! -e binutils-${BINUTILS_VERSION}/binutils-unpacked ]; then
    untar binutils-${BINUTILS_VERSION} || exit 1
    touch binutils-unpacked
  fi

  cd binutils-${BINUTILS_VERSION} || exit 1
  source ${BASE}/script/build-binutils.sh
fi

source ${BASE}/script/build-newlib-gcc.sh

source ${BASE}/script/build-gdb.sh

source ${BASE}/script/finalize.sh
