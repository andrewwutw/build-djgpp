## Building DJGPP cross compiler on Windows, Mac OSX, Linux and FreeBSD.

build-djgpp : Build DJGPP cross compiler and binutils on Windows (MinGW/Cygwin), Mac OSX, Linux and FreeBSD.

### Prebuilt binary files

If you don't want build DJGPP by yourself, you can download prebuilt DJGPP binary files for MinGW, OSX and Linux from GitHub Release page.

### Requirement

Before running this script, you need to install these programs first :

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

Default install location is /usr/local/djgpp. You can change install location by setting environment variable *DJGPP_PREFIX* :

```
DJGPP_PREFIX=/usr/local/my-djgpp
```

Default support language is C and C++. You can change supported languages by setting environment variable *ENABLE_LANGUAGES* :

```
ENABLE_LANGUAGES=c,c++,f95,objc,obj-c++
```

Default number of parallel builds is 4. You can change this number by setting environment variable *MAKE_JOBS* :

```
MAKE_JOBS=8
```

To configure packages with additional options, add your custom flags to one of the following environment variables:

```
GCC_CONFIGURE_OPTIONS="--enable-feature"
GDB_CONFIGURE_OPTIONS="--enable-feature"
BINUTILS_CONFIGURE_OPTIONS="--enable-feature"
```

### Building DJGPP compiler

To build DJGPP, just run :

./build-djgpp.sh [packages...]

Currently supported packages :

* gcc-4.7.3
* gcc-4.8.4
* gcc-4.8.5
* gcc-4.9.2
* gcc-4.9.3
* gcc-4.9.4
* gcc-5.1.0
* gcc-5.2.0
* gcc-5.3.0
* gcc-5.4.0
* gcc-5.5.0
* gcc-6.1.0
* gcc-6.2.0
* gcc-6.3.0
* gcc-6.4.0
* gcc-7.1.0
* gcc-7.2.0
* gcc-7.3.0
* binutils-2.29.1
* gdb-8.0.1

For example, to build gcc 7.2.0 with the base library and latest binutils:

```
./build-djgpp.sh base binutils gcc-7.2.0
```

To install or upgrade all packages:

```
./build-djgpp.sh all
```

It will download all necessary files, build DJGPP compiler and binutils, and install it.

### Using DJGPP compiler

There are 2 methods to run the compiler (*BASE_DIR* is your DJGPP install location).

* Use compiler full name :

```
BASE_DIR/bin/i586-pc-msdosdjgpp-g++ hello.cpp
```

* Or, use compiler short name, you have to change environment variables.

If you are using Linux :
```
export PATH=BASE_DIR/i586-pc-msdosdjgpp/bin/:$PATH
export GCC_EXEC_PREFIX=BASE_DIR/lib/gcc/
g++ hello.cpp
```
Or, run :

```
source BASE_DIR/setenv
```

If you are using Windows command prompt :

```
PATH=BASE_DIR/i586-pc-msdosdjgpp/bin;%PATH%
set GCC_EXEC_PREFIX=BASE_DIR/lib/gcc/
g++ hello.cpp
```

Or, run :

```
BASE_DIR/setenv.bat
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

This script is based on spec file from DJGPP source rpm files by Andris Pavenis :

<http://ap1.pp.fi/djgpp/index.html>
