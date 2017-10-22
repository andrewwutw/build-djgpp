#!/usr/bin/env bash

BUILD_VER=$1

if [ -z $BUILD_VER ]; then
  echo "Usage : $0 djgpp-version"
  echo "Supported djgpp-version :"
  for F in `(cd script/;echo *)`; do echo "  "$F; done
  exit 1
fi

if [ -x script/$BUILD_VER ]; then
  echo "Building version : $BUILD_VER"
  script/$BUILD_VER || exit 1
else
  echo "Unsupported version : $BUILD_VER"
  exit 1
fi
