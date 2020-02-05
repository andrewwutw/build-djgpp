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
  --no-download) NO_DOWNLOAD=y ;;
  --only-download) ONLY_DOWNLOAD=y ;;
  --ignore-dependencies) IGNORE_DEPENDENCIES=y ;;
  --batch) BUILD_BATCH=y ;;
  --prefix=*) PREFIX=${A#*=} ;;
  --target=*) TARGET=${A#*=} ;;
  *) add_pkg $A ;;
  esac
done
