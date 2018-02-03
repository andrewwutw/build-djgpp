mkdir -p ${BASE}/build/tmpinst
export PATH="${BASE}/build/tmpinst/:$PATH"

# build GNU tar if needed.
TAR=tar
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
  TAR=${BASE}/build/tmpinst/bin/tar
fi

untar()
{
  ${TAR} -xavf $(ls -t ${BASE}/download/$1.tar.* | head -n 1)
}

cd ${BASE}/build || exit 1

# build GNU sed if needed.
SED=sed
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
  SED=${BASE}/build/tmpinst/bin/sed
fi

cd ${BASE}/build || exit 1
