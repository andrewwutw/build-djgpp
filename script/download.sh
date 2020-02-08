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
