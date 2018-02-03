# use gmake/clang under FreeBSD
if [ `uname` = "FreeBSD" ]; then
  MAKE=${MAKE-gmake}
  CC=${CC-clang}
  CXX=${CXX-clang++}
else
  MAKE=${MAKE-make}
  CC=${CC-gcc}
  CXX=${CXX-g++}
fi

export CC CXX MAKE

echo "You are about to build and install:"
[ -z ${DJGPP_VERSION} ]    || echo "    - DJGPP base library ${DJGPP_VERSION}"
[ -z ${NEWLIB_VERSION} ]   || echo "    - newlib ${NEWLIB_VERSION}"
[ -z ${BINUTILS_VERSION} ] || echo "    - binutils ${BINUTILS_VERSION}"
[ -z ${GCC_VERSION} ]      || echo "    - gcc ${GCC_VERSION}"
[ -z ${GDB_VERSION} ]      || echo "    - gdb ${GDB_VERSION}"
[ -z ${BUILD_DXEGEN} ]     || echo "    - DXE tools ${DJGPP_VERSION}"
echo ""
echo "With the following options:"
echo "    TARGET=${TARGET}"
echo "    PREFIX=${PREFIX}"
echo "    CC=${CC}"
echo "    CXX=${CXX}"
echo "    CFLAGS=${CFLAGS}"
echo "    CXXFLAGS=${CXXFLAGS}"
echo "    LDFLAGS=${LDFLAGS}"
echo "    MAKE=${MAKE}"
echo "    MAKE_JOBS=${MAKE_JOBS}"
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
echo ""
echo "If you wish to change anything, press CTRL-C now. Otherwise, press any other key to continue."
read -s -n 1

# check required programs
REQ_PROG_LIST="${CXX} ${CC} unzip bison flex ${MAKE} makeinfo patch"

# MinGW doesn't have curl, so we use wget.
if ! which curl > /dev/null; then
  USE_WGET=1
fi

# use curl or wget?
if [ ! -z $USE_WGET ]; then
  REQ_PROG_LIST+=" wget"
else
  REQ_PROG_LIST+=" curl"
fi

for REQ_PROG in $REQ_PROG_LIST; do
  if ! which $REQ_PROG > /dev/null; then
    echo "$REQ_PROG not installed"
    exit 1
  fi
done

# check GNU sed is installed or not.
# It is for OSX, which doesn't ship with GNU sed.
if ! sed --version 2>/dev/null |grep "GNU sed" > /dev/null ;then
  echo GNU sed is not installed, need to download.
  SED_VERSION=4.4
  SED_ARCHIVE="http://ftpmirror.gnu.org/sed/sed-${SED_VERSION}.tar.xz"
else
  SED_ARCHIVE=""
fi

# check for GNU tar and download if necessary.
if ! tar --version 2>/dev/null |grep "GNU tar" > /dev/null ;then
  echo GNU tar is not installed, need to download.
  TAR_VERSION=1.30
  TAR_ARCHIVE="http://ftpmirror.gnu.org/tar/tar-${TAR_VERSION}.tar.xz"
else
  TAR_ARCHIVE=""
fi

# check zlib is installed
if ! ${CC} test-zlib.c -o test-zlib -lz; then
  echo "zlib not installed"
  exit 1
fi
rm test-zlib 2>/dev/null
rm test-zlib.exe 2>/dev/null

if [ ! -z ${GCC_VERSION} ]; then
  DJCROSS_GCC_ARCHIVE="${DJGPP_DOWNLOAD_BASE}/djgpp/rpms/djcross-gcc-${GCC_VERSION}/djcross-gcc-${GCC_VERSION}.tar.bz2"
  # djcross-gcc-X.XX-tar.* maybe moved from /djgpp/rpms/ to /djgpp/deleted/rpms/ directory.
  OLD_DJCROSS_GCC_ARCHIVE=${DJCROSS_GCC_ARCHIVE/rpms\//deleted\/rpms\/}
fi

# download source files
ARCHIVE_LIST="$BINUTILS_ARCHIVE $DJCRX_ARCHIVE $DJLSR_ARCHIVE $DJDEV_ARCHIVE
              $SED_ARCHIVE $DJCROSS_GCC_ARCHIVE $OLD_DJCROSS_GCC_ARCHIVE $GCC_ARCHIVE
              $AUTOCONF_ARCHIVE $AUTOMAKE_ARCHIVE $GDB_ARCHIVE $TAR_ARCHIVE"

echo "Download source files..."
mkdir -p download || exit 1
cd download

for ARCHIVE in $ARCHIVE_LIST; do
  FILE=`basename $ARCHIVE`
  if ! [ -f $FILE ]; then
    echo "Download $ARCHIVE ..."
    if [ ! -z $USE_WGET ]; then
      DL_CMD="wget -U firefox $ARCHIVE"
    else
      DL_CMD="curl -f $ARCHIVE -L -o $FILE"
    fi
    echo "Command : $DL_CMD"
    if ! eval $DL_CMD; then
      if [ "$ARCHIVE" == "$DJCROSS_GCC_ARCHIVE" ]; then
        echo "$FILE maybe moved to deleted/ directory."
      else
        rm $FILE
        echo "Download $ARCHIVE failed."
        exit 1
      fi
    fi
  fi
done
cd ..

# create target directory, check writable.
echo "Make prefix directory : $PREFIX"
mkdir -p $PREFIX

if ! [ -d $PREFIX ]; then
  echo "Unable to create prefix directory"
  exit 1
fi

if ! [ -w $PREFIX ]; then
  echo "prefix directory is not writable."
  exit 1
fi

mkdir -p ${PREFIX}/${TARGET}/etc/ || exit 1

# make build dir
echo "Make build dir"
mkdir -p ${BASE}/build
mkdir -p ${BASE}/build/tmpinst
cd ${BASE}/build || exit 1
