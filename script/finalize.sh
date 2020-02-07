echo "Copy long name executables to short name."
(
  cd $PREFIX || exit 1
  ${SUDO} mkdir -p ${TARGET}/bin
  SHORT_NAME_LIST="gcc g++ c++ addr2line c++filt cpp size strings dxegen dxe3gen dxe3res exe2coff stubify stubedit gdb djasm"
  for SHORT_NAME in $SHORT_NAME_LIST; do
    if [ -f bin/${TARGET}-$SHORT_NAME ]; then
      ${SUDO} cp -p bin/${TARGET}-$SHORT_NAME ${TARGET}/bin/$SHORT_NAME
    fi
  done
  ${SUDO} cp -p bin/${TARGET}-g++ bin/${TARGET}-g++-${GCC_VERSION}
)

cat << STOP > ${BASE}/build/${TARGET}-setenv
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

echo "Installing ${TARGET}-setenv"
chmod +x ${BASE}/build/${TARGET}-setenv
${SUDO} cp -p ${BASE}/build/${TARGET}-setenv ${PREFIX}/bin/
case `uname` in
MINGW*) ;&
MSYS*) cp -p ${BASE}/build/setenv-${TARGET}.cmd ${PREFIX}/bin/ 2> /dev/null ;;
esac

if [ ! -z "`ls ${PREFIX}/${TARGET}/etc/gcc-*-installed 2> /dev/null`" ]; then
  for x in $(echo $ENABLE_LANGUAGES | tr "," " ")
  do
    case $x in
      c++)
        echo "Testing C++ compiler: "
        ($PREFIX/bin/${TARGET}-c++ ${BASE}/script/hello.c -o hello && echo "PASS") || echo "FAIL"
        ;;
      c)
        echo "Testing C compiler: "
        if $PREFIX/bin/${TARGET}-gcc ${BASE}/script/hello.c -o hello; then
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
