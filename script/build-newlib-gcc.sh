cd ${BASE}/build/

if [ ! -z ${NEWLIB_VERSION} ] && [ ! -e newlib-${NEWLIB_VERSION}/newlib-unpacked ]; then
  echo "Unpacking newlib..."
  untar ${NEWLIB_ARCHIVE}
  ${SUDO} mkdir -p ${DST}/${TARGET}/include/
  ${SUDO} cp -rv newlib-${NEWLIB_VERSION}/newlib/libc/include/* ${DST}/${TARGET}/include/ | exit 1
  touch newlib-${NEWLIB_VERSION}/newlib-unpacked
fi

if [ ! -z ${GCC_VERSION} ]; then
  if [ ! -e gcc-${GCC_VERSION}/gcc-unpacked ]; then
    echo "Unpacking gcc..."
    untar ${GCC_ARCHIVE}

    pushd gcc-${GCC_VERSION} || exit 1

    if [ ! -z ${BUILD_DEB} ]; then
      echo "Unpacking gcc dependencies"
      for URL in $GMP_ARCHIVE $MPFR_ARCHIVE $MPC_ARCHIVE $ISL_ARCHIVE; do
        FILE=`basename $URL`
        untar ${FILE}
        mv ${FILE%.*.*} ${FILE%%-*} || exit 1
      done
    else
      echo "Downloading gcc dependencies"
      sed -i 's/ftp/http/g' contrib/download_prerequisites
      ./contrib/download_prerequisites || exit 1
    fi

    touch gcc-unpacked
    popd
  else
    echo "gcc already unpacked, skipping."
  fi

  echo "Building gcc (stage 1)"

  mkdir -p gcc-${GCC_VERSION}/build-${TARGET}
  cd gcc-${GCC_VERSION}/build-${TARGET} || exit 1

  TEMP_CFLAGS="$CFLAGS"
  export CFLAGS="$CFLAGS $GCC_EXTRA_CFLAGS"

  GCC_CONFIGURE_OPTIONS+=" --target=${TARGET} --prefix=${PREFIX} ${HOST_FLAG} ${BUILD_FLAG}
                           --enable-languages=${ENABLE_LANGUAGES}
                           --with-newlib"
  strip_whitespace GCC_CONFIGURE_OPTIONS

  if [ ! -e configure-prefix ] || [ ! "`cat configure-prefix`" == "${GCC_CONFIGURE_OPTIONS}" ]; then
    rm -rf *
    rm -rf ${BASE}/build/newlib-${NEWLIB_VERSION}/build-${TARGET}/*
    eval "../configure ${GCC_CONFIGURE_OPTIONS}" || exit 1
    echo ${GCC_CONFIGURE_OPTIONS} > configure-prefix
  else
    echo "Note: gcc already configured. To force a rebuild, use: rm -rf $(pwd)"
    [ -z ${BUILD_BATCH} ] && sleep 5
  fi

  ${MAKE_J} all-gcc || exit 1
  echo "Installing gcc (stage 1)"
  ${SUDO} ${MAKE_J} install-gcc || exit 1

  export CFLAGS="$TEMP_CFLAGS"
fi

cd ${BASE}/build/

if [ ! -z ${NEWLIB_VERSION} ]; then
  echo "Building newlib"
  mkdir -p newlib-${NEWLIB_VERSION}/build-${TARGET}
  cd newlib-${NEWLIB_VERSION}/build-${TARGET} || exit 1

  NEWLIB_CONFIGURE_OPTIONS+=" --target=${TARGET} --prefix=${PREFIX} ${HOST_FLAG} ${BUILD_FLAG}"
  strip_whitespace NEWLIB_CONFIGURE_OPTIONS

  if [ ! -z ${GCC_VERSION} ] || [ ! "`cat configure-options 2> /dev/null`" == "${NEWLIB_CONFIGURE_OPTIONS}" ]; then
    rm -rf *
    ../configure ${NEWLIB_CONFIGURE_OPTIONS} || exit 1
    echo ${NEWLIB_CONFIGURE_OPTIONS} > configure-options
  else
    echo "Note: newlib already configured. To force a rebuild, use: rm -rf $(pwd)"
    [ -z ${BUILD_BATCH} ] && sleep 5
  fi

  ${MAKE_J} || exit 1
  [ ! -z $MAKE_CHECK ] && ${MAKE_J} -s check | tee ${BASE}/tests/newlib.log
  echo "Installing newlib"
  ${SUDO} ${MAKE_J} install || \
  ${SUDO} ${MAKE_J} install || exit 1
fi

cd ${BASE}/build/

if [ ! -z ${GCC_VERSION} ]; then
  echo "Building gcc (stage 2)"
  cd gcc-${GCC_VERSION}/build-${TARGET} || exit 1

  export STAGE_CC_WRAPPER="${BASE}/script/destdir-hack.sh ${DST}/${TARGET}"
  ${MAKE_J} || exit 1
  [ ! -z $MAKE_CHECK_GCC ] && ${MAKE_J} -s check-gcc | tee ${BASE}/tests/gcc.log
  echo "Installing gcc"
  ${SUDO} ${MAKE_J} install-strip || \
  ${SUDO} ${MAKE_J} install-strip || exit 1
  ${SUDO} ${MAKE_J} -C mpfr install DESTDIR=${BASE}/build/tmpinst

  set_version gcc
fi
