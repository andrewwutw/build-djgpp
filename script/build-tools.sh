mkdir -p ${BASE}/build/tmpinst
export PATH="${BASE}/build/tmpinst/bin:$PATH"

cd ${BASE}/build || exit 1

# build GNU sed if needed.
if [ ! -z $SED_VERSION ]; then
  if [ ! -e ${BASE}/build/tmpinst/sed-${SED_VERSION}-installed ]; then
    echo "Building sed"
    untar ${SED_ARCHIVE} || exit 1
    cd sed-${SED_VERSION}/
    ./configure --prefix=${BASE}/build/tmpinst || exit 1
    ${MAKE} -j${MAKE_JOBS} || exit 1
    ${MAKE} -j${MAKE_JOBS} install || exit 1
    touch ${BASE}/build/tmpinst/sed-${SED_VERSION}-installed
  fi
fi
