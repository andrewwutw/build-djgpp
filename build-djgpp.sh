#! /bin/sh

# target directory
DJGPP_PREFIX=/usr/local/djgpp

#enabled languages
#ENABLE_LANGUAGES=c,c++,f95,objc,obj-c++
ENABLE_LANGUAGES=c,c++

# source tarball versions
BINUTILS_VERSION=224
DJCRX_VERSION=204
SED_VERSION=4.2.2

GCC_VERSION=4.8.2
GCC_VERSION_SHORT=4.82
GMP_VERSION=5.1.2
MPFR_VERSION=3.1.2
MPC_VERSION=1.0.1
AUTOCONF_VERSION=2.64
AUTOMAKE_VERSION=1.11.1

# tarball location
BINUTILS_ARCHIVE="ftp://ftp.delorie.com/pub/djgpp/current/v2gnu/bnu${BINUTILS_VERSION}s.zip"
DJCRX_ARCHIVE="http://ap1.pp.fi/djgpp/djdev/djgpp/20130326/djcrx${DJCRX_VERSION}.zip"
SED_ARCHIVE="http://ftp.gnu.org/gnu/sed/sed-${SED_VERSION}.tar.bz2"

DJCROSS_GCC_ARCHIVE="ftp://ftp.delorie.com/pub/djgpp/rpms/djcross-gcc-${GCC_VERSION}/djcross-gcc-${GCC_VERSION}.tar.bz2"
GCC_ARCHIVE="http://ftpmirror.gnu.org/gcc/gcc-${GCC_VERSION}/gcc-${GCC_VERSION}.tar.bz2"
GMP_ARCHIVE="http://ftpmirror.gnu.org/gmp/gmp-${GMP_VERSION}.tar.bz2"
MPFR_ARCHIVE="http://ftpmirror.gnu.org/mpfr/mpfr-${MPFR_VERSION}.tar.bz2"
MPC_ARCHIVE="http://ftpmirror.gnu.org/mpc/mpc-${MPC_VERSION}.tar.gz"
AUTOCONF_ARCHIVE="http://ftp.gnu.org/gnu/autoconf/autoconf-${AUTOCONF_VERSION}.tar.bz2"
AUTOMAKE_ARCHIVE="http://ftp.gnu.org/gnu/automake/automake-${AUTOMAKE_VERSION}.tar.bz2"

# check required programs
REQ_PROG_LIST="gcc curl unzip"

for REQ_PROG in $REQ_PROG_LIST; do
  if ! which $REQ_PROG > /dev/null; then
    echo "$REQ_PROG not installed"
    exit 1
  fi
done

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
  test -f $FILE || (
    echo "Download $ARCHIVE ..."
    curl $ARCHIVE -L -o $FILE || exit 1
  )
done
cd ..

# make build dir
rm -rf build || exit 1
mkdir -p build || exit 1
cd build

# build binutils
echo "Building bintuils"
mkdir bnu${BINUTILS_VERSION}s
cd bnu${BINUTILS_VERSION}s
unzip ../../download/bnu${BINUTILS_VERSION}s.zip || exit 1
cd gnu/bnutl-* || exit

# install-sh exec permission is not set, fix it.
chmod a+x install-sh

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

make check || exit 1

sudo make install || exit 1

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

sudo mkdir -p $DJGPP_PREFIX/i586-pc-msdosdjgpp/sys-include || exit 1
sudo cp -rp include/* $DJGPP_PREFIX/i586-pc-msdosdjgpp/sys-include/ || exit 1
sudo cp -rp lib $DJGPP_PREFIX/i586-pc-msdosdjgpp/ || exit 1
sudo cp -p src/stub/stubify $DJGPP_PREFIX/i586-pc-msdosdjgpp/bin/ || exit 1
sudo cp -p src/stub/stubedit $DJGPP_PREFIX/i586-pc-msdosdjgpp/bin/ || exit 1

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
PATH=$BUILDDIR//tmpinst/bin:$PATH \
./configure --prefix=$BUILDDIR/tmpinst || exit 1
PATH=$BUILDDIR//tmpinst/bin:$PATH \
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

echo "Running unpack-gcc.sh"
PATH="$BUILDDIR/tmpinst/bin:$PATH" sh unpack-gcc.sh --no-djgpp-source ../../download/gcc-${GCC_VERSION}.tar.bz2

# copy stubify programs
cp $DJGPP_PREFIX/i586-pc-msdosdjgpp/bin/stubify $BUILDDIR/tmpinst/bin

echo "Building gmp"
cd $BUILDDIR/gmp-${GMP_VERSION}/
./configure --prefix=$BUILDDIR/tmpinst --enable-static --disable-shared || exit 1
make all || exit 1
make check || exit 1
make install || exit 1

echo "Building mpfr"
cd $BUILDDIR/mpfr-${MPFR_VERSION}/
./configure --prefix=$BUILDDIR/tmpinst --with-gmp-build=$BUILDDIR/gmp-${GMP_VERSION} --enable-static --disable-shared || exit 1
make all || exit 1
make check || exit 1
make install || exit 1

echo "Building mpc"
cd $BUILDDIR/mpc-1.0.1/
./configure --prefix=$BUILDDIR/tmpinst --with-gmp=$BUILDDIR/tmpinst --with-mpfr=$BUILDDIR/tmpinst --enable-static --disable-shared || exit 1
make all || exit 1
make check || exit 1
make install || exit 1

echo "Building gcc"
cd $BUILDDIR/

mkdir djcross
cd djcross

PATH=$BUILDDIR//tmpinst/bin:$PATH \
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

make j=4 PATH=$BUILDDIR/tmpinst/bin:$PATH || exit 1

sudo make install || exit 1

# gcc done

echo "Use DJGPP to build a test program."
cd $BUILDDIR
cd ..
$DJGPP_PREFIX/bin/i586-pc-msdosdjgpp-c++ ../hello.cpp -o hello || exit 1

echo "build-djgpp.sh done."
