#!/usr/bin/env bash

unset CDPATH

# target directory
DJGPP_PREFIX=${DJGPP_PREFIX-/usr/local/djgpp}

# enabled languages
#ENABLE_LANGUAGES=${ENABLE_LANGUAGES-c,c++,f95,objc,obj-c++}
ENABLE_LANGUAGES=${ENABLE_LANGUAGES-c,c++}

# number of parallel build threads
MAKE_JOBS=${MAKE_JOBS-4}

#DJGPP_DOWNLOAD_BASE="ftp://ftp.delorie.com/pub"
export DJGPP_DOWNLOAD_BASE="http://www.delorie.com/pub"

BASE=`pwd`

if [ -z $1 ]; then
  echo "Usage: $0 [packages...]"
  echo "Supported packages:"
  for F in `(cd script/;echo *)`; do echo "  "$F; done
  exit 1
fi

while [ ! -z $1 ]; do
  if [ ! -x script/$1 ]; then
    echo "Unsupported package: $1"
    exit 1
  fi

  source script/$1
  shift
done

DEPS=""

[ ! -z ${GCC_VERSION} ] && DEPS+=" base binutils"
[ ! -z ${BINUTILS_VERSION} ] && DEPS+=" "
[ ! -z ${GDB_VERSION} ] && DEPS+=" "
[ ! -z ${DJGPP_VERSION} ] && DEPS+=" "
[ ! -z ${BUILD_DXEGEN} ] && DEPS+=" base binutils gcc"

for DEP in ${DEPS}; do
  case $DEP in
    base)
      [ -z ${DJGPP_VERSION} ] \
        && source script/base
      ;;
    binutils)
      [ -z "`ls ${DJGPP_PREFIX}/i586-pc-msdosdjgpp/etc/binutils-*-installed 2> /dev/null`" ] \
        && [ -z ${BINUTILS_VERSION} ] \
        && source script/binutils
      ;;
    gcc)
      [ -z "`ls ${DJGPP_PREFIX}/i586-pc-msdosdjgpp/etc/gcc-*-installed 2> /dev/null`" ] \
        && [ -z ${GCC_VERSION} ] \
        && source script/gcc
      ;;
    gdb)
      [ -z "`ls ${DJGPP_PREFIX}/i586-pc-msdosdjgpp/etc/gdb-*-installed 2> /dev/null`" ] \
        && [ -z ${GDB_VERSION} ] \
        && source script/gdb
      ;;
    dxegen)
      [ -z "`ls ${DJGPP_PREFIX}/i586-pc-msdosdjgpp/etc/dxegen-installed 2> /dev/null`" ] \
        && [ -z ${BUILD_DXEGEN} ] \
        && source script/dxegen
      ;;
  esac
done

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
[ -z ${DJGPP_VERSION} ] || echo "    - DJGPP base library ${DJGPP_VERSION}"
[ -z ${BINUTILS_VERSION} ] || echo "    - binutils ${BINUTILS_VERSION}"
[ -z ${GCC_VERSION} ] || echo "    - gcc ${GCC_VERSION}"
[ -z ${GDB_VERSION} ] || echo "    - gdb ${GDB_VERSION}"
[ -z ${BUILD_DXEGEN} ] || echo "    - DXE tools ${DJGPP_VERSION}"
echo ""
echo "With the following options:"
echo "    DJGPP_PREFIX=${DJGPP_PREFIX}"
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
              $AUTOCONF_ARCHIVE $AUTOMAKE_ARCHIVE $GDB_ARCHIVE"

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
echo "Make prefix directory : $DJGPP_PREFIX"
mkdir -p $DJGPP_PREFIX

if ! [ -d $DJGPP_PREFIX ]; then
  echo "Unable to create prefix directory"
  exit 1
fi

if ! [ -w $DJGPP_PREFIX ]; then
  echo "prefix directory is not writable."
  exit 1
fi

mkdir -p ${DJGPP_PREFIX}/i586-pc-msdosdjgpp/etc/ || exit 1

# make build dir
echo "Make build dir"
mkdir -p ${BASE}/build
cd build || exit 1

