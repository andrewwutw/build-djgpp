cd ${BASE}/build

if [ ! -z ${GDB_VERSION} ]; then
  if [ ! -e gdb-${GDB_VERSION}/gdb-unpacked ]; then
    echo "Unpacking gdb..."
    untar ${GDB_ARCHIVE} || exit 1
    touch gdb-${GDB_VERSION}/gdb-unpacked
  fi
  mkdir -p gdb-${GDB_VERSION}/build-${TARGET}
  cd gdb-${GDB_VERSION}/build-${TARGET} || exit 1

  echo "Building gdb"
  
  GDB_CONFIGURE_OPTIONS+=" --target=${TARGET} --prefix=${PREFIX} ${HOST_FLAG} ${BUILD_FLAG}"
  [ -e ${BASE}/build/tmpinst${PREFIX}/lib/libmpfr.a ] && GDB_CONFIGURE_OPTIONS+=" --with-mpfr=${BASE}/build/tmpinst${PREFIX}"
  strip_whitespace GDB_CONFIGURE_OPTIONS

  if [ ! -e configure-prefix ] || [ ! "`cat configure-prefix`" = "${GDB_CONFIGURE_OPTIONS}" ]; then
    rm -rf *
    ../configure ${GDB_CONFIGURE_OPTIONS} || exit 1
    echo ${GDB_CONFIGURE_OPTIONS} > configure-prefix
  else
    echo "Note: gdb already configured. To force a rebuild, use: rm -rf $(pwd)"
    [ -z ${BUILD_BATCH} ] && sleep 5
  fi
  ${MAKE_J} || exit 1
  [ ! -z $MAKE_CHECK ] && ${MAKE_J} -s check | tee ${BASE}/tests/gdb.log
  echo "Installing gdb"
  ${SUDO} ${MAKE_J} install || exit 1

  ${SUDO} rm -f ${DST}/${TARGET}/etc/gdb-*-installed
  ${SUDO} touch ${DST}/${TARGET}/etc/gdb-${GDB_VERSION}-installed
fi
