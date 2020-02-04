echo "Creating install directory: ${PREFIX}"
[ -d ${PREFIX} ] || ${SUDO} mkdir -p ${PREFIX} || exit 1
[ -d ${PREFIX}/${TARGET}/etc/ ] || ${SUDO} mkdir -p ${PREFIX}/${TARGET}/etc/ || exit 1

export PATH="${PREFIX}/bin:$PATH"

rm -rf ${BASE}/tests
mkdir -p ${BASE}/tests
mkdir -p ${BASE}/build
