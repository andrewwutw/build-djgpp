unset CDPATH

BASE=`pwd`

# target directory
PREFIX=${PREFIX-/usr/local/cross}

# enabled languages
#ENABLE_LANGUAGES=${ENABLE_LANGUAGES-c,c++,f95,objc,obj-c++}
ENABLE_LANGUAGES=${ENABLE_LANGUAGES-c,c++}

# number of parallel build threads
MAKE_JOBS=${MAKE_JOBS-4}

untar()
{
  tar -xavf $(ls -t ${BASE}/download/$1.tar.* | head -n 1)
}
