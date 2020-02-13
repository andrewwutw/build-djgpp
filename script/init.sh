unset CDPATH
unset SUDO
unset MAKEFLAGS
unset INSTALL

BASE=`pwd`

# number of parallel build threads
if nproc > /dev/null 2>&1 ; then
  MAKE_JOBS=${MAKE_JOBS-`nproc --all`}
else
  MAKE_JOBS=${MAKE_JOBS-`sysctl -n hw.physicalcpu`}
fi

# use gmake/clang under FreeBSD
if [ `uname` = "FreeBSD" ]; then
  MAKE=${MAKE-gmake}
  CC=${CC-clang}
  CXX=${CXX-clang++}
else
  MAKE=${MAKE-make}
  CC=${CC-gcc}
  CXX=${CXX-g++}
fi

MAKE_J="${MAKE} -j${MAKE_JOBS}"

case `uname -s` in
Darwin*) ;;
*) MAKE_J+=" -Otarget" ;;
esac

export CC CXX MAKE

[ ! -z ${BUILD} ] && BUILD_FLAG="--build=${BUILD}"
if [ ! -z ${HOST} ]; then
  HOST_FLAG="--host=${HOST}"
  IGNORE_DEPENDENCIES=yes
  HOST_CC=${HOST_CC-$HOST-$CC}
  HOST_CXX=${HOST_CXX-$HOST-$CXX}
else
  HOST_FLAG=""
  HOST_CC=${CC}
  HOST_CXX=${CXX}
fi

CFLAGS_FOR_TARGET=${CFLAGS_FOR_TARGET:-"-O2 -g"}
CXXFLAGS_FOR_TARGET=${CXXFLAGS_FOR_TARGET:-"-O2 -g"}

untar()
{
  [ -z $1 ] && return
  local file=$(basename $1)
  local ext=${file##*.}
  local param="-a"
  case $ext in
    xz)  param="-J" ;;
    bz2) param="-j" ;;
    gz)  param="-z" ;;
    tar) param=""   ;;
  esac
  tar -x ${param} -f ${BASE}/download/${file} || exit 1
}

strip_whitespace() { eval "$1=\"`echo ${!1}`\""; }

prepend() { eval "$1=\"$2 ${!1}\""; }

add_pkg()
{
  for DIR in ${PACKAGE_SOURCES}; do
    if [ -e $DIR/$1 ]; then
      source $DIR/$1
      return
    fi
  done
  echo "Unrecognized option or invalid package: $1"
  exit 1
}

if [ -z $1 ]; then
  echo "Usage: $0 [options...] [packages...]"
  echo "Supported options:"
  echo "    --prefix=[...]"
  echo "    --target=[...]"
  echo "    --enable-languages=[...]"
  echo "Supported packages:"
  for DIR in ${PACKAGE_SOURCES}; do
    ls $DIR
  done
  exit 1
fi

for A in "$@"; do
  case $A in
  --no-download) NO_DOWNLOAD=y ;;
  --only-download) ONLY_DOWNLOAD=y ;;
  --ignore-dependencies) IGNORE_DEPENDENCIES=y ;;
  --batch) BUILD_BATCH=y ;;
  --destdir=*) DESTDIR=${A#*=} ;;
  --prefix=*) PREFIX=${A#*=} ;;
  --target=*) TARGET=${A#*=} ;;
  --enable-languages=*) ENABLE_LANGUAGES=${A#*=} ;;
  *) add_pkg $A ;;
  esac
done

# install directory
PREFIX=${PREFIX-/usr/local/cross}

# enabled languages
#ENABLE_LANGUAGES=${ENABLE_LANGUAGES-c,c++,f95,objc,obj-c++}
ENABLE_LANGUAGES=${ENABLE_LANGUAGES-c,c++}
