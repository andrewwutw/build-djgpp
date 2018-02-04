#!/usr/bin/env bash

source script/functions.sh

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
  if [ ! -x newlib/$1 ] && [ ! -x common/$1 ]; then
    echo "Unsupported package: $1"
    exit 1
  fi

  [ -e newlib/$1 ] && source newlib/$1 || source common/$1
  shift
done

DEPS=""

if [ -z ${IGNORE_DEPENDENCIES} ]; then
  [ ! -z ${GCC_VERSION} ] && DEPS+=" binutils"
  [ ! -z ${BINUTILS_VERSION} ] && DEPS+=" "
  [ ! -z ${GDB_VERSION} ] && DEPS+=" "
  
  for DEP in ${DEPS}; do
    case $DEP in
      binutils)
        [ -z "`ls ${PREFIX}/${TARGET}/etc/binutils-*-installed 2> /dev/null`" ] \
          && [ -z ${BINUTILS_VERSION} ] \
          && source newlib/binutils
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

source ${BASE}/script/begin.sh

source ${BASE}/script/build-tools.sh

cd ${BASE}/build/ || exit 1

if [ ! -z ${BINUTILS_VERSION} ]; then
  echo "Building binutils"
  if [ ! -e binutils-${BINUTILS_VERSION}/binutils-unpacked ]; then
    untar binutils-${BINUTILS_VERSION} || exit 1
    touch binutils-${BINUTILS_VERSION}/binutils-unpacked
  fi
  
  cd binutils-${BINUTILS_VERSION} || exit 1

  source ${BASE}/script/build-binutils.sh
fi

cd ${BASE}/build/

if [ ! -z ${GCC_VERSION} ]; then
  if [ ! -e gcc-${GCC_VERSION}/gcc-unpacked ]; then
    untar gcc-${GCC_VERSION}

    # download mpc/gmp/mpfr/isl libraries
    echo "Downloading gcc dependencies"
    cd gcc-${GCC_VERSION}/
    ./contrib/download_prerequisites
    touch gcc-unpacked
    cd -
  else
    echo "gcc already unpacked, skipping."
  fi

  echo "Building gcc"

  mkdir -p gcc-${GCC_VERSION}/build-${TARGET}
  cd gcc-${GCC_VERSION}/build-${TARGET} || exit 1

  TEMP_CFLAGS="$CFLAGS"
  export CFLAGS="$CFLAGS $GCC_EXTRA_CFLAGS"

  GCC_CONFIGURE_OPTIONS+=" --target=${TARGET} --prefix=${PREFIX}
                           --enable-languages=${ENABLE_LANGUAGES}"
  GCC_CONFIGURE_OPTIONS="`echo ${GCC_CONFIGURE_OPTIONS}`"

  if [ ! -e configure-prefix ] || [ ! `cat configure-prefix` = "${PREFIX}" ]; then
    rm -rf *
    ../configure ${GCC_CONFIGURE_OPTIONS} || exit 1
    echo ${PREFIX} > configure-prefix
  else
    echo "Note: gcc already configured. To force a rebuild, use: rm -rf $(pwd)"
    sleep 5
  fi

  ${MAKE} -j${MAKE_JOBS} || exit 1
  [ ! -z $MAKE_CHECK ] && ${MAKE} -j${MAKE_JOBS} -s check | tee ${BASE}/tests/gcc.log
  ${MAKE} -j${MAKE_JOBS} install-strip || exit 1

  export CFLAGS="$TEMP_CFLAGS"
fi

cd ${BASE}/build

source ${BASE}/script/build-gdb.sh

source ${BASE}/script/finalize.sh
