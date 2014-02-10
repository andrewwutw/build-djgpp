#! /bin/sh

# target directory
DJGPP_PREFIX=${DJGPP_PREFIX-/usr/local/djgpp}

# enabled languages
#ENABLE_LANGUAGES=${ENABLE_LANGUAGES-c,c++,f95,objc,obj-c++}
ENABLE_LANGUAGES=${ENABLE_LANGUAGES-c,c++}

OPT_FILE=${OPT_FILE-gcc482.opt}

# loading tarball version and location from option file
echo "Load setting file from $OPT_FILE"
source $OPT_FILE

# check required programs
REQ_PROG_LIST="g++ gcc curl unzip bison flex make makeinfo patch"

for REQ_PROG in $REQ_PROG_LIST; do
  if ! which $REQ_PROG > /dev/null; then
    echo "$REQ_PROG not installed"
    exit 1
  fi
done

# check zlib is installed
if ! gcc test-zlib.c -o test-zlib -lz; then
  echo "zlib not installed"
  exit 1
fi
rm test-zlib

# download source files
ARCHIVE_LIST="$BINUTILS_ARCHIVE $DJCRX_ARCHIVE $SED_ARCHIVE
              $DJCROSS_GCC_ARCHIVE $GCC_ARCHIVE
              $GMP_ARCHIVE $MPFR_ARCHIVE $MPC_ARCHIVE
              $AUTOCONF_ARCHIVE $AUTOMAKE_ARCHIVE"

echo "Download source files..."
mkdir -p download || exit 1
cd download

for ARCHIVE in $ARCHIVE_LIST; do
  FILE=`basename $ARCHIVE`
  if ! [ -f $FILE ]; then
    echo "Download $ARCHIVE ..."
    curl $ARCHIVE -L -o $FILE || exit 1
  fi
done
cd ..

# create target directory, check writable.
echo "Make prefix directory : $DJGPP_PREFIX"
mkdir -p $DJGPP_PREFIX

if ! [ -d $DJGPP_PREFIX ]; then
  echo "Unable to create prefix directory"
  exit 1
fi

if ! [ -w $DJGPP_PREFIX ]; then
  echo "prefix directory is not writable."
  exit 1
fi

# make build dir
echo "Make build dir"
rm -rf build || exit 1
mkdir -p build || exit 1
cd build

# build binutils
echo "Building bintuils"
mkdir bnu${BINUTILS_VERSION}s
cd bnu${BINUTILS_VERSION}s
unzip ../../download/bnu${BINUTILS_VERSION}s.zip || exit 1
cd gnu/bnutl-* || exit

# exec permission of some files are not set, fix it.
for EXEC_FILE in install-sh missing; do
  echo "chmod a+x $EXEC_FILE"
  chmod a+x $EXEC_FILE || exit 1
done

sh ./configure \
           --prefix=$DJGPP_PREFIX \
           --target=i586-pc-msdosdjgpp \
           --program-prefix=i586-pc-msdosdjgpp- \
           --disable-werror \
           --disable-nls \
           || exit 1

make configure-bfd || exit 1
make -C bfd stmp-lcoff-h || exit 1
make || exit 1

if [ ! -z $MAKE_CHECK ]; then
  echo "Run make check"
  make check || exit 1
fi

make install || exit 1

cd ../../..
# binutils done

# prepare djcrx
echo "Prepare djcrx"
mkdir djcrx${DJCRX_VERSION}
cd djcrx${DJCRX_VERSION}
unzip ../../download/djcrx${DJCRX_VERSION}.zip || exit 1

cd src/stub
gcc -O2 stubify.c -o stubify || exit 1
gcc -O2 stubedit.c -o stubedit || exit 1

cd ../..

