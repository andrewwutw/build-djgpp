#!/usr/bin/env bash

source script/init.sh

case $TARGET in
*-msdosdjgpp) ;;
*) TARGET="i586-pc-msdosdjgpp" ;;
esac

export DJGPP_DOWNLOAD_BASE="http://www.mirrorservice.org/sites/ftp.delorie.com/pub"

prepend BINUTILS_CONFIGURE_OPTIONS "--disable-werror
                                    --disable-nls"

prepend GCC_CONFIGURE_OPTIONS "--disable-nls
                               --enable-libquadmath-support
                               --enable-version-specific-runtime-libs
                               --enable-fat
                               --enable-libstdcxx-filesystem-ts"

prepend GDB_CONFIGURE_OPTIONS "--disable-werror
                               --disable-nls"

prepend DJGPP_CFLAGS "-O2"

if [ -z $1 ]; then
  echo "Usage: $0 [packages...]"
  echo "Supported packages:"
  ls djgpp/
  ls common/
  exit 1
fi

while [ ! -z $1 ]; do
  if [ ! -x djgpp/$1 ] && [ ! -x common/$1 ]; then
    echo "Unsupported package: $1"
    exit 1
  fi

  [ -e djgpp/$1 ] && source djgpp/$1 || source common/$1
  shift
done

DEPS=""

if [ -z ${IGNORE_DEPENDENCIES} ]; then
  [ ! -z ${GCC_VERSION} ] && DEPS+=" djgpp binutils"
  [ ! -z ${BINUTILS_VERSION} ] && DEPS+=" "
  [ ! -z ${GDB_VERSION} ] && DEPS+=" "
  [ ! -z ${DJGPP_VERSION} ] && DEPS+=" binutils gcc"
  [ ! -z ${BUILD_DXEGEN} ] && DEPS+=" djgpp binutils gcc"
  
  for DEP in ${DEPS}; do
    case $DEP in
      djgpp)
        [ -z ${DJGPP_VERSION} ] \
          && source djgpp/djgpp
        ;;
      binutils)
        [ -z "`ls ${PREFIX}/${TARGET}/etc/binutils-*-installed 2> /dev/null`" ] \
          && [ -z ${BINUTILS_VERSION} ] \
          && source djgpp/binutils
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
      dxegen)
        [ -z "`ls ${PREFIX}/${TARGET}/etc/dxegen-installed 2> /dev/null`" ] \
          && [ -z ${BUILD_DXEGEN} ] \
          && source djgpp/dxegen
        ;;
    esac
  done
fi

