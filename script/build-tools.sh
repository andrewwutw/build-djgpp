mkdir -p ${BASE}/build/tmpinst
export PATH="${BASE}/build/tmpinst/bin:$PATH"

cd ${BASE}/build/ || exit 1

# build GNU tar if needed.
if [ ! -z $TAR_VERSION ]; then
  if [ ! -e ${BASE}/build/tmpinst/tar-${TAR_VERSION}-installed ]; then
    echo "Building tar"
    tar -xJvf ${BASE}/download/tar-${TAR_VERSION}.tar.xz || exit 1
    cd tar-${TAR_VERSION}/
    ./configure --prefix=${BASE}/build/tmpinst || exit 1
    ${MAKE} -j${MAKE_JOBS} || exit 1
    ${MAKE} -j${MAKE_JOBS} install || exit 1
    touch ${BASE}/build/tmpinst/tar-${TAR_VERSION}-installed
  fi
fi

cd ${BASE}/build || exit 1

# build GNU sed if needed.
if [ ! -z $SED_VERSION ]; then
  if [ ! -e ${BASE}/build/tmpinst/sed-${SED_VERSION}-installed ]; then
    echo "Building sed"
    untar sed-${SED_VERSION} || exit 1
    cd sed-${SED_VERSION}/
    ./configure --prefix=${BASE}/build/tmpinst || exit 1
    ${MAKE} -j${MAKE_JOBS} || exit 1
    ${MAKE} -j${MAKE_JOBS} install || exit 1
    touch ${BASE}/build/tmpinst/sed-${SED_VERSION}-installed
  fi
fi
