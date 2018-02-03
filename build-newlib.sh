#!/usr/bin/env bash

unset CDPATH

# target directory
PREFIX=${PREFIX-/usr/local/cross}

# enabled languages
#ENABLE_LANGUAGES=${ENABLE_LANGUAGES-c,c++,f95,objc,obj-c++}
ENABLE_LANGUAGES=${ENABLE_LANGUAGES-c,c++}

# number of parallel build threads
MAKE_JOBS=${MAKE_JOBS-4}

BASE=`pwd`

if [ -z $1 ]; then
  echo "Usage: $0 [packages...]"
  echo "Supported packages:"
  ls newlib/
  ls script/
  exit 1
fi

while [ ! -z $1 ]; do
  if [ ! -x newlib/$1 ] && [ ! -x script/$1 ]; then
    echo "Unsupported package: $1"
    exit 1
  fi

  ([ -e newlib/$1 ] && source newlib/$1) || source script/$1
  shift
done

DEPS=""

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
        && source newlib/binutils
      ;;
    gcc)
      [ -z ${GCC_VERSION} ] \
        && source script/gcc
      ;;
    gdb)
      [ -z "`ls ${PREFIX}/${TARGET}/etc/gdb-*-installed 2> /dev/null`" ] \
        && [ -z ${GDB_VERSION} ] \
        && source script/gdb
      ;;
  esac
done

source script/begin.sh

source script/build-tools.sh

if [ ! -z ${BINUTILS_VERSION} ]; then
  echo "Building binutils"
  if [ ! -e binutils-${BINUTILS_VERSION}/binutils-unpacked ]; then
    untar binutils-${BINUTILS_VERSION} || exit 1
    touch binutils-unpacked
  fi
  
  cd binutils-${BINUTILS_VERSION} || exit 1

  source script/build-binutils.sh
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
  
  cd gcc-${GCC_VERSION}/

  echo "Building gcc"

  mkdir -p build-${TARGET}
  cd build-${TARGET} || exit 1

  TEMP_CFLAGS="$CFLAGS"
  export CFLAGS="$CFLAGS $GCC_EXTRA_CFLAGS"

  if [ ! -e gcc-configure-prefix ] || [ ! `cat gcc-configure-prefix` = "${PREFIX}" ]; then
    rm gcc-configure-prefix
    ${MAKE} distclean
    ../configure \
          --target=${TARGET} \
          --prefix=${PREFIX} \
          --disable-nls \
          --enable-libquadmath-support \
          --enable-version-specific-runtime-libs \
          --enable-languages=${ENABLE_LANGUAGES} \
          --enable-fat \
          ${GCC_CONFIGURE_OPTIONS} || exit 1
    echo ${PREFIX} > gcc-configure-prefix
  else
    echo "Note: gcc already configured. To force a rebuild, use: rm -rf $(pwd)"
    sleep 5
  fi

  ${MAKE} -j${MAKE_JOBS} || exit 1
  ${MAKE} -j${MAKE_JOBS} install-strip || exit 1

  rm ${PREFIX}/${TARGET}/etc/gcc-*-installed
  touch ${PREFIX}/${TARGET}/etc/gcc-${GCC_VERSION}-installed

  export CFLAGS="$TEMP_CFLAGS"
fi

if [ ! -z ${NEWLIB_VERSION} ]; then
    #TODO build newlib
fi

if [ ! -z ${GCC_VERSION} ]; then
    #TODO build gcc stage2
fi

cd ${BASE}/build

source script/build-gdb.sh

source script/finalize.sh
