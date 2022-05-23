#!/usr/bin/env bash

BUILD_VER=$1

if [ -z $BUILD_VER ]; then
  echo "Usage : $0 gcc-version"
  echo "Supported gcc-version :"
  for F in `(cd script/;echo *)`; do echo "  "$F; done
  exit 1
fi

if [ -x script/$BUILD_VER ]; then
  echo "Building with GCC version : $BUILD_VER"
  script/$BUILD_VER || exit 1
else
  echo "Unsupported GCC version : $BUILD_VER"
  exit 1
fi
