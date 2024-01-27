cd ${BASE}/build/

if [ ! -z ${AVRLIBC_VERSION} ]; then
  if [ ! -e avr-libc-${AVRLIBC_VERSION}/avr-libc-unpacked ]; then
    echo "Unpacking avr-libc..."
    untar ${AVRLIBC_ARCHIVE}
    cd avr-libc-${AVRLIBC_VERSION}/
    untar ${AVRLIBC_DOC_ARCHIVE}
    touch avr-libc-unpacked
    cd ..
  fi
  cd avr-libc-${AVRLIBC_VERSION}/
  ${SUDO} mkdir -p ${DST}/${TARGET}/include/
  install_files include/* ${DST}/${TARGET}/include/ | exit 1
  echo "Installing avr-libc documentation"
  ${SUDO} mkdir -p ${DST}/${TARGET}/share/man/
  install_files man/* ${DST}/${TARGET}/share/man/ | exit 1
  cd ..
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
  fi

  echo "Building gcc (stage 1)"

  mkdir -p gcc-${GCC_VERSION}/build-${TARGET}
  cd gcc-${GCC_VERSION}/build-${TARGET} || exit 1

  TEMP_CFLAGS="$CFLAGS"
  TEMP_CXXFLAGS="$CXXFLAGS"
  export CFLAGS="$CFLAGS $GCC_EXTRA_CFLAGS"
  export CXXFLAGS="$CXXFLAGS $GCC_EXTRA_CXXFLAGS"

  GCC_CONFIGURE_OPTIONS+=" --target=${TARGET} --prefix=${PREFIX} ${HOST_FLAG} ${BUILD_FLAG}
                           --enable-languages=${ENABLE_LANGUAGES}
                           --with-avrlibc"
  strip_whitespace GCC_CONFIGURE_OPTIONS

  if [ ! -e configure-prefix ] || [ ! "`cat configure-prefix`" == "${GCC_CONFIGURE_OPTIONS}" ]; then
    rm -rf *
    rm -rf ${BASE}/build/avr-libc-${AVRLIBC_VERSION}/build-${TARGET}/*
    eval "../configure ${GCC_CONFIGURE_OPTIONS}" || exit 1
    echo ${GCC_CONFIGURE_OPTIONS} > configure-prefix
  else
    echo "Note: gcc already configured. To force a rebuild, use: rm -rf $(pwd)"
    [ -z ${BUILD_BATCH} ] && sleep 5
  fi

  ${MAKE_J} all-gcc || exit 1
  echo "Installing gcc (stage 1)"
  ${SUDO} ${MAKE_J} install-gcc || exit 1

  CFLAGS="$TEMP_CFLAGS"
  CXXFLAGS="$TEMP_CXXFLAGS"
fi

cd ${BASE}/build/

if [ ! -z ${AVRLIBC_VERSION} ]; then
  echo "Building avr-libc"
  mkdir -p avr-libc-${AVRLIBC_VERSION}/build-${TARGET}
  cd avr-libc-${AVRLIBC_VERSION}/build-${TARGET} || exit 1

  AVRLIBC_CONFIGURE_OPTIONS+=" --host=${TARGET} --prefix=${PREFIX} ${BUILD_FLAG}"
  strip_whitespace AVRLIBC_CONFIGURE_OPTIONS

  if [ ! -z ${GCC_VERSION} ] || [ ! "`cat configure-options 2> /dev/null`" == "${AVRLIBC_CONFIGURE_OPTIONS}" ]; then
    rm -rf *
    CC=avr-gcc ../configure ${AVRLIBC_CONFIGURE_OPTIONS} || exit 1
    echo ${AVRLIBC_CONFIGURE_OPTIONS} > configure-options
  else
    echo "Note: avr-libc already configured. To force a rebuild, use: rm -rf $(pwd)"
    [ -z ${BUILD_BATCH} ] && sleep 5
  fi

  ${MAKE_J} || exit 1
  [ ! -z $MAKE_CHECK ] && ${MAKE_J} -s check | tee ${BASE}/tests/avr-libc.log
  echo "Installing avr-libc"
  ${SUDO} ${MAKE_J} install || exit 1
fi

cd ${BASE}/build/

if [ ! -z ${GCC_VERSION} ]; then
  echo "Building gcc (stage 2)"
  cd gcc-${GCC_VERSION}/build-${TARGET} || exit 1

  TEMP_CFLAGS="$CFLAGS"
  TEMP_CXXFLAGS="$CXXFLAGS"
  export CFLAGS="$CFLAGS $GCC_EXTRA_CFLAGS"
  export CXXFLAGS="$CXXFLAGS $GCC_EXTRA_CXXFLAGS"

  export STAGE_CC_WRAPPER="${BASE}/script/destdir-hack.sh ${DST}/${TARGET}"
  ${MAKE_J} || exit 1
  [ ! -z $MAKE_CHECK_GCC ] && ${MAKE_J} -s check-gcc | tee ${BASE}/tests/gcc.log
  echo "Installing gcc"
  ${SUDO} ${MAKE_J} install-strip || \
  ${SUDO} ${MAKE_J} install-strip || exit 1
  ${SUDO} ${MAKE_J} -C mpfr install DESTDIR=${BASE}/build/tmpinst

  CFLAGS="$TEMP_CFLAGS"
  CXXFLAGS="$TEMP_CXXFLAGS"

  set_version gcc
fi
