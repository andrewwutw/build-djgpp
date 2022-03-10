echo "Copy long name executables to short name."
pushd ${DST} || exit 1
${SUDO} mkdir -p ${TARGET}/bin
SHORT_NAME_LIST="dxegen dxe3gen dxe3res exe2coff stubify stubedit djasm gdb
                 g++ c++ cpp gcc gprof gcc-nm gcov-tool gcc-ranlib gcc-ar gcov-dump gcov
                 strings ld readelf ld.bfd size addr2line setenv strip objcopy c++filt ar gprof ranlib as nm elfedit objdump"
for SHORT_NAME in $SHORT_NAME_LIST; do
  if [ -f bin/${TARGET}-$SHORT_NAME ]; then
    ${SUDO} cp -p bin/${TARGET}-$SHORT_NAME ${TARGET}/bin/$SHORT_NAME
  fi
done
if [ ! -z ${GCC_VERSION} ]; then
  ${SUDO} cp -p bin/${TARGET}-gcc bin/${TARGET}-gcc-${GCC_VERSION} 2> /dev/null
  ${SUDO} cp -p bin/${TARGET}-g++ bin/${TARGET}-g++-${GCC_VERSION} 2> /dev/null
  ${SUDO} cp -p ${TARGET}/bin/gcc ${TARGET}/bin/gcc-${GCC_VERSION} 2> /dev/null
  ${SUDO} cp -p ${TARGET}/bin/g++ ${TARGET}/bin/g++-${GCC_VERSION} 2> /dev/null
fi
popd

cat << STOP > ${BASE}/build/${TARGET}-setenv
#!/usr/bin/env bash
if ! (return 2> /dev/null); then
  echo "This script must be executed with 'source' to set environment variables:"
  echo "source \$0"
  exit 1
fi
export PATH="${PREFIX}/${TARGET}/bin/:${PREFIX}/bin/:\$PATH"
export GCC_EXEC_PREFIX="${PREFIX}/lib/gcc/"
export MANPATH="${PREFIX}/${TARGET}/share/man:${PREFIX}/share/man:\$MANPATH"
export INFOPATH="${PREFIX}/${TARGET}/share/info:${PREFIX}/share/info:\$INFOPATH"
STOP

cat << STOP > ${BASE}/build/${TARGET}-setenv.cmd
@echo off
PATH=%~dp0..\\${TARGET}\\bin;%~dp0..\\bin;%PATH%
set GCC_EXEC_PREFIX=%~dp0..\\lib\\gcc\\
STOP

case $TARGET in
*-msdosdjgpp)
  echo "export DJDIR=\"${PREFIX}/${TARGET}\""   >> ${BASE}/build/${TARGET}-setenv
  echo "set DJDIR=%~dp0..\\${TARGET}"           >> ${BASE}/build/${TARGET}-setenv.cmd
  ;;
esac

if [ ! -z "$(get_version watt32)" ]; then
  WATT_ROOT="${PREFIX}/${TARGET}/watt"
  WATT_INCLUDE="${WATT_ROOT}/inc"
  echo "export WATT_ROOT=\"${WATT_ROOT}\"" >> ${BASE}/build/${TARGET}-setenv
  case $(uname) in
  MSYS*|MINGW*)
    WATT_ROOT="$(cygpath -w "$WATT_ROOT")"
    WATT_INCLUDE="$(cygpath -w "$WATT_INCLUDE")"
    ;;
  esac
  echo "set WATT_ROOT=\"${WATT_ROOT}\"" >> ${BASE}/build/${TARGET}-setenv.cmd

  ${TARGET}-gcc -dumpspecs > ${BASE}/build/specs
  sed -i "/\*cpp:/{n;s#\(.*\)#-isystem ${WATT_INCLUDE} \1#}" ${BASE}/build/specs
  sed -i "/\*cc1plus:/{n;s#\(.*\)#-isystem ${WATT_INCLUDE} \1#}" ${BASE}/build/specs

  echo "Installing specs file"
  ${SUDO} cp ${BASE}/build/specs ${DST}/lib/gcc/${TARGET}/$(get_version gcc)/ || exit 1
fi

case $TARGET in
i586-pc-msdosdjgpp) ;;
*-pc-msdosdjgpp) cat << STOP > ${BASE}/build/${TARGET}-link-i586
#!/usr/bin/env bash
echo "Linking i586-pc-msdosdjgpp-* to ${TARGET}-*"
for PROG in ${PREFIX}/bin/${TARGET}-*; do
  ln -fs \`basename \$PROG\` \${PROG/$TARGET/i586-pc-msdosdjgpp}
done
STOP
  echo "Installing ${TARGET}-link-i586"
  chmod +x ${BASE}/build/${TARGET}-link-i586
  ${SUDO} cp -p ${BASE}/build/${TARGET}-link-i586 ${DST}/bin/
  ;;
*) ;;
esac

echo "Installing ${TARGET}-setenv"
chmod +x ${BASE}/build/${TARGET}-setenv
${SUDO} cp -p ${BASE}/build/${TARGET}-setenv ${DST}/bin/
case `uname` in
MINGW*) ;&
MSYS*) cp -p ${BASE}/build/setenv-${TARGET}.cmd ${DST}/bin/ 2> /dev/null ;;
esac

if [ ! -z "$(get_version gcc)" ]; then
  for x in $(echo $ENABLE_LANGUAGES | tr "," " ")
  do
    case $x in
      c++)
        echo "Testing C++ compiler: "
        (${DST}/bin/${TARGET}-c++ ${BASE}/script/hello.c -o hello && echo "PASS") || echo "FAIL"
        ;;
      c)
        echo "Testing C compiler: "
        if ${DST}/bin/${TARGET}-gcc ${BASE}/script/hello.c -o hello; then
          echo "PASS"
        else
          echo "FAIL"
          exit 1
        fi
        ;;
    esac
  done
fi

echo "Done."
echo "To remove temporary build files, use: rm -rf build/"
echo "To remove downloaded source packages, use: rm -rf download/"
