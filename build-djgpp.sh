#!/usr/bin/env bash

source script/init.sh

DJGPP_DOWNLOAD_BASE="http://www.mirrorservice.org/sites/ftp.delorie.com/pub"
PACKAGE_SOURCES="djgpp common"
source script/parse-args.sh

case $TARGET in
*-msdosdjgpp) ;;
*) TARGET="i586-pc-msdosdjgpp" ;;
esac

prepend BINUTILS_CONFIGURE_OPTIONS "--disable-werror
                                    --disable-nls"

prepend GCC_CONFIGURE_OPTIONS "--disable-nls
                               --enable-libquadmath-support
                               --enable-version-specific-runtime-libs
                               --enable-fat
                               --enable-libstdcxx-filesystem-ts"

prepend GDB_CONFIGURE_OPTIONS "--disable-werror
                               --disable-nls"

prepend CFLAGS_FOR_TARGET "-O2"

DEPS=""
[ ! -z ${GCC_VERSION} ] && DEPS+=" djgpp binutils"
[ ! -z ${DJGPP_VERSION} ] && DEPS+=" binutils gcc"

source ${BASE}/script/check-deps-and-confirm.sh
source ${BASE}/script/download.sh
source ${BASE}/script/mkdirs.sh
source ${BASE}/script/build-tools.sh

cd ${BASE}/build/ || exit 1

