## Build gcc cross compiler on Windows, Mac OSX, Linux and FreeBSD.

### Upgrade notes:

* 2020-02-13: default target for djgpp has changed to `i386-pc-msdosdjgpp`.  
If you require compatibility with distributions that use `i586`, you can either:
    - run `sudo i386-pc-msdosdjgpp-link-i586` after installing, or
    - build with `./build-djgpp.sh --prefix=i586-pc-msdosdjgpp`.
* 2020-02-07: setenv script is now installed to `$PREFIX/bin/$TARGET-setenv`.
* 2019-06-06: `master` is now the default branch again.

### Current package versions, as of 2022-05-23:

* gcc 12.1.0
* binutils 2.38
* gdb 12.1
* djgpp 2.05 / cvs
* watt-32 git
* newlib 4.1.0
* avr-libc 2.1.0
* avrdude 6.4
* avarice 2.14
* simulavr git

### Tested targets:

* i386-pc-msdosdjgpp
* ia16
* arm-eabi
* avr

See the [Actions tab](https://github.com/jwt27/build-gcc/actions?query=workflow%3A"Test+builds"+branch%3Amaster) on Github for a detailed status of individual targets.

### Requirements

Before running this script, you need to install these programs first:

* g++
* gcc
* unzip
* tar
* bzip2
* gzip
* xz
* bison
* flex
* make (or gmake for FreeBSD)
* makeinfo
* patch
* zlib header/library
* curl or wget
* bash (for FreeBSD)
* python2 headers (for gdb)
* python3 headers (for gdb >= 9.0)

Depending on your system, installation procedure maybe different.

On Debian/Ubuntu, you can install these programs by :

```sh
sudo apt-get update
sudo apt-get install bison flex curl gcc g++ make texinfo zlib1g-dev tar bzip2 gzip xz-utils unzip python{2,3}-dev
```

Fedora :

```sh
sudo yum install gcc-c++ bison flex texinfo patch zlib-devel tar bzip2 gzip xz unzip python-devel
```

mingw-w64 (msys2) :

```sh
pacman -Syuu base-devel mingw-w64-x86_64-{toolchain,curl,zlib,python{2,3}} compression
```

### Configuration

The following command line options are recognized:
```sh
  --prefix=...              # Install location (default: /usr/local/cross)
  --target=...              # Target name
  --enable-languages=...    # Comma-separated list of languages to build compilers for (default: c,c++)
  --no-download             # Do not download any files
  --only-download           # Download source files, then exit
  --ignore-dependencies     # Do not check package dependencies
  --batch                   # Run in batch mode (will not prompt or delay to confirm settings)
```

Several environment variables also control the build process:
```sh
MAKE_JOBS=                  # Number of parallel build threads (auto-detected)
GCC_CONFIGURE_OPTIONS=      # Extra options to pass to gcc's ./configure
BINUTILS_CONFIGURE_OPTIONS= # Same, for binutils
GDB_CONFIGURE_OPTIONS=      # Same, for gdb
NEWLIB_CONFIGURE_OPTIONS=   # Same, for newlib
AVRLIBC_CONFIGURE_OPTIONS=  # Same, for avr-libc
CFLAGS_FOR_TARGET=          # CFLAGS used to build target libraries
HOST=                       # The platform you are building for, when building a cross-cross compiler
BUILD=                      # The platform you are building on (auto-detected)
MAKE_CHECK=                 # Run test suites on built programs.
MAKE_CHECK_GCC=             # Run gcc test suites.
```

### Building

Pick the script you want to use:
```sh
build-djgpp.sh      # builds a toolchain targeting djgpp (default TARGET: i386-pc-msdosdjgpp)
build-newlib.sh     # builds a toolchain with the newlib C library
build-ia16.sh       # builds a toolchain targeting 8086 processors, with the newlib C library (fixed TARGET: ia16-elf)
build-avr.sh        # builds a toolchain targeting AVR microcontrollers (fixed TARGET: avr)
```

To build DJGPP, just run:
```sh
./build-djgpp.sh [options...] [packages...]
```
Run with no arguments to see a list of supported packages and versions.

For example, to build gcc 9.2.0 with the latest djgpp C library from CVS and latest binutils:
```sh
./build-djgpp.sh --prefix=/usr/local djgpp-cvs binutils gcc-9.2.0
```

To install or upgrade all packages:
```sh
./build-djgpp.sh --prefix=/usr/local all
```

It will download all necessary files, build DJGPP compiler, binutils, and gdb, and install it.

### Using

In order to use your new compiler, you must add its `bin/` directory to your `PATH`.  
You can then access the compiler through its target-prefixed name: (`$PREFIX` and `$TARGET` in these examples are the variables you used to build)

```sh
$ PATH=$PREFIX/bin/:$PATH
$ $TARGET-g++ hello.cpp
```

To use the short name variant, and access documentation with `man` and `info`, use the installed setenv script:

```sh
$ source $TARGET-setenv
$ g++ hello.cpp
```

If you are using Windows command prompt :

```bat
> PATH=$PREFIX/bin;%PATH%
> $TARGET-g++ hello.cpp
> $TARGET-setenv
> g++ hello.cpp
```

### Supported DJGPP utilities

* dxe3gen
* dxe3res
* dxegen
* exe2coff
* stubedit
* stubify
* djasm

### Supported AVR utilities

* avrdude
* avarice
* simulavr

### Thanks

These scripts are based on Andrew Wu's build-djgpp script:  
<https://github.com/andrewwutw/build-djgpp>  
Which in turn is based on spec file from DJGPP source rpm files by Andris Pavenis:  
<http://ap1.pp.fi/djgpp/index.html>
