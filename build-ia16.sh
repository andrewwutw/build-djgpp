#!/usr/bin/env bash

source script/init.sh

TARGET="ia16-elf"

prepend BINUTILS_CONFIGURE_OPTIONS "--disable-werror
                                    --disable-nls"

prepend GCC_CONFIGURE_OPTIONS "--disable-nls
                               --enable-fat"

prepend GDB_CONFIGURE_OPTIONS "--disable-werror
                               --disable-nls"

prepend NEWLIB_CONFIGURE_OPTIONS "--enable-newlib-nano-malloc
                                  --disable-newlib-multithread"

if [ -z ${TARGET} ]; then
  echo "Please specify a target with: export TARGET=..."
  exit 1
fi

if [ -z $1 ]; then
  echo "Usage: $0 [packages...]"
  echo "Supported packages:"
  ls ia16/
  ls binutils/
  exit 1
fi

while [ ! -z $1 ]; do
  if [ -e ia16/$1 ]; then
    source ia16/$1
  elif [ -e binutils/$1 ]; then
    source binutils/$1
  else
    echo "Unsupported package: $1"
    exit 1
  fi
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

source ${BASE}/script/download.sh

source ${BASE}/script/build-tools.sh

cd ${BASE}/build/ || exit 1

echo "Downloading gcc..."
[ -d gcc-ia16 ] || git clone https://github.com/tkchia/gcc-ia16.git --depth 1 --branch gcc-6_3_0-ia16-tkchia
cd gcc-ia16
git reset --hard HEAD
git pull || exit 1
cd ..

echo "Downloading newlib..."
[ -d newlib-ia16 ] || git clone https://github.com/tkchia/newlib-ia16.git --depth 1 --branch newlib-2_4_0-ia16-tkchia
cd newlib-ia16
git reset --hard HEAD
git pull || exit 1
cd ..

if [ ! -z ${BINUTILS_VERSION} ]; then
  if [ "$BINUTILS_VERSION" = "ia16" ]; then
    echo "Downloading binutils..."
    [ -d binutils-ia16 ] || git clone https://github.com/tkchia/binutils-ia16.git --depth 1 --branch binutils-ia16-tkchia
    cd binutils-ia16
    git reset --hard HEAD
    git pull || exit 1
    cd ..
  elif [ ! -e binutils-${BINUTILS_VERSION}/binutils-unpacked ]; then
    echo "Unpacking binutils..."
    untar ${BINUTILS_ARCHIVE} || exit 1
    touch binutils-${BINUTILS_VERSION}/binutils-unpacked
  fi

  cd binutils-${BINUTILS_VERSION} || exit 1
  source ${BASE}/script/build-binutils.sh
fi

source ${BASE}/script/build-newlib-gcc.sh

source ${BASE}/script/build-gdb.sh

source ${BASE}/script/finalize.sh