if [ ! -z ${BINUTILS_VERSION} ]; then
  mkdir -p bnu${BINUTILS_VERSION}s
  cd bnu${BINUTILS_VERSION}s
  if [ ! -e binutils-unpacked ]; then
    echo "Unpacking binutils..."
    unzip -oq ../../download/bnu${BINUTILS_VERSION}s.zip || exit 1

    case ${BINUTILS_VERSION} in
    227)  patch gnu/binutils-*/bfd/init.c ${BASE}/patch/patch-bnu27-bfd-init.txt || exit 1 ;;
    2331) patch gnu/binutils-*/libctf/swap.h ${BASE}/patch/patch-djgpp-binutils-2.33.1-swap.txt || exit 1 ;;
    234)  ;; #TODO
    esac

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
    cd djgpp-cvs || exit 1
  else
    echo "Unpacking djgpp..."
    rm -rf djgpp-${DJGPP_VERSION}/
    mkdir -p djgpp-${DJGPP_VERSION}/
    cd djgpp-${DJGPP_VERSION}/ || exit 1
    unzip -uoq ../../download/djdev${DJGPP_VERSION}.zip || exit 1
    unzip -uoq ../../download/djlsr${DJGPP_VERSION}.zip || exit 1
    unzip -uoq ../../download/djcrx${DJGPP_VERSION}.zip || exit 1
    patch -p1 -u < ../../patch/patch-djcrx${DJGPP_VERSION}.txt || exit 1
    cat ../../patch/djlsr${DJGPP_VERSION}/* | patch -p1 -u || exit 1
  fi

  cd src
  unset COMSPEC
  sed -i "50cCROSS_PREFIX = ${TARGET}-" makefile.def
  sed -i "61cGCC = \$(CC) -g -O2 ${CFLAGS}" makefile.def
  if [ -e configure-options ] && [ ! "`cat configure-options 2> /dev/null`" == "${TARGET}:${DST}:${CFLAGS_FOR_TARGET}" ]; then
    ${MAKE} -j${MAKE_JOBS} clean
  fi
  ${MAKE} misc.exe makemake.exe ../hostbin || exit 1
  ${MAKE} -C djasm native || exit 1
  ${MAKE} -C stub native || exit 1
  cd ..

  case `uname` in
  MINGW*) EXE=.exe ;;
  MSYS*) EXE=.exe ;;
  *) EXE= ;;
  esac

  echo "Installing djgpp headers and utilities"
  ${SUDO} mkdir -p ${DST}/${TARGET}/sys-include || exit 1
  ${SUDO} cp -rp include/* ${DST}/${TARGET}/sys-include/ || exit 1
  ${SUDO} mkdir -p ${DST}/bin || exit 1
  ${SUDO} cp -p hostbin/stubify.exe  ${DST}/bin/${TARGET}-stubify${EXE}  || exit 1
  ${SUDO} cp -p hostbin/stubedit.exe ${DST}/bin/${TARGET}-stubedit${EXE} || exit 1
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
      ${MAKE} -j${MAKE_JOBS} DESTDIR=/ all install || exit 1
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
      ${MAKE} DESTDIR=/ all install || exit 1
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

    case ${GCC_VERSION} in
    4.7.3) UNPACK_PATCH=patch-unpack-gcc-4.7.3.txt ;;
    4.8.0) ;&
    4.8.1) ;&
    4.8.2) UNPACK_PATCH=patch-unpack-gcc-4.8.0.txt ;;
    *)     UNPACK_PATCH=patch-unpack-gcc.txt ;;
    esac

    patch -p1 -u < ${BASE}/patch/${UNPACK_PATCH} || exit 1

    echo "Unpacking gcc..."
    mkdir gnu/
    cd gnu/ || exit 1
    untar ${GCC_ARCHIVE}
    cd ..

    echo "Running unpack-gcc.sh"
    sh unpack-gcc.sh --no-djgpp-source || exit 1

    # patch gnu/gcc-X.XX/gcc/doc/gcc.texi
    echo "Patch gcc/doc/gcc.texi"
    cd gnu/gcc-*/gcc/doc || exit 1
    sed -i "s/[^^]@\(\(tex\)\|\(end\)\)/\n@\1/g" gcc.texi || exit 1
    cd -

    cd $BUILDDIR/

    echo "Unpacking gcc dependencies"
    (
      cd gnu/gcc-${GCC_VERSION} || exit 1

      for URL in $GMP_ARCHIVE $MPFR_ARCHIVE $MPC_ARCHIVE $ISL_ARCHIVE; do
          FILE=`basename $URL`
          untar ${FILE}
          mv ${FILE%.*.*} ${FILE%%-*}
      done

      # apply extra patches if necessary
      [ -e ${BASE}/patch/patch-djgpp-gcc-${GCC_VERSION}.txt ] && patch -p 1 -u -i ${BASE}/patch/patch-djgpp-gcc-${GCC_VERSION}.txt
    )

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
    eval "../gnu/gcc-${GCC_VERSION}/configure ${GCC_CONFIGURE_OPTIONS}" || exit 1
    echo ${GCC_CONFIGURE_OPTIONS} > configure-prefix
  else
    echo "Note: gcc already configured. To force a rebuild, use: rm -rf $(pwd)"
    sleep 5
  fi

  cp ${DST}/bin/${TARGET}-stubify ${BUILDDIR}/tmpinst/bin/stubify || exit 1

  ${MAKE} -j${MAKE_JOBS} all-gcc || exit 1
  echo "Installing gcc (stage 1)"
  ${SUDO} ${MAKE} -j${MAKE_JOBS} install-gcc || exit 1

  export CFLAGS="$TEMP_CFLAGS"
fi

