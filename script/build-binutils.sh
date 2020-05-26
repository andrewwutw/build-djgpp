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
  [ -z ${BUILD_BATCH} ] && sleep 5
fi

case $TARGET in
*-msdosdjgpp)
  ${MAKE_J} configure-bfd || exit 1
  ${MAKE_J} -C bfd stmp-lcoff-h || exit 1
  ;;
*) ;;
esac

${MAKE_J} || exit 1
[ ! -z $MAKE_CHECK ] && ${MAKE_J} -s check | tee ${BASE}/tests/binutils.log
echo "Installing binutils"
${SUDO} ${MAKE_J} install || exit 1

${SUDO} rm -f ${DST}/${TARGET}/etc/binutils-*-installed
${SUDO} touch ${DST}/${TARGET}/etc/binutils-${BINUTILS_VERSION}-installed