if [ ! -z ${GCC_VERSION} ] && [ -z ${DJCROSS_GCC_ARCHIVE} ]; then
  DJCROSS_GCC_ARCHIVE="${DJGPP_DOWNLOAD_BASE}/djgpp/rpms/djcross-gcc-${GCC_VERSION}/djcross-gcc-${GCC_VERSION}.tar.bz2"
  # djcross-gcc-X.XX-tar.* maybe moved from /djgpp/rpms/ to /djgpp/deleted/rpms/ directory.
  OLD_DJCROSS_GCC_ARCHIVE=${DJCROSS_GCC_ARCHIVE/rpms\//deleted\/rpms\/}
fi

source ${BASE}/script/download.sh

source ${BASE}/script/build-tools.sh

cd ${BASE}/build/ || exit 1

if [ ! -z ${BINUTILS_VERSION} ]; then
  mkdir -p bnu${BINUTILS_VERSION}s
  cd bnu${BINUTILS_VERSION}s
  if [ ! -e binutils-unpacked ]; then
    echo "Unpacking binutils..."
    unzip -oq ../../download/bnu${BINUTILS_VERSION}s.zip || exit 1

    # patch for binutils 2.27
    [ ${BINUTILS_VERSION} == 227 ] && (patch gnu/binutils-*/bfd/init.c ${BASE}/patch/patch-bnu27-bfd-init.txt || exit 1 )

    touch binutils-unpacked
  fi
  cd gnu/binutils-* || exit 1

  # exec permission of some files are not set, fix it.
  for EXEC_FILE in install-sh missing configure; do
    echo "chmod a+x $EXEC_FILE"
    chmod a+x $EXEC_FILE || exit 1
  done

  source ${BASE}/script/build-binutils.sh
fi

cd ${BASE}/build/ || exit 1

if [ ! -z ${DJGPP_VERSION} ]; then
  if [ "${DJGPP_VERSION}" == "cvs" ]; then
    download_git https://github.com/jwt27/djgpp-cvs.git jwt27
    cd djgpp-cvs
  else
    echo "Unpacking djgpp..."
    rm -rf djgpp-${DJGPP_VERSION}/
    mkdir -p djgpp-${DJGPP_VERSION}/
    cd djgpp-${DJGPP_VERSION}/ || exit 1
    unzip -uoq ../../download/djdev${DJGPP_VERSION}.zip || exit 1
    unzip -uoq ../../download/djlsr${DJGPP_VERSION}.zip || exit 1
    unzip -uoq ../../download/djcrx${DJGPP_VERSION}.zip || exit 1
    patch -p1 -u < ../../patch/patch-djlsr${DJGPP_VERSION}.txt || exit 1
    patch -p1 -u < ../../patch/patch-djcrx${DJGPP_VERSION}.txt || exit 1
  fi

  cd src
  unset COMSPEC
  sed -i "50cCROSS_PREFIX = ${TARGET}-" makefile.def
  sed -i '61cGCC = \$(CC) -g -O2 \$(HOST_CFLAGS)' makefile.def
  ${MAKE} misc.exe makemake.exe ../hostbin || exit 1
  ${MAKE} config || exit 1
  echo "-Wno-error" >> gcc.opt
  ${MAKE} -C djasm native || exit 1
  ${MAKE} -C stub native || exit 1
  cd ..

  case `uname` in
  MINGW*) EXE=.exe ;;
  MSYS*) EXE=.exe ;;
  *) EXE= ;;
  esac

  echo "Installing djgpp headers"
  ${SUDO} mkdir -p $PREFIX/${TARGET}/sys-include || exit 1
  ${SUDO} cp -rp include/* $PREFIX/${TARGET}/sys-include/ || exit 1
  ${SUDO} mkdir -p $PREFIX/bin || exit 1
  ${SUDO} cp -p hostbin/stubify.exe $PREFIX/bin/${TARGET}-stubify${EXE} || exit 1
  ${SUDO} cp -p hostbin/stubedit.exe $PREFIX/bin/${TARGET}-stubedit${EXE} || exit 1
fi

cd ${BASE}/build/

if [ ! -z ${GCC_VERSION} ]; then
  # build gcc
  untar ${DJCROSS_GCC_ARCHIVE} || exit 1
  cd djcross-gcc-${GCC_VERSION}/

  BUILDDIR=`pwd`
  export PATH="${BUILDDIR}/tmpinst/bin:$PATH"

  if [ ! -e ${BUILDDIR}/tmpinst/autoconf-${AUTOCONF_VERSION}-built ]; then
    echo "Building autoconf"
    cd $BUILDDIR
    untar ${AUTOCONF_ARCHIVE} || exit 1
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
    untar ${AUTOMAKE_ARCHIVE} || exit 1
    cd automake-${AUTOMAKE_VERSION}/
    ./configure --prefix=$BUILDDIR/tmpinst || exit 1
      ${MAKE} all install || exit 1
    rm ${BUILDDIR}/tmpinst/automake-*-built
    touch ${BUILDDIR}/tmpinst/automake-${AUTOMAKE_VERSION}-built
  else
    echo "automake already built, skipping."
  fi

  cd $BUILDDIR

  if [ ! -e gcc-unpacked ]; then
    rm -rf $BUILDDIR/gnu/

    if [ `uname` = "FreeBSD" ]; then
      # The --verbose option is not recognized by BSD patch
      sed -i 's/patch --verbose/patch/' unpack-gcc.sh || exit 1
    fi
    # prevent renaming source directory.
    sed -i 's/gcc-\$short_ver/gcc-\$gcc_version/' unpack-gcc.sh || exit 1

    echo "Running unpack-gcc.sh"
    sh unpack-gcc.sh --no-djgpp-source ../../download/$(basename ${GCC_ARCHIVE}) || exit 1

    # patch gnu/gcc-X.XX/gcc/doc/gcc.texi
    echo "Patch gcc/doc/gcc.texi"
    cd gnu/gcc-*/gcc/doc || exit 1
    sed -i "s/[^^]@\(\(tex\)\|\(end\)\)/\n@\1/g" gcc.texi || exit 1
    cd -

    cd $BUILDDIR/

    # download mpc/gmp/mpfr/isl libraries
    echo "Downloading gcc dependencies"
    cd gnu/gcc-${GCC_VERSION} || exit 1
    sed -i 's/ftp/http/' contrib/download_prerequisites
    ./contrib/download_prerequisites || exit 1

    # apply extra patches if necessary
    [ -e ${BASE}/patch/patch-djgpp-gcc-${GCC_VERSION}.txt ] && patch -p 1 -u -i ${BASE}/patch/patch-djgpp-gcc-${GCC_VERSION}.txt
    cd -

    touch gcc-unpacked
  else
    echo "gcc already unpacked, skipping."
  fi

  echo "Building gcc (stage 1)"

  mkdir -p djcross
  cd djcross || exit 1

  TEMP_CFLAGS="$CFLAGS"
  export CFLAGS="$CFLAGS $GCC_EXTRA_CFLAGS"

  GCC_CONFIGURE_OPTIONS+=" --target=${TARGET} --prefix=${PREFIX} ${HOST_FLAG} ${BUILD_FLAG}
                           --enable-languages=${ENABLE_LANGUAGES}"
  strip_whitespace GCC_CONFIGURE_OPTIONS

  if [ ! -e configure-prefix ] || [ ! "`cat configure-prefix`" == "${GCC_CONFIGURE_OPTIONS}" ]; then
    rm -rf *
    ../gnu/gcc-${GCC_VERSION}/configure ${GCC_CONFIGURE_OPTIONS} || exit 1
    echo ${GCC_CONFIGURE_OPTIONS} > configure-prefix
  else
    echo "Note: gcc already configured. To force a rebuild, use: rm -rf $(pwd)"
    sleep 5
  fi

  cp $PREFIX/bin/${TARGET}-stubify $BUILDDIR/tmpinst/bin/stubify || exit 1

  ${MAKE} -j${MAKE_JOBS} all-gcc || exit 1
  echo "Installing gcc (stage 1)"
  ${SUDO} ${MAKE} -j${MAKE_JOBS} install-gcc || exit 1

  export CFLAGS="$TEMP_CFLAGS"
