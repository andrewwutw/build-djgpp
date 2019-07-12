unset CDPATH

BASE=`pwd`

# target directory
PREFIX=${PREFIX-/usr/local/cross}

# enabled languages
#ENABLE_LANGUAGES=${ENABLE_LANGUAGES-c,c++,f95,objc,obj-c++}
ENABLE_LANGUAGES=${ENABLE_LANGUAGES-c,c++}

# number of parallel build threads
if nproc > /dev/null 2>&1 ; then
  MAKE_JOBS=${MAKE_JOBS-`nproc --all`}
else
  MAKE_JOBS=${MAKE_JOBS-`sysctl -n hw.physicalcpu`}
fi

SUDO=

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

untar()
{
  local file=$(basename $1)
  local ext=${file##*.}
  local param="-a"
  case $ext in
    xz)  param="-J" ;;
    bz2) param="-j" ;;
    gz)  param="-z" ;;
  esac
  tar -x ${param} -f ${BASE}/download/${file}
}

strip_whitespace() { eval "$1=\"`echo ${!1}`\""; }

prepend() { eval "$1=\"$2 ${!1}\""; }

download_git()
{
  local repo=$(basename $1)
  repo=${repo%.*}
  echo "Downloading ${repo}..."
  [ -d $repo ] || git clone $1 --depth 1 $([ "$2" != "" ] && echo "--branch $2")
  cd $repo || exit 1
  git reset --hard HEAD
  git checkout $2
  git pull || exit 1
  cd ..
}
