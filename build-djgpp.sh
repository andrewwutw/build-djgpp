#! /bin/sh

# target directory
DJGPP_PREFIX=/usr/local/djgpp

# source tarball versions
BINUTILS_VERSION=224
DJCRX_VERSION=204
SED_VERSION=4.2.2

GCC_VERSION=4.8.2
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

# check gcc is installed
if ! which gcc > /dev/null; then
  echo "gcc not installed"
  exit 1
fi

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

# make build dir
rm -rf build || exit 1
mkdir -p build || exit 1
cd build

# build binutils
mkdir bnu224s
cd bnu224s
unzip ../../download/bnu224s.zip || exit 1
cd gnu/bnutl-2.24/

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
mkdir djcrx204
cd djcrx204
unzip ../../download/djcrx204.zip || exit 1

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
tar -xjvf ../download/djcross-gcc-4.8.2.tar.bz2 || exit 1
cd djcross-gcc-4.8.2/

BUILDDIR=`pwd`

tar xjf ../../download/autoconf-2.64.tar.bz2 || exit 1
cd autoconf-2.64/
./configure --prefix=$BUILDDIR/tmpinst || exit 1
make all install || exit 1

cd $BUILDDIR
tar xjf ../../download/automake-1.11.1.tar.bz2 || exit 1
cd automake-1.11.1/
./configure --prefix=$BUILDDIR/tmpinst || exit 1
make all install || exit 1

# OSX built-in sed has problem, build GNU sed.
cd $BUILDDIR
tar xjf ../../download/sed-4.2.2.tar.bz2 || exit 1
cd sed-4.2.2/
./configure --prefix=$BUILDDIR/tmpinst || exit 1
make all install || exit 1

cd $BUILDDIR
tar xjf ../../download/gmp-5.1.2.tar.bz2 || exit 1
tar xjf ../../download/mpfr-3.1.2.tar.bz2 || exit 1
tar xzf ../../download/mpc-1.0.1.tar.gz || exit 1

PATH="$BUILDDIR/tmpinst/bin:$PATH" sh unpack-gcc.sh --no-djgpp-source ../../download/gcc-4.8.2.tar.bz2

# copy stubify programs
cp $DJGPP_PREFIX/i586-pc-msdosdjgpp/bin/stubify $BUILDDIR/tmpinst/bin

cd $BUILDDIR/gmp-5.1.2/
./configure --prefix=$BUILDDIR/tmpinst --enable-static --disable-shared || exit 1
make all || exit 1
make check || exit 1
make install || exit 1

cd $BUILDDIR/mpfr-3.1.2/
./configure --prefix=$BUILDDIR/tmpinst --with-gmp-build=$BUILDDIR/gmp-5.1.2 --enable-static --disable-shared || exit 1
make all || exit 1
make check || exit 1
make install || exit 1

cd $BUILDDIR/mpc-1.0.1/
./configure --prefix=$BUILDDIR/tmpinst --with-gmp=$BUILDDIR/tmpinst --with-mpfr=$BUILDDIR/tmpinst --enable-static --disable-shared || exit 1
make all || exit 1
make check || exit 1
make install || exit 1

cd $BUILDDIR/

mkdir djcross
cd djcross

PATH=$BUILDDIR//tmpinst/bin:$PATH \
../gnu/gcc-4.82/configure \
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
                                 --enable-languages=c,c++,f95,objc,obj-c++ \
                                 || exit 1

make j=4 PATH=$BUILDDIR/tmpinst/bin:$PATH || exit 1

sudo make install || exit 1

# gcc done

echo "build-djgpp.sh done"
