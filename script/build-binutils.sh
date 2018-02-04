mkdir -p build-${TARGET}
cd build-${TARGET} || exit 1

BINUTILS_CONFIGURE_OPTIONS+=" --target=${TARGET} --prefix=${PREFIX}"
BINUTILS_CONFIGURE_OPTIONS="`echo ${BINUTILS_CONFIGURE_OPTIONS}`"

if [ ! -e configure-prefix ] || [ ! "`cat configure-prefix`" = "${BINUTILS_CONFIGURE_OPTIONS}" ]; then
  cd .. && rm -rf build-${TARGET}/ && cd - || exit 1
  ../configure ${BINUTILS_CONFIGURE_OPTIONS} || exit 1
  echo ${BINUTILS_CONFIGURE_OPTIONS} > configure-prefix
else
  echo "Note: binutils already configured. To force a rebuild, use: rm -rf $(pwd)"
  sleep 5
fi

if [ ${TARGET} == "i586-pc-msdosdjgpp" ]; then
  ${MAKE} -j${MAKE_JOBS} configure-bfd || exit 1
  ${MAKE} -j${MAKE_JOBS} -C bfd stmp-lcoff-h || exit 1
fi
${MAKE} -j${MAKE_JOBS} || exit 1

if [ ! -z $MAKE_CHECK ]; then
  echo "Run ${MAKE} check"
  ${MAKE} -j${MAKE_JOBS} check || exit 1
fi

${MAKE} -j${MAKE_JOBS} install || exit 1

rm ${PREFIX}/${TARGET}/etc/binutils-*-installed
touch ${PREFIX}/${TARGET}/etc/binutils-${BINUTILS_VERSION}-installed
