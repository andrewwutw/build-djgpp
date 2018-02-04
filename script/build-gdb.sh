if [ ! -z ${GDB_VERSION} ]; then
  if [ ! -e gdb-${GDB_VERSION}/gdb-unpacked ]; then
    echo "Unpacking gdb."
    untar gdb-${GDB_VERSION} || exit 1
    touch gdb-${GDB_VERSION}/gdb-unpacked
  fi
  mkdir -p gdb-${GDB_VERSION}/build-${TARGET}
  cd gdb-${GDB_VERSION}/build-${TARGET} || exit 1

  echo "Building gdb."
  
  GDB_CONFIGURE_OPTIONS+=" --target=${TARGET} --prefix=${PREFIX}"
  GDB_CONFIGURE_OPTIONS="`echo ${GDB_CONFIGURE_OPTIONS}`"

  if [ ! -e configure-prefix ] || [ ! "`cat configure-prefix`" = "${GDB_CONFIGURE_OPTIONS}" ]; then
    rm -rf *
    ../configure ${GDB_CONFIGURE_OPTIONS} || exit 1
    echo ${GDB_CONFIGURE_OPTIONS} > configure-prefix
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

  rm ${PREFIX}/${TARGET}/etc/gdb-*-installed
  touch ${PREFIX}/${TARGET}/etc/gdb-${GDB_VERSION}-installed
fi