mkdir -p $DJGPP_PREFIX/i586-pc-msdosdjgpp/sys-include || exit 1
cp -rp include/* $DJGPP_PREFIX/i586-pc-msdosdjgpp/sys-include/ || exit 1
cp -rp lib $DJGPP_PREFIX/i586-pc-msdosdjgpp/ || exit 1
cp -p src/stub/stubify $DJGPP_PREFIX/i586-pc-msdosdjgpp/bin/ || exit 1
cp -p src/stub/stubedit $DJGPP_PREFIX/i586-pc-msdosdjgpp/bin/ || exit 1

cd ..
# djcrx done

# build gcc
tar -xjvf ../download/djcross-gcc-${GCC_VERSION}.tar.bz2 || exit 1
cd djcross-gcc-${GCC_VERSION}/

BUILDDIR=`pwd`

echo "Building autoconf"
cd $BUILDDIR
tar xjf ../../download/autoconf-${AUTOCONF_VERSION}.tar.bz2 || exit 1
cd autoconf-${AUTOCONF_VERSION}/
./configure --prefix=$BUILDDIR/tmpinst || exit 1
make all install || exit 1

echo "Building automake"
cd $BUILDDIR
tar xjf ../../download/automake-${AUTOMAKE_VERSION}.tar.bz2 || exit 1
cd automake-${AUTOMAKE_VERSION}/
PATH="$BUILDDIR//tmpinst/bin:$PATH" \
./configure --prefix=$BUILDDIR/tmpinst || exit 1
PATH="$BUILDDIR//tmpinst/bin:$PATH" \
make all install || exit 1

# OSX built-in sed has problem, build GNU sed.
echo "Building sed"
cd $BUILDDIR
tar xjf ../../download/sed-${SED_VERSION}.tar.bz2 || exit 1
cd sed-${SED_VERSION}/
./configure --prefix=$BUILDDIR/tmpinst || exit 1
make all install || exit 1

cd $BUILDDIR
tar xjf ../../download/gmp-${GMP_VERSION}.tar.bz2 || exit 1
tar xjf ../../download/mpfr-${MPFR_VERSION}.tar.bz2 || exit 1
tar xzf ../../download/mpc-${MPC_VERSION}.tar.gz || exit 1

if [ ! -z $PATCH_UNPACK_GCC_SH ]; then
  echo "Patch unpack-gcc.sh"
  patch unpack-gcc.sh ../../${PATCH_UNPACK_GCC_SH} || exit 1
fi

echo "Running unpack-gcc.sh"
PATH="$BUILDDIR/tmpinst/bin:$PATH" sh unpack-gcc.sh --no-djgpp-source ../../download/gcc-${GCC_VERSION}.tar.bz2

# copy stubify programs
cp $DJGPP_PREFIX/i586-pc-msdosdjgpp/bin/stubify $BUILDDIR/tmpinst/bin

echo "Building gmp"
cd $BUILDDIR/gmp-${GMP_VERSION}/
./configure --prefix=$BUILDDIR/tmpinst --enable-static --disable-shared || exit 1
make all || exit 1
if [ ! -z $MAKE_CHECK ]; then
  echo "Run make check"
  make check || exit 1
fi
make install || exit 1

echo "Building mpfr"
cd $BUILDDIR/mpfr-${MPFR_VERSION}/
./configure --prefix=$BUILDDIR/tmpinst --with-gmp-build=$BUILDDIR/gmp-${GMP_VERSION} --enable-static --disable-shared || exit 1
make all || exit 1
if [ ! -z $MAKE_CHECK ]; then
  echo "Run make check"
  make check || exit 1
fi
make install || exit 1

echo "Building mpc"
cd $BUILDDIR/mpc-${MPC_VERSION}/
./configure --prefix=$BUILDDIR/tmpinst --with-gmp=$BUILDDIR/tmpinst --with-mpfr=$BUILDDIR/tmpinst --enable-static --disable-shared || exit 1
make all || exit 1
if [ ! -z $MAKE_CHECK ]; then
  echo "Run make check"
  make check || exit 1
fi
make install || exit 1

echo "Building gcc"
cd $BUILDDIR/

mkdir djcross
cd djcross

PATH="$BUILDDIR//tmpinst/bin:$PATH" \
../gnu/gcc-${GCC_VERSION_SHORT}/configure \
                                 --target=i586-pc-msdosdjgpp \
                                 --program-prefix=i586-pc-msdosdjgpp- \
                                 --prefix=$DJGPP_PREFIX \
                                 --disable-nls \
                                 --disable-lto \
                                 --enable-libquadmath-support \
                                 --with-gmp=$BUILDDIR/tmpinst \
                                 --with-mpfr=$BUILDDIR/tmpinst \
                                 --with-mpc=$BUILDDIR/tmpinst \
                                 --enable-version-specific-runtime-libs \
                                 --enable-languages=${ENABLE_LANGUAGES} \
                                 || exit 1

make j=4 "PATH=$BUILDDIR/tmpinst/bin:$PATH" || exit 1

make install || exit 1

# gcc done

echo "Use DJGPP to build a test program."
cd $BUILDDIR
cd ..
$DJGPP_PREFIX/bin/i586-pc-msdosdjgpp-c++ ../hello.cpp -o hello || exit 1

echo "build-djgpp.sh done."
