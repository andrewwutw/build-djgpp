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

    echo "Unpacking gcc dependencies"
    pushd gcc-${GCC_VERSION} || exit 1

    for URL in $GMP_ARCHIVE $MPFR_ARCHIVE $MPC_ARCHIVE $ISL_ARCHIVE; do
        FILE=`basename $URL`
        untar ${FILE}
        mv ${FILE%.*.*} ${FILE%%-*} || exit 1
    done

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

  ${MAKE} -j${MAKE_JOBS} all-gcc || exit 1
  echo "Installing gcc (stage 1)"
  ${SUDO} ${MAKE} -j${MAKE_JOBS} install-gcc || exit 1

  export CFLAGS="$TEMP_CFLAGS"
fi

cd ${BASE}/build/

if [ ! -z ${NEWLIB_VERSION} ]; then
  echo "Building newlib"
  mkdir -p newlib-${NEWLIB_VERSION}/build-${TARGET}
  cd newlib-${NEWLIB_VERSION}/build-${TARGET} || exit 1

  NEWLIB_CONFIGURE_OPTIONS+=" --target=${TARGET} --prefix=${PREFIX} ${HOST_FLAG} ${BUILD_FLAG}"
  strip_whitespace NEWLIB_CONFIGURE_OPTIONS

  if [ ! -e configure-prefix ] || [ ! "`cat configure-prefix`" == "${NEWLIB_CONFIGURE_OPTIONS}" ]; then
    rm -rf *
    ../configure ${NEWLIB_CONFIGURE_OPTIONS} || exit 1
    echo ${NEWLIB_CONFIGURE_OPTIONS} > configure-prefix
  else
    echo "Note: newlib already configured. To force a rebuild, use: rm -rf $(pwd)"
    [ -z ${BUILD_BATCH} ] && sleep 5
  fi

  ${MAKE} -j${MAKE_JOBS} || exit 1
  [ ! -z $MAKE_CHECK ] && ${MAKE} -j${MAKE_JOBS} -s check | tee ${BASE}/tests/newlib.log
  echo "Installing newlib"
  ${SUDO} ${MAKE} -j${MAKE_JOBS} install || \
  ${SUDO} ${MAKE} -j${MAKE_JOBS} install || exit 1
fi

cd ${BASE}/build/

if [ ! -z ${GCC_VERSION} ]; then
  echo "Building gcc (stage 2)"
  cd gcc-${GCC_VERSION}/build-${TARGET} || exit 1

  export STAGE_CC_WRAPPER="${BASE}/script/destdir-hack.sh ${DST}/${TARGET}"
  ${MAKE} -j${MAKE_JOBS} || exit 1
  [ ! -z $MAKE_CHECK_GCC ] && ${MAKE} -j${MAKE_JOBS} -s check-gcc | tee ${BASE}/tests/gcc.log
  echo "Installing gcc"
  ${SUDO} ${MAKE} -j${MAKE_JOBS} install-strip || \
  ${SUDO} ${MAKE} -j${MAKE_JOBS} install-strip || exit 1
  ${SUDO} ${MAKE} -j${MAKE_JOBS} -C mpfr install

  ${SUDO} rm -f ${DST}/${TARGET}/etc/gcc-*-installed
  ${SUDO} touch ${DST}/${TARGET}/etc/gcc-${GCC_VERSION}-installed
fi
