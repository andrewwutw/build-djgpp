#!/usr/bin/env bash

source script/init.sh

prepend BINUTILS_CONFIGURE_OPTIONS "--disable-werror
                                    --disable-nls"

prepend GCC_CONFIGURE_OPTIONS "--disable-nls
                               --enable-libquadmath-support
                               --enable-version-specific-runtime-libs
                               --enable-fat"

prepend GDB_CONFIGURE_OPTIONS "--disable-werror
                               --disable-nls"

if [ -z ${TARGET} ]; then
  echo "Please specify a target with: export TARGET=..."
  exit 1
fi

if [ -z $1 ]; then
  echo "Usage: $0 [packages...]"
  echo "Supported packages:"
  ls newlib/
  ls common/
  exit 1
fi

while [ ! -z $1 ]; do
  if [ -e newlib/$1 ]; then
    source newlib/$1
  elif [ -e binutils/$1 ]; then
    source binutils/$1
  elif [ -e common/$1 ]; then
    source common/$1
  else
    echo "Unsupported package: $1"
    exit 1
  fi
  shift
done

DEPS=""

if [ -z ${IGNORE_DEPENDENCIES} ]; then
  [ ! -z ${GCC_VERSION} ] && DEPS+=" newlib binutils"
  [ ! -z ${BINUTILS_VERSION} ] && DEPS+=" "
  [ ! -z ${GDB_VERSION} ] && DEPS+=" "
  [ ! -z ${NEWLIB_VERSION} ] && DEPS+=" gcc binutils"
  
  for DEP in ${DEPS}; do
    case $DEP in
      newlib)
        [ -z ${NEWLIB_VERSION} ] \
          && source newlib/newlib
        ;;
      binutils)
        [ -z "`ls ${PREFIX}/${TARGET}/etc/binutils-*-installed 2> /dev/null`" ] \
          && [ -z ${BINUTILS_VERSION} ] \
          && source binutils/binutils
        ;;
      gcc)
        [ -z ${GCC_VERSION} ] \
          && source common/gcc
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

if [ ! -z ${BINUTILS_VERSION} ]; then
  if [ ! -e binutils-${BINUTILS_VERSION}/binutils-unpacked ]; then
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
