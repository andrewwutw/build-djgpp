#!/usr/bin/env bash
if [ -z $1 ]; then
  echo "Missing target directory."
  exit 1
fi

echo "Copy setenv script"
cp setenv $1/
if uname|grep "^MINGW" > /dev/null; then
  cp setenv.bat $1/
elif uname|grep "^CYGWIN" > /dev/null; then
  cp setenv.bat $1/
fi