fi

# gcc done

if [ ! -z ${DJGPP_VERSION} ]; then
  echo "Building djgpp libc"
  cd ${BASE}/build/djgpp-${DJGPP_VERSION}/src
  TEMP_CFLAGS="$CFLAGS"
  export CFLAGS="$DJGPP_CFLAGS"
  ${MAKE} -j${MAKE_JOBS}|| exit 1
  CFLAGS="$TEMP_CFLAGS"
  cd ..

  echo "Installing djgpp libc"
  ${SUDO} mkdir -p ${PREFIX}/${TARGET}/lib
  ${SUDO} cp -rp lib/* $PREFIX/${TARGET}/lib || exit 1
  ${SUDO} cp -p hostbin/exe2coff.exe $PREFIX/bin/${TARGET}-exe2coff${EXE} || exit 1
  ${SUDO} mkdir -p ${PREFIX}/${TARGET}/share/info
  ${SUDO} cp -rp info/* ${PREFIX}/${TARGET}/share/info

  if [ ! -z ${BUILD_DXEGEN} ]; then
    echo "Installing DXE tools"
    ${SUDO} cp -p hostbin/dxegen.exe  $PREFIX/bin/${TARGET}-dxegen${EXE} || exit 1
    ${SUDO} ln -s $PREFIX/bin/${TARGET}-dxegen${EXE} $PREFIX/bin/${TARGET}-dxe3gen${EXE} || exit 1
    ${SUDO} cp -p hostbin/dxe3res.exe $PREFIX/bin/${TARGET}-dxe3res${EXE} || exit 1
    touch ${PREFIX}/${TARGET}/etc/dxegen-installed
  fi

  ${SUDO} rm -f ${PREFIX}/${TARGET}/etc/djgpp-*-installed
  ${SUDO} touch ${PREFIX}/${TARGET}/etc/djgpp-${DJGPP_VERSION}-installed
fi

if [ ! -z ${GCC_VERSION} ]; then
  echo "Building gcc (stage 2)"
  cd $BUILDDIR/djcross || exit 1

  TEMP_CFLAGS="$CFLAGS"
  export CFLAGS="$CFLAGS $GCC_EXTRA_CFLAGS"
  ${MAKE} -j${MAKE_JOBS} || exit 1
  [ ! -z $MAKE_CHECK_GCC ] && ${MAKE} -j${MAKE_JOBS} -s check-gcc | tee ${BASE}/tests/gcc.log
  echo "Installing gcc (stage 2)"
  ${SUDO} ${MAKE} -j${MAKE_JOBS} install-strip || \
  ${SUDO} ${MAKE} -j${MAKE_JOBS} install-strip || exit 1
  ${SUDO} ${MAKE} -j${MAKE_JOBS} -C mpfr install
  CFLAGS="$TEMP_CFLAGS"

  ${SUDO} rm -f ${PREFIX}/${TARGET}/etc/gcc-*-installed
  ${SUDO} touch ${PREFIX}/${TARGET}/etc/gcc-${GCC_VERSION}-installed
fi

cd ${BASE}/build

source ${BASE}/script/build-gdb.sh

source ${BASE}/script/finalize.sh