if [ ! -z ${BINUTILS_VERSION} ]; then
  echo "Building binutils"
  mkdir -p bnu${BINUTILS_VERSION}s
  cd bnu${BINUTILS_VERSION}s
  if [ ! -e binutils-unpacked ]; then
    unzip -o ../../download/bnu${BINUTILS_VERSION}s.zip || exit 1

    # patch for binutils 2.27
    [ ${BINUTILS_VERSION} == 227 ] && (patch gnu/binutils-*/bfd/init.c ${BASE}/patch/patch-bnu27-bfd-init.txt || exit 1 )

    touch binutils-unpacked
  fi
  cd gnu/binutils-* || exit 1

  # exec permission of some files are not set, fix it.
  for EXEC_FILE in install-sh missing; do
    echo "chmod a+x $EXEC_FILE"
    chmod a+x $EXEC_FILE || exit 1
  done

  mkdir -p build
  cd build || exit 1
  if [ ! -e binutils-configure-prefix ] || [ ! `cat binutils-configure-prefix` = "${DJGPP_PREFIX}" ]; then
    rm binutils-configure-prefix
    ${MAKE} distclean
    ../configure \
               --prefix=$DJGPP_PREFIX \
               --target=i586-pc-msdosdjgpp \
               --program-prefix=i586-pc-msdosdjgpp- \
               --disable-werror \
               --disable-nls \
               ${BINUTILS_CONFIGURE_OPTIONS} \
               || exit 1
    echo ${DJGPP_PREFIX} > binutils-configure-prefix
  else
    echo "Note: binutils already configured. To force a rebuild, use: rm -rf $(pwd)"
    sleep 5
  fi

  ${MAKE} -j${MAKE_JOBS} configure-bfd || exit 1
  ${MAKE} -j${MAKE_JOBS} -C bfd stmp-lcoff-h || exit 1
  ${MAKE} -j${MAKE_JOBS} || exit 1

  if [ ! -z $MAKE_CHECK ]; then
    echo "Run ${MAKE} check"
    ${MAKE} -j${MAKE_JOBS} check || exit 1
  fi

  ${MAKE} -j${MAKE_JOBS} install || exit 1

  rm ${DJGPP_PREFIX}/i586-pc-msdosdjgpp/etc/binutils-*-installed
  touch ${DJGPP_PREFIX}/i586-pc-msdosdjgpp/etc/binutils-${BINUTILS_VERSION}-installed
  # binutils done
fi

cd ${BASE}/build/

