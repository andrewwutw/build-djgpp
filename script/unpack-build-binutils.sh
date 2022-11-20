cd ${BASE}/build/ || exit 1

if [ ! -z ${BINUTILS_VERSION} ]; then
  if [ ! -e binutils-${BINUTILS_VERSION}/binutils-unpacked ]; then
    echo "Unpacking binutils..."
    untar ${BINUTILS_ARCHIVE} || exit 1

    cd binutils-${BINUTILS_VERSION}/ || exit 1
    case ${BINUTILS_VERSION} in
    2.33.1) patch libctf/swap.h ${BASE}/patch/patch-binutils-2.33.1-swap.txt || exit 1 ;;
    2.34)   patch libctf/swap.h ${BASE}/patch/patch-binutils-2.34-swap.txt || exit 1 ;;
    esac
    cat ${BASE}/patch/binutils-${BINUTILS_VERSION}/* | patch -p1 -u || exit 1

    touch binutils-unpacked
  else
    cd binutils-${BINUTILS_VERSION}/ || exit 1
  fi

  source ${BASE}/script/build-binutils.sh
fi
