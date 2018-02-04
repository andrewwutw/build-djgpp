#!/usr/bin/env bash

unset CDPATH

# target directory
PREFIX=${PREFIX-/usr/local/ia16}

# enabled languages
#ENABLE_LANGUAGES=${ENABLE_LANGUAGES-c,c++,f95,objc,obj-c++}
ENABLE_LANGUAGES=${ENABLE_LANGUAGES-c,c++}

# number of parallel build threads
MAKE_JOBS=${MAKE_JOBS-4}

TARGET="ia16-none-elf"

BINUTILS_CONFIGURE_OPTIONS="--disable-werror
                            --disable-nls
                            ${BINUTILS_CONFIGURE_OPTIONS}"

GCC_CONFIGURE_OPTIONS="--disable-nls
                       --enable-libquadmath-support
                       --enable-version-specific-runtime-libs
                       --enable-fat
                       ${GCC_CONFIGURE_OPTIONS}"

GDB_CONFIGURE_OPTIONS="--disable-werror
                       --disable-nls
                       ${GDB_CONFIGURE_OPTIONS}"


BASE=`pwd`

if [ -z ${TARGET} ]; then
  echo "Please specify a target with: export TARGET=..."
  exit 1
fi

if [ -z $1 ]; then
  echo "Usage: $0 [packages...]"
  echo "Supported packages:"
  ls ia16/
  ls common/
  exit 1
fi

while [ ! -z $1 ]; do
  if [ ! -x ia16/$1 ]; then
    echo "Unsupported package: $1"
    exit 1
  fi

  [ -e ia16/$1 ] && source ia16/$1 || source common/$1
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
        && source ia16/newlib
      ;;
    binutils)
      [ -z "`ls ${PREFIX}/${TARGET}/etc/binutils-*-installed 2> /dev/null`" ] \
        && [ -z ${BINUTILS_VERSION} ] \
        && source newlib/binutils
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

source ${BASE}/script/begin.sh

source ${BASE}/script/build-tools.sh

cd ${BASE}/build/ || exit 1

[ -d gcc-ia16 ] || git clone https://github.com/tkchia/gcc-ia16.git --depth 1 --branch gcc-6_3_0-ia16-tkchia
cd gcc-ia16 && git pull && cd .. || exit 1

[ -d newlib-ia16 ] || git clone https://github.com/tkchia/newlib-ia16.git --depth 1 --branch newlib-2_4_0-ia16-tkchia
cd newlib-ia16 && git pull && cd .. || exit 1

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

cd ${BASE}/build/

if [ ! -z ${NEWLIB_VERSION} ] && [ ! -e newlib-${NEWLIB_VERSION}/newlib-unpacked ]; then
  untar newlib-${NEWLIB_VERSION}
  mkdir -p ${PREFIX}/${TARGET}/sys-include/
  cp -rv newlib-${NEWLIB_VERSION}/newlib/libc/include/* ${PREFIX}/${TARGET}/sys-include/ | exit 1
  touch newlib-${NEWLIB_VERSION}/newlib-unpacked
fi

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
                           --enable-languages=${ENABLE_LANGUAGES}
                           --with-newlib"
  GCC_CONFIGURE_OPTIONS="`echo ${GCC_CONFIGURE_OPTIONS}`"

  if [ ! -e configure-prefix ] || [ ! "`cat configure-prefix`" == "${GCC_CONFIGURE_OPTIONS}" ]; then
    rm -rf *
    ../configure ${GCC_CONFIGURE_OPTIONS} || exit 1
    echo ${GCC_CONFIGURE_OPTIONS} > configure-prefix
  else
    echo "Note: gcc already configured. To force a rebuild, use: rm -rf $(pwd)"
    sleep 5
  fi

  ${MAKE} -j${MAKE_JOBS} all-gcc || exit 1
  ${MAKE} -j${MAKE_JOBS} install-gcc || exit 1

  export CFLAGS="$TEMP_CFLAGS"
fi

cd ${BASE}/build/

if [ ! -z ${NEWLIB_VERSION} ]; then
  mkdir -p newlib-${NEWLIB_VERSION}/build-${TARGET}
  cd newlib-${NEWLIB_VERSION}/build-${TARGET} || exit 1
  
  NEWLIB_CONFIGURE_OPTIONS+=" --target=${TARGET} --prefix=${PREFIX}"
  NEWLIB_CONFIGURE_OPTIONS="`echo ${NEWLIB_CONFIGURE_OPTIONS}`"
  
  if [ ! -e configure-prefix ] || [ ! "`cat configure-prefix`" == "${NEWLIB_CONFIGURE_OPTIONS}" ]; then
    rm -rf *
    ../configure ${NEWLIB_CONFIGURE_OPTIONS} || exit 1
    echo ${NEWLIB_CONFIGURE_OPTIONS} > configure-prefix
  else
    echo "Note: newlib already configured. To force a rebuild, use: rm -rf $(pwd)"
    sleep 5
  fi
  
  ${MAKE} -j${MAKE_JOBS} || exit 1
  ${MAKE} -j${MAKE_JOBS} install || \
  ${MAKE} -j${MAKE_JOBS} install || exit 1
fi

cd ${BASE}/build/

if [ ! -z ${GCC_VERSION} ]; then
  cd gcc-${GCC_VERSION}/build-${TARGET} || exit 1
  
  ${MAKE} -j${MAKE_JOBS} || exit 1
  ${MAKE} -j${MAKE_JOBS} install-strip || exit 1
  
  rm ${PREFIX}/${TARGET}/etc/gcc-*-installed
  touch ${PREFIX}/${TARGET}/etc/gcc-${GCC_VERSION}-installed
fi

cd ${BASE}/build

source ${BASE}/script/build-gdb.sh

source ${BASE}/script/finalize.sh
