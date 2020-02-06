if [ ! -z ${GCC_VERSION} ] && [ -z ${DJCROSS_GCC_ARCHIVE} ]; then
  DJCROSS_GCC_ARCHIVE="${DJGPP_DOWNLOAD_BASE}/djgpp/rpms/djcross-gcc-${GCC_VERSION}/djcross-gcc-${GCC_VERSION}.tar.bz2"
  # djcross-gcc-X.XX-tar.* maybe moved from /djgpp/rpms/ to /djgpp/deleted/rpms/ directory.
  OLD_DJCROSS_GCC_ARCHIVE=${DJCROSS_GCC_ARCHIVE/rpms\//deleted\/rpms\/}
fi

case $TARGET in
*-msdosdjgpp) ;;
*) unset DJCROSS_GCC_ARCHIVE OLD_DJCROSS_GCC_ARCHIVE ;;
esac

if [ ! -z ${GCC_VERSION} ]; then
  GMP_VERSION=${GMP_VERSION:-6.2.0}
  MPFR_VERSION=${MPFR_VERSION:-4.0.2}
  MPC_VERSION=${MPC_VERSION:-1.1.0}
  ISL_VERSION=${ISL_VERSION:-0.21}

  GMP_ARCHIVE="http://ftp.gnu.org/gnu/gmp/gmp-${GMP_VERSION}.tar.xz"
  MPFR_ARCHIVE="http://ftp.gnu.org/gnu/mpfr/mpfr-${MPFR_VERSION}.tar.xz"
  MPC_ARCHIVE="http://ftp.gnu.org/gnu/mpc/mpc-${MPC_VERSION}.tar.gz"
  ISL_ARCHIVE="http://isl.gforge.inria.fr/isl-${ISL_VERSION}.tar.xz"
fi

# download source files
ARCHIVE_LIST="$BINUTILS_ARCHIVE $DJCRX_ARCHIVE $DJLSR_ARCHIVE $DJDEV_ARCHIVE
              $SED_ARCHIVE $DJCROSS_GCC_ARCHIVE $OLD_DJCROSS_GCC_ARCHIVE $GCC_ARCHIVE
              $AUTOCONF_ARCHIVE $AUTOMAKE_ARCHIVE $GDB_ARCHIVE $NEWLIB_ARCHIVE
              $AVRLIBC_ARCHIVE $AVRLIBC_DOC_ARCHIVE $AVRDUDE_ARCHIVE $AVARICE_ARCHIVE
              $GMP_ARCHIVE $MPFR_ARCHIVE $MPC_ARCHIVE $ISL_ARCHIVE"

if [ -z ${NO_DOWNLOAD} ]; then
  echo "Download source files..."
  mkdir -p download || exit 1
  cd download

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

for ARCHIVE in $ARCHIVE_LIST; do
  FILE=`basename $ARCHIVE`
  if ! [ -f download/$FILE ]; then
    echo "Missing: $FILE"
    exit 1
  fi
done
