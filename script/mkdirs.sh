echo "Creating install directory: ${DST}"
[ -d ${DST} ] || ${SUDO} mkdir -p ${DST} || exit 1
[ -d ${DST}/${TARGET}/etc/ ] || ${SUDO} mkdir -p ${DST}/${TARGET}/etc/ || exit 1

export PATH="${DST}/bin:${PREFIX}/bin:$PATH"

rm -rf ${BASE}/tests
mkdir -p ${BASE}/tests
mkdir -p ${BASE}/build
