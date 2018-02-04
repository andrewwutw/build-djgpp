echo "Copy long name executables to short name."
(
  cd $PREFIX || exit 1
  SHORT_NAME_LIST="gcc g++ c++ addr2line c++filt cpp size strings dxegen dxe3gen dxe3res exe2coff stubify stubedit gdb"
  for SHORT_NAME in $SHORT_NAME_LIST; do
    if [ -f bin/${TARGET}-$SHORT_NAME ]; then
      cp -p bin/${TARGET}-$SHORT_NAME ${TARGET}/bin/$SHORT_NAME
    fi
  done
)

echo "export PATH=\"${PREFIX}/${TARGET}/bin/:${PREFIX}/bin/:\$PATH\""  >  ${PREFIX}/setenv-${TARGET}
echo "export GCC_EXEC_PREFIX=\"${PREFIX}/lib/gcc/\""                   >> ${PREFIX}/setenv-${TARGET}
echo "export MANPATH=\"${PREFIX}/share/man:\$MANPATH\""                >> ${PREFIX}/setenv-${TARGET}
echo "export INFOPATH=\"${PREFIX}/share/info:\$INFOPATH\""             >> ${PREFIX}/setenv-${TARGET}

echo "@echo off"                                >> ${PREFIX}/setenv-${TARGET}.bat
echo "PATH=%~dp0${TARGET}\\bin;%~dp0bin;%PATH%" >> ${PREFIX}/setenv-${TARGET}.bat
echo "set GCC_EXEC_PREFIX=%~dp0lib\\gcc\\"      >> ${PREFIX}/setenv-${TARGET}.bat

cd ${BASE}/build

for x in $(echo $ENABLE_LANGUAGES | tr "," " ")
do
  case $x in
    c++)
      echo "Testing C++ compiler: "
      ($PREFIX/bin/${TARGET}-c++ ../hello-cpp.cpp -o hello-cpp && echo "PASS") || echo "FAIL"
      ;;
    c)
      echo "Testing C compiler: "
      ($PREFIX/bin/${TARGET}-gcc ../hello.c -o hello && echo "PASS") || echo "FAIL"
      ;;
  esac
done

echo "Done."
echo "To remove temporary build files, use: rm -rf build/"
echo "To remove downloaded source packages, use: rm -rf download/"
