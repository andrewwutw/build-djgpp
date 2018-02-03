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

# copy setenv script
(cd ${BASE}/setenv/ && ./copyfile.sh $PREFIX) || exit 1

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
