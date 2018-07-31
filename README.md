## Build gcc cross compiler on Windows, Mac OSX, Linux and FreeBSD.

### Current package versions, as of 2018-07-31:

* gcc 8.2.0
* binutils 2.31.1
* gdb 8.1.1
* djgpp 2.05
* newlib 3.0.0.20180720

### Requirements

Before running this script, you need to install these programs first:

* g++
* gcc
* unzip
* bison
* flex
* make (or gmake for FreeBSD)
* makeinfo
* patch
* zlib header/library
* curl or wget
* bash (for FreeBSD)

Depending on your system, installation procedure maybe different.

On Debian/Ubuntu, you can install these programs by :

```
sudo apt-get update
sudo apt-get install bison flex curl gcc g++ make texinfo zlib1g-dev g++ unzip
```

Fedora :

```
sudo yum install gcc-c++ bison flex texinfo patch zlib-devel
```

MinGW :

```
mingw-get update
mingw-get install msys-unzip libz-dev msys-wget msys-bison msys-flex msys-patch
```

MinGW64 :

```
pacman -Syuu base-devel mingw-w64-x86_64-toolchain mingw-w64-x86_64-curl mingw-w64-x86_64-zlib unzip
```

### Configuration

Several environment variables control the build process. Usually you only need to specify `TARGET`. Here is the full list:
```
# Primary build options:
TARGET=                     # Target duplet or triplet.
PREFIX=                     # Install location.
ENABLE_LANGUAGES=           # Comma-separated list of languages to build compilers for.

# Advanced build options:
MAKE_JOBS=                  # Number of parallel build threads (auto-detected)
GCC_CONFIGURE_OPTIONS=      # Extra options to pass to gcc's ./configure
BINUTILS_CONFIGURE_OPTIONS= # Same, for binutils
GDB_CONFIGURE_OPTIONS=      # Same, for gdb
NEWLIB_CONFIGURE_OPTIONS=   # Same, for newlib

# Misc.
HOST=                       # The platform you are building for, when building a cross-cross compiler
BUILD=                      # The platform you are building on (auto-detected)
MAKE_CHECK=                 # Run test suites on built programs.
MAKE_CHECK_GCC=             # Run gcc test suites.
```

### Building

Pick the script you want to use:
```
build-glibc.sh      # builds a toolchain with glibc (gcc's default standard library)
build-djgpp.sh      # builds a toolchain with the djgpp standard library (fixed TARGET: i586-pc-msdosdjgpp)
build-newlib.sh     # builds a toolchain with the newlib standard library
build-ia16.sh       # builds a toolchain with the newlib standard library (fixed TARGET: ia16-elf)
```

To build DJGPP, just run:
```
./build-djgpp.sh [packages...]
```
Run with no arguments to see a list of supported packages and versions.

For example, to build gcc 7.2.0 with the djgpp base library and latest binutils:
```
./build-djgpp.sh base binutils gcc-7.2.0
```

To install or upgrade all packages:
```
./build-djgpp.sh all
```

It will download all necessary files, build DJGPP compiler and binutils, and install it.

### Using

There are 2 methods to run the compiler (`$PREFIX` and `$TARGET` here are the variables you used to build).

* Use compiler full name:

```
$PREFIX/bin/$TARGET-g++ hello.cpp
```

* Or, use compiler short name, you have to change environment variables.

If you are using Linux:
```
export PATH=$PREFIX/$TARGET/bin/:$PATH
export GCC_EXEC_PREFIX=$PREFIX/lib/gcc/
g++ hello.cpp
```
Or, run :

```
source $PREFIX/setenv-$TARGET
```

If you are using Windows command prompt :

```
PATH=$PREFIX/$TARGET/bin;%PATH%
set GCC_EXEC_PREFIX=$PREFIX/lib/gcc/
g++ hello.cpp
```

Or, run :

```
$PREFIX/setenv-$TARGET.bat
```

### Supported DJGPP Utilities
* dxe3gen
* dxe3res
* dxegen
* exe2coff
* stubedit
* stubify

### Successful build

* OSX 10.12.5
* Debian 7 (32bit)
* Ubuntu 12 (64bit)
* FreeBSD-10.2 (64bit)
* Cygwin (32bit Windows XP)
* MinGW (32bit Windows XP)
* MinGW64 (64bit Windows 7)

### Thanks

These scripts are based on Andrew Wu's build-djgpp script:  
<https://github.com/andrewwutw/build-djgpp>  
Which in turn is based on spec file from DJGPP source rpm files by Andris Pavenis:  
<http://ap1.pp.fi/djgpp/index.html>
