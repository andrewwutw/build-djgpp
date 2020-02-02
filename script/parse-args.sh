#!/usr/bin/env false

if [ -z $1 ]; then
  echo "Usage: $0 [packages...]"
  echo "Supported packages:"
  for DIR in ${PACKAGE_SOURCES}; do
    ls $DIR
  done
  exit 1
fi

add_pkg()
{
  for DIR in ${PACKAGE_SOURCES}; do
    if [ -e $DIR/$1 ]; then
      source $DIR/$1
      return
    fi
  done
  echo "Unsupported package: $1"
  exit 1
}

for A in "$@"; do
  case $A in
  --no-download)
    # assumes tar archives are already present in ./download/
    # does not prevent downloading from git sources.
    NO_DOWNLOAD=y ;;
  --prefix=*) PREFIX=${A#*=} ;;
  --target=*) TARGET=${A#*=} ;;
  *) add_pkg $A ;;
  esac
done
