# download source files
ARCHIVE_LIST="$BINUTILS_ARCHIVE $DJCRX_ARCHIVE $DJLSR_ARCHIVE $DJDEV_ARCHIVE
              $SED_ARCHIVE $DJCROSS_GCC_ARCHIVE $OLD_DJCROSS_GCC_ARCHIVE $GCC_ARCHIVE
              $AUTOCONF_ARCHIVE $AUTOMAKE_ARCHIVE $GDB_ARCHIVE $NEWLIB_ARCHIVE
              $AVRLIBC_ARCHIVE $AVRLIBC_DOC_ARCHIVE $AVRDUDE_ARCHIVE $AVARICE_ARCHIVE
              $GMP_ARCHIVE $MPFR_ARCHIVE $MPC_ARCHIVE $ISL_ARCHIVE"

if [ -z ${NO_DOWNLOAD} ]; then
  echo "Download source files..."
  mkdir -p download
  cd download || exit 1

  for ARCHIVE in $ARCHIVE_LIST; do
    FILE=`basename $ARCHIVE`
    if ! [ -f $FILE ]; then
      echo "Download $ARCHIVE ..."
      if [ ! -z $USE_WGET ]; then
        DL_CMD="wget -U firefox $ARCHIVE"
      else
        DL_CMD="curl -f $ARCHIVE -L -o $FILE"
      fi
      echo "Command : $DL_CMD"
      if ! eval $DL_CMD; then
        if [ "$ARCHIVE" == "$DJCROSS_GCC_ARCHIVE" ]; then
          echo "$FILE maybe moved to deleted/ directory."
        else
          rm $FILE
          echo "Download $ARCHIVE failed."
          exit 1
        fi
      fi
    fi
  done
  cd ..
fi

download_git()
{
  mkdir -p ${BASE}/build
  pushd ${BASE}/build || exit 1
  local repo=$(basename $1)
  repo=${repo%.*}
  if [ ! -d $repo/ ] || [ "`cd $repo/ && git remote get-url origin`" != "$1" ]; then
    if [ -z ${NO_DOWNLOAD} ]; then
      echo "Downloading ${repo}..."
      rm -rf $repo/
      git clone $1 --depth 1 $([ "$2" != "" ] && echo "--branch $2")
    else
      echo "Missing: ${repo}"
      exit 1
    fi
  fi
  cd $repo/ || exit 1
  git reset --hard HEAD
  git checkout $2
  if [ -z ${NO_DOWNLOAD} ]; then
    git pull || exit 1
  fi
  popd
}

# these variables are of the form "git://url/repo.git::branch"
# if 'branch' is empty then the default branch is checked out.
GIT_LIST="$DJGPP_GIT $GCC_GIT $BINUTILS_GIT $NEWLIB_GIT $SIMULAVR_GIT"

for REPO in $GIT_LIST; do
  download_git ${REPO%::*} ${REPO##*::}
done

for ARCHIVE in $ARCHIVE_LIST; do
  FILE=`basename $ARCHIVE`
  if ! [ -f download/$FILE ]; then
    echo "Missing: $FILE"
    exit 1
  fi
done

[ ! -z ${ONLY_DOWNLOAD} ] && exit 0

echo "Creating install directory: ${DST}"
[ -d ${DST} ] || ${SUDO} mkdir -p ${DST} || exit 1
[ -d ${DST}/${TARGET}/etc/ ] || ${SUDO} mkdir -p ${DST}/${TARGET}/etc/ || exit 1

export PATH="${DST}/bin:${PREFIX}/bin:$PATH"

rm -rf ${BASE}/tests
mkdir -p ${BASE}/tests
