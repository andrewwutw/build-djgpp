## Building DJGPP cross compiler on Windows, Mac OSX, Linux and FreeBSD.

build-djgpp : Build DJGPP cross compiler and binutils on Windows (MinGW/Cygwin), Mac OSX, Linux and FreeBSD.

### Prebuilt binary files

If you don't want build DJGPP by yourself, you can download prebuilt DJGPP binary files for MinGW, OSX and Linux from GitHub Release page.

djgpp is also available on Nixpkgs Unstable. You can run a development shell by executing the following Nix command:

`$ nix develop nixpkgs#djgpp`

Alternatively, you can run 

`$ nix develop nixpkgs#djgpp_i686`

for the i686 version.

For the oldschool tools, the commands are, respectively,


`$ nix-shell -p djgpp`


`$ nix-shell -p djgpp_i686`


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
* curl (for Cygwin/OSX/Linux/FreeBSD)
* wget (for MinGW)
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

### Configuration

Default install location is /usr/local/djgpp. You can change install location by setting environment variable *DJGPP_PREFIX* :

```
DJGPP_PREFIX=/usr/local/my-djgpp
```

Default support language is C and C++. You can change supported languages by setting environment variable *ENABLE_LANGUAGES* :

```
ENABLE_LANGUAGES=c,c++,f95,objc,obj-c++
```

### Building DJGPP compiler

To build DJGPP, just run :

./build-djgpp.sh *gcc-version*

Currently supported gcc-version :

* 4.7.3
* 4.8.4
* 4.8.5
* 4.9.2
* 4.9.3
* 4.9.4
* 5.1.0
* 5.2.0
* 5.3.0
* 5.4.0
* 5.5.0
* 6.1.0
* 6.2.0
* 6.3.0
* 6.4.0
* 6.5.0
* 7.1.0
* 7.2.0
* 7.3.0
* 7.5.0
* 8.3.0
* 9.3.0
* 10.1.0
* 10.2.0
* 10.3.0
* 12.1.0
* 12.2.0

For example, to build DJGPP for gcc 12.2.0 :

```
./build-djgpp.sh 12.2.0
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

### Thanks

This script is based on spec file from DJGPP source rpm files by Andris Pavenis :

[http://ap1.pp.fi/djgpp/index.html](https://web.archive.org/web/20190811054505/http://ap1.pp.fi/djgpp/index.html)
