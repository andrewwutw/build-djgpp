if [ -z ${NO_DOWNLOAD} ]; then
  # MinGW32 doesn't have curl, so we use wget.
  if ! which curl > /dev/null; then
    USE_WGET=1
    if ! which wget > /dev/null; then
      echo "curl or wget not installed"
      exit 1
    fi
  fi
fi

[ ! -z ${ONLY_DOWNLOAD} ] && return

if [ -z ${TARGET} ]; then
  echo "Please specify a target with: export TARGET=..."
  exit 1
fi

if [ -z ${IGNORE_DEPENDENCIES} ]; then
  for DEP in ${DEPS}; do
    case $DEP in
      djgpp)
        [ -z ${DJGPP_VERSION} ] \
          && add_pkg djgpp
        ;;
      newlib)
        [ -z ${NEWLIB_VERSION} ] \
          && add_pkg newlib
        ;;
      avr-libc)
        [ -z ${AVRLIBC_VERSION} ] \
          && add_pkg avr-libc
        ;;
      binutils)
        [ -z "`ls ${PREFIX}/${TARGET}/etc/binutils-*-installed 2> /dev/null`" ] \
          && [ -z ${BINUTILS_VERSION} ] \
          && add_pkg binutils
        ;;
      gcc)
        [ -z "`ls ${PREFIX}/${TARGET}/etc/gcc-*-installed 2> /dev/null`" ] \
          && [ -z ${GCC_VERSION} ] \
          && add_pkg gcc
        ;;
      gdb)
        [ -z "`ls ${PREFIX}/${TARGET}/etc/gdb-*-installed 2> /dev/null`" ] \
          && [ -z ${GDB_VERSION} ] \
          && add_pkg gdb
        ;;
    esac
  done
fi

# check required programs
REQ_PROG_LIST="${CXX} ${CC} unzip bison flex ${MAKE} makeinfo patch tar xz bunzip2 gunzip"

for REQ_PROG in $REQ_PROG_LIST; do
  if ! which $REQ_PROG > /dev/null; then
    echo "$REQ_PROG not installed"
    exit 1
  fi
done

# check GNU sed is installed or not.
# It is for OSX, which doesn't ship with GNU sed.
if ! sed --version 2>/dev/null | grep "GNU sed" > /dev/null ;then
  echo GNU sed is not installed, need to download.
  SED_VERSION=4.4
  SED_ARCHIVE="http://ftpmirror.gnu.org/sed/sed-${SED_VERSION}.tar.xz"
else
  SED_ARCHIVE=""
fi

# check zlib is installed
if ! ${CC} ${BASE}/script/test-zlib.c -o test-zlib -lz; then
  echo "zlib not installed"
  exit 1
fi
rm test-zlib 2>/dev/null
rm test-zlib.exe 2>/dev/null

echo "You are about to build and install:"
[ -z ${DJGPP_VERSION} ]    || echo "    - DJGPP libraries and utilities ${DJGPP_VERSION}"
[ -z ${NEWLIB_VERSION} ]   || echo "    - newlib ${NEWLIB_VERSION}"
[ -z ${BINUTILS_VERSION} ] || echo "    - binutils ${BINUTILS_VERSION}"
[ -z ${GCC_VERSION} ]      || echo "    - gcc ${GCC_VERSION}"
[ -z ${GDB_VERSION} ]      || echo "    - gdb ${GDB_VERSION}"
[ -z ${BUILD_DXEGEN} ]     || echo "    - DXE tools ${DJGPP_VERSION}"
[ -z ${AVRLIBC_VERSION} ]  || echo "    - avr-libc ${AVRLIBC_VERSION}"
[ -z ${AVRDUDE_VERSION} ]  || echo "    - AVRDUDE ${AVRDUDE_VERSION}"
[ -z ${AVARICE_VERSION} ]  || echo "    - AVaRICE ${AVARICE_VERSION}"
[ -z ${SIMULAVR_VERSION} ] || echo "    - SimulAVR ${SIMULAVR_VERSION}"

echo ""
echo "With the following options:"
[ ! -z ${IGNORE_DEPENDENCIES} ] && echo "    IGNORE_DEPENDENCIES=${IGNORE_DEPENDENCIES}"
echo "    TARGET=${TARGET}"
echo "    HOST=${HOST}"
echo "    BUILD=${BUILD}"
echo "    PREFIX=${PREFIX}"
echo "    CC=${CC}"
echo "    CXX=${CXX}"
echo "    CFLAGS=${CFLAGS}"
echo "    CXXFLAGS=${CXXFLAGS}"
echo "    CFLAGS_FOR_TARGET=${CFLAGS_FOR_TARGET}"
echo "    CXXFLAGS_FOR_TARGET=${CXXFLAGS_FOR_TARGET}"
echo "    LDFLAGS=${LDFLAGS}"
echo "    MAKE=${MAKE}"
echo "    MAKE_JOBS=${MAKE_JOBS}"
echo "    MAKE_CHECK=${MAKE_CHECK}"
echo "    MAKE_CHECK_GCC=${MAKE_CHECK_GCC}"
if [ ! -z ${HOST} ]; then
  echo "    HOST_CC=`echo ${HOST_CC}`"
  echo "    HOST_CXX=`echo ${HOST_CXX}`"
fi
if [ ! -z ${GCC_VERSION} ]; then
  echo "    ENABLE_LANGUAGES=${ENABLE_LANGUAGES}"
  echo "    GCC_CONFIGURE_OPTIONS=`echo ${GCC_CONFIGURE_OPTIONS}`"
fi
if [ ! -z ${BINUTILS_VERSION} ]; then
  echo "    BINUTILS_CONFIGURE_OPTIONS=`echo ${BINUTILS_CONFIGURE_OPTIONS}`"
fi
if [ ! -z ${GDB_VERSION} ]; then
  echo "    GDB_CONFIGURE_OPTIONS=`echo ${GDB_CONFIGURE_OPTIONS}`"
fi
if [ ! -z ${NEWLIB_VERSION} ]; then
  echo "    NEWLIB_CONFIGURE_OPTIONS=`echo ${NEWLIB_CONFIGURE_OPTIONS}`"
fi
if [ ! -z ${AVRLIBC_VERSION} ]; then
  echo "    AVRLIBC_CONFIGURE_OPTIONS=`echo ${AVRLIBC_CONFIGURE_OPTIONS}`"
fi
echo ""

mkdir -p ${PREFIX}

if [ ! -d ${PREFIX} ] || [ ! -w ${PREFIX} ]; then
  echo "WARNING: no write access to ${PREFIX}."
  echo "You may need to enter your sudo password several times during the build process."
  echo ""
  SUDO=sudo
fi

echo "If you wish to change anything, press CTRL-C now. Otherwise, press any other key to continue."
read -s -n 1
