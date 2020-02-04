if [ ! -z ${BINUTILS_VERSION} ]; then
  if [ ! -e binutils-${BINUTILS_VERSION}/binutils-unpacked ]; then
    echo "Unpacking binutils..."
    untar ${BINUTILS_ARCHIVE} || exit 1

    case ${BINUTILS_VERSION} in
    2.33.1) patch binutils-${BINUTILS_VERSION}/libctf/swap.h ${BASE}/patch/patch-binutils-2.33.1-swap.txt || exit 1 ;;
    2.34)   patch binutils-${BINUTILS_VERSION}/libctf/swap.h ${BASE}/patch/patch-binutils-2.34-swap.txt || exit 1 ;;
    esac

    touch binutils-${BINUTILS_VERSION}/binutils-unpacked
  fi

  cd binutils-${BINUTILS_VERSION} || exit 1
  source ${BASE}/script/build-binutils.sh
fi