if [ ! -z ${DJGPP_VERSION} ] || [ ! -z ${BUILD_DXEGEN} ]; then
  echo "Prepare djgpp"
  rm -rf ${BASE}/build/djgpp-${DJGPP_VERSION}
  mkdir -p ${BASE}/build/djgpp-${DJGPP_VERSION}
  cd ${BASE}/build/djgpp-${DJGPP_VERSION} || exit 1
  unzip -o ../../download/djdev${DJGPP_VERSION}.zip || exit 1
  unzip -o ../../download/djlsr${DJGPP_VERSION}.zip || exit 1
  unzip -o ../../download/djcrx${DJGPP_VERSION}.zip || exit 1
  patch -p1 -u < ../../patch/patch-djlsr${DJGPP_VERSION}.txt || exit 1
  patch -p1 -u < ../../patch/patch-djcrx${DJGPP_VERSION}.txt || exit 1

  cd src/stub
  ${CC} -O2 ${CFLAGS} stubify.c -o i586-pc-msdosdjgpp-stubify || exit 1
  ${CC} -O2 ${CFLAGS} stubedit.c -o i586-pc-msdosdjgpp-stubedit || exit 1

  cd ../..

  mkdir -p $DJGPP_PREFIX/i586-pc-msdosdjgpp/sys-include || exit 1
  cp -rp include/* $DJGPP_PREFIX/i586-pc-msdosdjgpp/sys-include/ || exit 1
  cp -rp lib $DJGPP_PREFIX/i586-pc-msdosdjgpp/ || exit 1
  mkdir -p $DJGPP_PREFIX/bin || exit 1
  cp -p src/stub/i586-pc-msdosdjgpp-stubify $DJGPP_PREFIX/bin/ || exit 1
  cp -p src/stub/i586-pc-msdosdjgpp-stubedit $DJGPP_PREFIX/bin/ || exit 1

  rm ${DJGPP_PREFIX}/i586-pc-msdosdjgpp/etc/djgpp-*-installed
  touch ${DJGPP_PREFIX}/i586-pc-msdosdjgpp/etc/djgpp-${DJGPP_VERSION}-installed
fi

cd ${BASE}/build/

if [ ! -z ${GCC_VERSION} ]; then
  # build gcc
  tar -xavf $(ls -t ../download/djcross-gcc-${GCC_VERSION}.tar.* | head -n 1) || exit 1
  cd djcross-gcc-${GCC_VERSION}/

  BUILDDIR=`pwd`

  if [ ! -e ${BUILDDIR}/tmpinst/autoconf-${AUTOCONF_VERSION}-built ]; then
    echo "Building autoconf"
    cd $BUILDDIR
    tar -xavf $(ls -t ../../download/autoconf-${AUTOCONF_VERSION}.tar.* | head -n 1) || exit 1
    cd autoconf-${AUTOCONF_VERSION}/
    ./configure --prefix=$BUILDDIR/tmpinst || exit 1
    ${MAKE} -j${MAKE_JOBS} all install || exit 1
    rm ${BUILDDIR}/tmpinst/autoconf-*-built
    touch ${BUILDDIR}/tmpinst/autoconf-${AUTOCONF_VERSION}-built
  else
    echo "autoconf already built, skipping."
  fi

  if [ ! -e ${BUILDDIR}/tmpinst/automake-${AUTOMAKE_VERSION}-built ]; then
    echo "Building automake"
    cd $BUILDDIR
    tar -xavf $(ls -t ../../download/automake-${AUTOMAKE_VERSION}.tar.* | head -n 1) || exit 1
    cd automake-${AUTOMAKE_VERSION}/
    PATH="$BUILDDIR//tmpinst/bin:$PATH" \
    ./configure --prefix=$BUILDDIR/tmpinst || exit 1
    PATH="$BUILDDIR//tmpinst/bin:$PATH" \
    ${MAKE} all install || exit 1
    rm ${BUILDDIR}/tmpinst/automake-*-built
    touch ${BUILDDIR}/tmpinst/automake-${AUTOMAKE_VERSION}-built
  else
    echo "automake already built, skipping."
  fi

  # build GNU sed if needed.
  SED=sed
  if [ ! -z $SED_VERSION ]; then
    echo "Building sed"
    cd $BUILDDIR
    tar -xavf $(ls -t ../../download/sed-${SED_VERSION}.tar.* | head -n 1) || exit 1
    cd sed-${SED_VERSION}/
    ./configure --prefix=$BUILDDIR/tmpinst || exit 1
    ${MAKE} -j${MAKE_JOBS} all install || exit 1
    SED=$BUILDDIR/tmpinst/bin/sed
  fi

  cd $BUILDDIR

  if [ ! -e gcc-unpacked ]; then
    echo "Patch unpack-gcc.sh"

    if [ ${GCC_VERSION} == "4.7.3" ]; then
      # gcc 4.7.3 unpack-gcc.sh needs to be patched for OSX
      # patch from :
      #   ( cd gnu && tar xf $top/$archive --use=`case $archive in *.gz|*.tgz) echo 'gzip';; *.bz2) echo 'bzip2';; *.xz) echo 'xz';; esac` && echo $archive >$top/s-sources )
      # to :
      #   ( cd gnu && tar xjf $top/$archive && echo $archive >$top/s-sources )
      $SED -i "s/\(cd gnu && tar x\)\([^-]*\)\([^&]*\)/\1j\2/" unpack-gcc.sh || exit 1
    else
      # gcc 4.8 or above unpack-gcc.sh needs to be patched for OSX
      # patch from :
      #   ( cd gnu && tar xf $top/$archive $tar_param && echo $archive >$top/s-sources )
      # to :
      #   ( cd gnu && tar xJf $top/$archive && echo $archive >$top/s-sources )
      $SED -i "s/\(cd gnu && tar x\)\(f [^ ]* \)\([^ ]* \)/\1a\2/" unpack-gcc.sh || exit 1
    fi

    if [ `uname` = "FreeBSD" ]; then
      # The --verbose option is not recognized by BSD patch
      $SED -i 's/patch --verbose/patch/' unpack-gcc.sh || exit 1
    fi

    echo "Running unpack-gcc.sh"
    PATH="$BUILDDIR/tmpinst/bin:$PATH" sh unpack-gcc.sh --no-djgpp-source $(ls -t ../../download/gcc-${GCC_VERSION}.tar.* | head -n 1) || exit 1

    # patch gnu/gcc-X.XX/gcc/doc/gcc.texi
    echo "Patch gcc/doc/gcc.texi"
    cd gnu/gcc-*/gcc/doc || exit 1
    $SED -i "s/[^^]@\(\(tex\)\|\(end\)\)/\n@\1/g" gcc.texi || exit 1
    cd -

    # copy stubify programs
    cp -p $DJGPP_PREFIX/bin/i586-pc-msdosdjgpp-stubify $BUILDDIR/tmpinst/bin/stubify

    cd $BUILDDIR/

    # download mpc/gmp/mpfr/isl libraries
    echo "Downloading gcc dependencies"
    cd gnu/gcc-${GCC_VERSION_SHORT}
    ./contrib/download_prerequisites
    cd -

    touch gcc-unpacked
  else
    echo "gcc already unpacked, skipping."
  fi

  echo "Building gcc"

  mkdir -p djcross || exit 1
  cd djcross

  TEMP_CFLAGS="$CFLAGS"
  export CFLAGS="$CFLAGS $GCC_EXTRA_CFLAGS"

  if [ ! -e gcc-configure-prefix ] || [ ! `cat gcc-configure-prefix` = "${DJGPP_PREFIX}" ]; then
    rm gcc-configure-prefix
    ${MAKE} distclean
    PATH="$BUILDDIR//tmpinst/bin:$PATH" \
    ../gnu/gcc-${GCC_VERSION_SHORT}/configure \
                                     --target=i586-pc-msdosdjgpp \
                                     --program-prefix=i586-pc-msdosdjgpp- \
                                     --prefix=$DJGPP_PREFIX \
                                     --disable-nls \
                                     --enable-libquadmath-support \
                                     --enable-version-specific-runtime-libs \
                                     --enable-languages=${ENABLE_LANGUAGES} \
                                     --enable-fat \
                                     ${GCC_CONFIGURE_OPTIONS} || exit 1
    echo ${DJGPP_PREFIX} > gcc-configure-prefix
  else
    echo "Note: gcc already configured. To force a rebuild, use: rm -rf $(pwd)"
    sleep 5
  fi

  ${MAKE} -j${MAKE_JOBS} "PATH=$BUILDDIR/tmpinst/bin:$PATH" || exit 1
  ${MAKE} -j${MAKE_JOBS} install-strip || exit 1

  rm ${DJGPP_PREFIX}/i586-pc-msdosdjgpp/etc/gcc-*-installed
  touch ${DJGPP_PREFIX}/i586-pc-msdosdjgpp/etc/gcc-${GCC_VERSION}-installed

  export CFLAGS="$TEMP_CFLAGS"
