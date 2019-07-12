mkdir -p build-${TARGET}
cd build-${TARGET} || exit 1

echo "Building binutils"

BINUTILS_CONFIGURE_OPTIONS+=" --target=${TARGET} --prefix=${PREFIX} ${HOST_FLAG} ${BUILD_FLAG}"
strip_whitespace BINUTILS_CONFIGURE_OPTIONS

if [ ! -e configure-prefix ] || [ ! "`cat configure-prefix`" = "${BINUTILS_CONFIGURE_OPTIONS}" ]; then
  rm -rf *
  ../configure ${BINUTILS_CONFIGURE_OPTIONS} || exit 1
  echo ${BINUTILS_CONFIGURE_OPTIONS} > configure-prefix
else
  echo "Note: binutils already configured. To force a rebuild, use: rm -rf $(pwd)"
  sleep 5
fi

case $TARGET in
*-msdosdjgpp)
  ${MAKE} -j${MAKE_JOBS} configure-bfd || exit 1
  ${MAKE} -j${MAKE_JOBS} -C bfd stmp-lcoff-h || exit 1
  ;;
*) ;;
esac

${MAKE} -j${MAKE_JOBS} || exit 1
[ ! -z $MAKE_CHECK ] && ${MAKE} -j${MAKE_JOBS} -s check | tee ${BASE}/tests/binutils.log
echo "Installing binutils"
${SUDO} ${MAKE} -j${MAKE_JOBS} install || exit 1

${SUDO} rm -f ${PREFIX}/${TARGET}/etc/binutils-*-installed
${SUDO} touch ${PREFIX}/${TARGET}/etc/binutils-${BINUTILS_VERSION}-installed
