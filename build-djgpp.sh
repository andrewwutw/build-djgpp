#!/usr/bin/env bash

BUILD_VER=$1

if [ -z $BUILD_VER ]; then
  echo "Usage : $0 djgpp-version"
  echo "Supported djgpp-version :"
  for F in `(cd script/;echo *)`; do echo "  "$F; done
  exit 1
fi

if [ ! -x script/$BUILD_VER ]; then
  echo "Unsupported version : $BUILD_VER"
  exit 1
fi

echo "Building version : $BUILD_VER"

unset CDPATH

# target directory
export DJGPP_PREFIX=${DJGPP_PREFIX-/usr/local/djgpp}

# enabled languages
#ENABLE_LANGUAGES=${ENABLE_LANGUAGES-c,c++,f95,objc,obj-c++}
export ENABLE_LANGUAGES=${ENABLE_LANGUAGES-c,c++}

# number of parallel build threads
export MAKE_JOBS=${MAKE_JOBS-4}

#DJGPP_DOWNLOAD_BASE="ftp://ftp.delorie.com/pub"
export DJGPP_DOWNLOAD_BASE="http://www.delorie.com/pub"

# source tarball versions
export DJCRX_VERSION=205
export DJLSR_VERSION=205
export DJDEV_VERSION=205
export BINUTILS_VERSION=2291

# source tarball locations
export BINUTILS_ARCHIVE="${DJGPP_DOWNLOAD_BASE}/djgpp/current/v2gnu/bnu${BINUTILS_VERSION}s.zip"
export DJCRX_ARCHIVE="${DJGPP_DOWNLOAD_BASE}/djgpp/current/v2/djcrx${DJCRX_VERSION}.zip"
export DJLSR_ARCHIVE="${DJGPP_DOWNLOAD_BASE}/djgpp/current/v2/djlsr${DJLSR_VERSION}.zip"
export DJDEV_ARCHIVE="${DJGPP_DOWNLOAD_BASE}/djgpp/current/v2/djdev${DJDEV_VERSION}.zip"

./script/$BUILD_VER