fi

# gcc done

if [ ! -z ${DJGPP_VERSION} ]; then
  # build djlsr (for dxegen / exe2coff)
  cd ${BASE}/build/djgpp-${DJGPP_VERSION}
  if [ "$CC" == "gcc" ] && [ ! -z ${BUILD_DXEGEN} ]; then
    echo "Building DXE tools."
    cd src
    PATH=$DJGPP_PREFIX/bin/:$PATH ${MAKE} || exit 1
    cd dxe
    cp -p dxegen  $DJGPP_PREFIX/bin/i586-pc-msdosdjgpp-dxegen || exit 1
    cp -p dxe3gen $DJGPP_PREFIX/bin/i586-pc-msdosdjgpp-dxe3gen || exit 1
    cp -p dxe3res $DJGPP_PREFIX/bin/i586-pc-msdosdjgpp-dxe3res || exit 1
    cd ../..
    touch ${DJGPP_PREFIX}/i586-pc-msdosdjgpp/etc/dxegen-installed
  else
    echo "Building DXE tools requires gcc, skip."
  fi
  cd src/stub
  ${CC} -O2 ${CFLAGS} -o exe2coff exe2coff.c || exit 1
  cp -p exe2coff $DJGPP_PREFIX/bin/i586-pc-msdosdjgpp-exe2coff || exit 1

  # djlsr done
