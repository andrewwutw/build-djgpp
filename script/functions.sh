unset CDPATH

BASE=`pwd`

# target directory
PREFIX=${PREFIX-/usr/local/cross}

# enabled languages
#ENABLE_LANGUAGES=${ENABLE_LANGUAGES-c,c++,f95,objc,obj-c++}
ENABLE_LANGUAGES=${ENABLE_LANGUAGES-c,c++}

# number of parallel build threads
MAKE_JOBS=${MAKE_JOBS-4}

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

untar() { tar -xavf $(ls -t ${BASE}/download/$1.tar.* | head -n 1); }

strip_whitespace() { eval "$1=\"`echo ${!1}`\""; }

prepend() { eval "$1=\"$2 ${!1}\""; }
