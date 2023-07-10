# download source files
ARCHIVE_LIST="$BINUTILS_ARCHIVE $DJCRX_ARCHIVE $DJLSR_ARCHIVE $DJDEV_ARCHIVE
              $SED_ARCHIVE $DJCROSS_GCC_ARCHIVE $OLD_DJCROSS_GCC_ARCHIVE $GCC_ARCHIVE
              $AUTOCONF_ARCHIVE $AUTOMAKE_ARCHIVE $GDB_ARCHIVE $NEWLIB_ARCHIVE
              $AVRLIBC_ARCHIVE $AVRLIBC_DOC_ARCHIVE $AVRDUDE_ARCHIVE $AVARICE_ARCHIVE
              $GMP_ARCHIVE $MPFR_ARCHIVE $MPC_ARCHIVE $ISL_ARCHIVE"

# these variables are of the form "git://url/repo.git::branch"
# if 'branch' is empty then the default branch is checked out.
GIT_LIST="$DJGPP_GIT $GCC_GIT $BINUTILS_GIT $NEWLIB_GIT $SIMULAVR_GIT $WATT32_GIT"

mkdir -p download
cd download/ || exit 1

# Remove files that don't belong in the Debian package.
if [ ! -z "$BUILD_DEB" ]; then
  for FILE in $(find * -maxdepth 0 -type f); do
    for ARCHIVE in $ARCHIVE_LIST; do
      [ "$FILE" == "$(basename $ARCHIVE)" ] && continue 2
    done
    for REPO in $GIT_LIST; do
      REPO=${REPO%::*}
      REPO=${REPO%.*}
      [ "$FILE" == "$(basename $REPO)-git.tar" ] && continue 2
    done
    rm -f $FILE
  done
fi

if [ -z ${NO_DOWNLOAD} ]; then
  echo "Download source files..."

  for ARCHIVE in $ARCHIVE_LIST; do
    FILE=`basename $ARCHIVE`
    if ! [ -f $FILE ]; then
      echo "Download $ARCHIVE ..."
      if [ ! -z $USE_WGET ]; then
        DL_CMD="wget -U firefox $ARCHIVE"
      else
        DL_CMD="curl -f $ARCHIVE -L -o $FILE"
      fi
      while true; do
        if eval $DL_CMD; then
          break
        else
          if [ "$ARCHIVE" == "$DJCROSS_GCC_ARCHIVE" ]; then
            echo "$FILE maybe moved to deleted/ directory."
            break
          else
            rm $FILE
            echo "Download $FILE failed, retrying in 5 seconds... (press CTRL-C to abort)"
            sleep 5
          fi
        fi
      done
    fi
  done
fi

download_git()
{
  local repo=$(basename $1)
  repo=${repo%.*}
  if [ ! -d $repo/ ] || [ "`cd $repo/ && git remote get-url origin`" != "$1" ]; then
    if [ -f $repo-git.tar ]; then
      untar $repo-git.tar
    fi
    if [ ! -d $repo/ ] || [ "`cd $repo/ && git remote get-url origin`" != "$1" ]; then
      if [ -z ${NO_DOWNLOAD} ]; then
        echo "Downloading $repo..."
        rm -rf $repo/
        git clone $1 --depth 1 $([ "$2" != "" ] && echo "--branch $2")
      else
        echo "Missing: $repo"
        exit 1
      fi
    fi
  fi
  cd $repo/ || exit 1
  if [ -z ${NO_GIT_RESET} ]; then
    git reset --hard HEAD
    git checkout $2
    if [ -z ${NO_DOWNLOAD} ]; then
      git fetch origin
      git reset --hard origin/$2 || exit 1
    fi
  fi
  cd ${BASE}/download/ || exit 1
  if [ ! -z ${ONLY_DOWNLOAD} ] && [ ! -z ${BUILD_DEB} ]; then
    # Pack git sources for Debian package.
    find $repo/* ! -wholename '*/.git/*' -delete 2>&1 > /dev/null
    tar -c -f $repo-git.tar $repo
    return
  fi
  mkdir -p ${BASE}/build
  rm -rf ${BASE}/build/$repo
  ln -fs ../download/$repo ${BASE}/build/$repo || exit 1
}

for REPO in $GIT_LIST; do
  download_git ${REPO%::*} ${REPO##*::}
done

for ARCHIVE in $ARCHIVE_LIST; do
  FILE=`basename $ARCHIVE`
  if ! [ -f $FILE ]; then
    echo "Missing: $FILE"
    exit 1
  fi
done

if [ ! -z ${ONLY_DOWNLOAD} ]; then
  if [ ! -z ${BUILD_DEB} ]; then
    # Remove git sources that don't belong in the Debian package.
    rm -rf ${BASE}/download/*/
  fi
  exit 0
fi

cd ${BASE}/ || exit 1

echo "Creating install directory: ${DST}"
[ -d ${DST} ] || ${SUDO} mkdir -p ${DST} || exit 1
[ -d ${DST}/${TARGET}/etc/ ] || ${SUDO} mkdir -p ${DST}/${TARGET}/etc/ || exit 1

export PATH="${DST}/bin:${PREFIX}/bin:$PATH"

remove_if_exists()
{
  if [ -e $1 ]; then
    ${SUDO} rm -f $1 || exit 1
  fi
}

if which ${TARGET}-gcc 2>&1 > /dev/null; then
  echo "Removing previously-installed specs file"
  remove_if_exists "${DST}/lib/gcc/${TARGET}/$(${TARGET}-gcc -dumpversion)/specs"
  remove_if_exists "${PREFIX}/lib/gcc/${TARGET}/$(${TARGET}-gcc -dumpversion)/specs"
fi

rm -rf ${BASE}/tests
mkdir -p ${BASE}/tests