fi

cd ${BASE}/build

if [ ! -z ${GDB_VERSION} ]; then
  if [ ! -e gdb-${GDB_VERSION}/gdb-unpacked ]; then
    echo "Unpacking gdb."
    tar -xavf $(ls -t ../download/gdb-${GDB_VERSION}.tar.* | head -n 1) || exit 1
    touch gdb-${GDB_VERSION}/gdb-unpacked
  fi
  mkdir -p gdb-${GDB_VERSION}/build
  cd gdb-${GDB_VERSION}/build || exit 1

  echo "Building gdb."
  if [ ! -e gdb-configure-prefix ] || [ ! `cat gdb-configure-prefix` = "${DJGPP_PREFIX}" ]; then
    rm gdb-configure-prefix
    ${MAKE} distclean
    ../configure \
          --prefix=${DJGPP_PREFIX} \
          --target=i586-pc-msdosdjgpp \
          --disable-werror \
          --disable-nls \
          ${GDB_CONFIGURE_OPTIONS} \
          || exit 1
    echo ${DJGPP_PREFIX} > gdb-configure-prefix
  else
    echo "Note: gdb already configured. To force a rebuild, use: rm -rf $(pwd)"
    sleep 5
  fi
  ${MAKE} -j${MAKE_JOBS} || exit 1

  if [ ! -z $MAKE_CHECK ]; then
    echo "Run ${MAKE} check"
    ${MAKE} -j${MAKE_JOBS} check || exit 1
  fi

  ${MAKE} -j${MAKE_JOBS} install || exit 1

  rm ${DJGPP_PREFIX}/i586-pc-msdosdjgpp/etc/gdb-*-installed
  touch ${DJGPP_PREFIX}/i586-pc-msdosdjgpp/etc/gdb-${GDB_VERSION}-installed
fi

echo "Copy long name executables to short name."
(
  cd $DJGPP_PREFIX || exit 1
  SHORT_NAME_LIST="gcc g++ c++ addr2line c++filt cpp size strings dxegen dxe3gen dxe3res exe2coff stubify stubedit gdb"
  for SHORT_NAME in $SHORT_NAME_LIST; do
    if [ -f bin/i586-pc-msdosdjgpp-$SHORT_NAME ]; then
      cp -p bin/i586-pc-msdosdjgpp-$SHORT_NAME i586-pc-msdosdjgpp/bin/$SHORT_NAME
    fi
  done
)

# copy setenv script
(cd ${BASE}/setenv/ && ./copyfile.sh $DJGPP_PREFIX) || exit 1

echo "Testing DJGPP."
cd ${BASE}/build
echo "Use DJGPP to build a test C program."
$DJGPP_PREFIX/bin/i586-pc-msdosdjgpp-gcc ../hello.c -o hello || echo "FAILED: C"

for x in $(echo $ENABLE_LANGUAGES | tr "," " ")
do
  case $x in
    c++)
      echo "Use DJGPP to build a test C++ program."
      $DJGPP_PREFIX/bin/i586-pc-msdosdjgpp-c++ ../hello-cpp.cpp -o hello-cpp || echo "FAILED: C++"
      ;;
  esac
done

echo "build-djgpp.sh done."
echo "To remove temporary build files, use: rm -rf build/"
echo "To remove downloaded source packages, use: rm -rf download/"