if [ ! -z ${DJGPP_VERSION} ]; then
  echo "Building djgpp libc"
  cd ${BASE}/build/djgpp-${DJGPP_VERSION}/src
  TEMP_CFLAGS="$CFLAGS"
  export CFLAGS="$CFLAGS_FOR_TARGET"
  sed -i 's/Werror/Wno-error/' makefile.cfg
  ${MAKE} config || exit 1
  echo "${TARGET}:${DST}:${CFLAGS_FOR_TARGET}" > configure-options
  ${MAKE} -j${MAKE_JOBS} -C mkdoc || exit 1
  ${MAKE} -j${MAKE_JOBS} -C libc || exit 1

  echo "Installing djgpp libc"
  ${SUDO} mkdir -p ${DST}/${TARGET}/lib
  ${SUDO} cp -rp ../lib/* ${DST}/${TARGET}/lib || exit 1
  CFLAGS="$TEMP_CFLAGS"
fi

if [ ! -z ${GCC_VERSION} ]; then
  echo "Building gcc (stage 2)"
  cd $BUILDDIR/djcross || exit 1

  TEMP_CFLAGS="$CFLAGS"
  export CFLAGS="$CFLAGS $GCC_EXTRA_CFLAGS"
  export STAGE_CC_WRAPPER="${BASE}/script/destdir-hack.sh ${DST}/${TARGET}"
  ${MAKE} -j${MAKE_JOBS} || exit 1
  [ ! -z $MAKE_CHECK_GCC ] && ${MAKE} -j${MAKE_JOBS} -s check-gcc | tee ${BASE}/tests/gcc.log
  echo "Installing gcc (stage 2)"
  ${SUDO} ${MAKE} -j${MAKE_JOBS} install-strip || \
  ${SUDO} ${MAKE} -j${MAKE_JOBS} install-strip || exit 1
  ${SUDO} ${MAKE} -j${MAKE_JOBS} -C mpfr install
  CFLAGS="$TEMP_CFLAGS"

  ${SUDO} rm -f ${DST}/${TARGET}/etc/gcc-*-installed
  ${SUDO} touch ${DST}/${TARGET}/etc/gcc-${GCC_VERSION}-installed
fi

if [ ! -z ${DJGPP_VERSION} ]; then
  echo "Building djgpp libraries"
  cd ${BASE}/build/djgpp-${DJGPP_VERSION}/src
  TEMP_CFLAGS="$CFLAGS"
  export CFLAGS="$CFLAGS_FOR_TARGET"
  ${MAKE} -j${MAKE_JOBS} -C utils native || exit 1
  ${MAKE} -j${MAKE_JOBS} -C dxe native || exit 1
  ${MAKE} -j${MAKE_JOBS} -C debug || exit 1
  ${MAKE} -j${MAKE_JOBS} -C libemu || exit 1
  ${MAKE} -j${MAKE_JOBS} -C libm || exit 1
  ${MAKE} -j${MAKE_JOBS} -C docs || exit 1
  ${MAKE} -j${MAKE_JOBS} -C ../zoneinfo/src
  ${MAKE} -j${MAKE_JOBS} -f makempty || exit 1
  CFLAGS="$TEMP_CFLAGS"
  cd ..

  echo "Installing djgpp libraries and utilities"
  ${SUDO} cp -rp lib/* ${DST}/${TARGET}/lib || exit 1
  ${SUDO} mkdir -p ${DST}/${TARGET}/share/info
  ${SUDO} cp -rp info/* ${DST}/${TARGET}/share/info
  ${SUDO} cp -p hostbin/exe2coff.exe ${DST}/bin/${TARGET}-exe2coff${EXE} || exit 1
  ${SUDO} cp -p hostbin/djasm.exe    ${DST}/bin/${TARGET}-djasm${EXE}    || exit 1
  ${SUDO} cp -p hostbin/dxegen.exe   ${DST}/bin/${TARGET}-dxegen${EXE}   || exit 1
  ${SUDO} cp -p hostbin/dxegen.exe   ${DST}/bin/${TARGET}-dxe3gen${EXE}  || exit 1
  ${SUDO} cp -p hostbin/dxe3res.exe  ${DST}/bin/${TARGET}-dxe3res${EXE}  || exit 1

  ${SUDO} rm -f ${DST}/${TARGET}/etc/djgpp-*-installed
  ${SUDO} touch ${DST}/${TARGET}/etc/djgpp-${DJGPP_VERSION}-installed
fi

cd ${BASE}/build

source ${BASE}/script/build-gdb.sh
source ${BASE}/script/finalize.sh
