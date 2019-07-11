#!/usr/bin/env bash

source script/init.sh

TARGET="avr"

prepend BINUTILS_CONFIGURE_OPTIONS "--disable-werror
                                    --disable-nls"

prepend GCC_CONFIGURE_OPTIONS "--disable-nls
                               --enable-version-specific-runtime-libs
                               --enable-fat"

prepend GDB_CONFIGURE_OPTIONS "--disable-werror
                               --disable-nls"

prepend AVRLIBC_CONFIGURE_OPTIONS "--enable-device-lib"

if [ -z $1 ]; then
  echo "Usage: $0 [packages...]"
  echo "Supported packages:"
  ls avr/
  ls binutils/
  ls common/
  exit 1
fi

while [ ! -z $1 ]; do
  if [ -e avr/$1 ]; then
    source avr/$1
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
  [ ! -z ${GCC_VERSION} ] && DEPS+=" avr-libc binutils"
  [ ! -z ${BINUTILS_VERSION} ] && DEPS+=" "
  [ ! -z ${GDB_VERSION} ] && DEPS+=" "
  [ ! -z ${AVRLIBC_VERSION} ] && DEPS+=" gcc binutils"
  [ ! -z ${AVRDUDE_VERSION} ] && DEPS+=" "
  [ ! -z ${AVARICE_VERSION} ] && DEPS+=" "
  [ ! -z ${SIMULAVR_VERSION} ] && DEPS+=" "
  
  for DEP in ${DEPS}; do
    case $DEP in
      avr-libc)
        [ -z ${AVRLIBC_VERSION} ] \
          && source avr/avr-libc
        ;;
      binutils)
        [ -z "`ls ${PREFIX}/${TARGET}/etc/binutils-*-installed 2> /dev/null`" ] \
          && [ -z ${BINUTILS_VERSION} ] \
          && source binutils/binutils
        ;;
      gcc)
        [ -z "`ls ${PREFIX}/${TARGET}/etc/gcc-*-installed 2> /dev/null`" ] \
          && [ -z ${GCC_VERSION} ] \
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

if [ ! -z ${SIMULAVR_VERSION} ]; then
  [ -d simulavr ] || git clone https://git.savannah.nongnu.org/git/simulavr.git --depth 1 --branch master
  cd simulavr
  git reset --hard HEAD
  git pull || exit 1
  cd ..
fi

if [ ! -z ${BINUTILS_VERSION} ]; then
  echo "Building binutils"
  if [ ! -e binutils-${BINUTILS_VERSION}/binutils-unpacked ]; then
    untar ${BINUTILS_ARCHIVE} || exit 1
    touch binutils-${BINUTILS_VERSION}/binutils-unpacked
  fi

  cd binutils-${BINUTILS_VERSION} || exit 1
  source ${BASE}/script/build-binutils.sh
fi

source ${BASE}/script/build-avr-gcc.sh

if [ ! -z ${SIMULAVR_VERSION} ]; then
  echo "Building SimulAVR"
  cd simulavr/ || exit 1
  ./bootstrap || exit 1
  #mkdir -p build-avr/
  #cd build-avr/ || exit 1
  make distclean
  ./configure --prefix=${PREFIX} || exit 1
  ${MAKE} -j${MAKE_JOBS} || exit 1
  [ ! -z $MAKE_CHECK ] && ${MAKE} -j${MAKE_JOBS} -s check | tee ${BASE}/tests/simulavr.log
  ${SUDO} ${MAKE} -j${MAKE_JOBS} install || exit 1
  cd ${BASE}/build/ || exit 1
fi

if [ ! -z ${AVARICE_VERSION} ]; then
  echo "Building AVaRICE"
  untar ${AVARICE_ARCHIVE}
  cd avarice-${AVARICE_VERSION}
  mkdir -p build-avr/
  cd build-avr/ || exit 1
  rm -rf *
  ../configure --prefix=${PREFIX} || exit 1
  ${MAKE} -j${MAKE_JOBS} || exit 1
  [ ! -z $MAKE_CHECK ] && ${MAKE} -j${MAKE_JOBS} -s check | tee ${BASE}/tests/avarice.log
  ${SUDO} ${MAKE} -j${MAKE_JOBS} install || exit 1
  cd ${BASE}/build/ || exit 1
fi

if [ ! -z ${AVRDUDE_VERSION} ]; then
  echo "Building AVRDUDE"
  untar ${AVRDUDE_ARCHIVE}
  cd avrdude-${AVRDUDE_VERSION}
  mkdir -p build-avr/
  cd build-avr/ || exit 1
  rm -rf *
  ../configure --prefix=${PREFIX} || exit 1
  ${MAKE} -j${MAKE_JOBS} || exit 1
  [ ! -z $MAKE_CHECK ] && ${MAKE} -j${MAKE_JOBS} -s check | tee ${BASE}/tests/avrdude.log
  ${SUDO} ${MAKE} -j${MAKE_JOBS} install || exit 1
  cd ${BASE}/build/ || exit 1
fi

source ${BASE}/script/build-gdb.sh

source ${BASE}/script/finalize.sh
