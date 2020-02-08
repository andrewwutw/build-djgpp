#!/usr/bin/env bash

source script/init.sh

PACKAGE_SOURCES="avr binutils common"
source script/parse-args.sh

TARGET="avr"

prepend BINUTILS_CONFIGURE_OPTIONS "--disable-werror
                                    --disable-nls"

prepend GCC_CONFIGURE_OPTIONS "--disable-nls
                               --enable-version-specific-runtime-libs
                               --enable-fat"

prepend GDB_CONFIGURE_OPTIONS "--disable-werror
                               --disable-nls"

prepend AVRLIBC_CONFIGURE_OPTIONS "--enable-device-lib"

DEPS=""
[ ! -z ${GCC_VERSION} ] && DEPS+=" avr-libc binutils"
[ ! -z ${AVRLIBC_VERSION} ] && DEPS+=" gcc binutils"

source ${BASE}/script/check-deps-and-confirm.sh
source ${BASE}/script/download.sh
source ${BASE}/script/mkdirs.sh
source ${BASE}/script/build-tools.sh
source ${BASE}/script/unpack-build-binutils.sh
source ${BASE}/script/build-avr-gcc.sh

cd ${BASE}/build/

if [ ! -z ${SIMULAVR_VERSION} ]; then
  echo "Building simulavr"
  cd simulavr/ || exit 1
  case `uname` in
  MINGW*) sed -i 's/CMAKE_CONFIG_OPTS=/CMAKE_CONFIG_OPTS=-G "MSYS Makefiles" /' Makefile ;;
  esac
  sed -i "s/-DCMAKE_INSTALL_PREFIX=/-DCMAKE_INSTALL_PREFIX=${PREFIX} #/" Makefile
  sed -i 's/\/bin\///' cmake/GetGitInfo.cmake
  ${MAKE} -j${MAKE_JOBS} build || exit 1
  ${MAKE} -j${MAKE_JOBS} doc || exit 1
  [ ! -z $MAKE_CHECK ] && ${MAKE} -j${MAKE_JOBS} -s check | tee ${BASE}/tests/simulavr.log
  echo "Installing simulavr"
  ${SUDO} ${MAKE} -C build install || exit 1
  cd ${BASE}/build/ || exit 1
fi

if [ ! -z ${AVARICE_VERSION} ]; then
  echo "Building AVaRICE"
  untar ${AVARICE_ARCHIVE}
  cd avarice-${AVARICE_VERSION}
  [ -e ${BASE}/patch/patch-avarice-${AVARICE_VERSION}.txt ] && patch -p1 -u < ${BASE}/patch/patch-avarice-${AVARICE_VERSION}.txt || exit 1
  mkdir -p build-avr/
  cd build-avr/ || exit 1
  rm -rf *
  ../configure --prefix=${PREFIX} || exit 1
  ${MAKE} -j${MAKE_JOBS} || exit 1
  [ ! -z $MAKE_CHECK ] && ${MAKE} -j${MAKE_JOBS} -s check | tee ${BASE}/tests/avarice.log
  echo "Installing AVaRICE"
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
  echo "Installing AVRDUDE"
  ${SUDO} ${MAKE} -j${MAKE_JOBS} install || exit 1
  cd ${BASE}/build/ || exit 1
fi

source ${BASE}/script/build-gdb.sh
source ${BASE}/script/finalize.sh
