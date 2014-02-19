## build-djgpp : Build DJGPP cross compiler and binutils on Windows (MinGW/Cygwin), Mac OSX and Linux

### Prebuilt binary files

If you don't want build DJGPP by yourself, you can download prebuilt DJGPP binary files for OSX/MinGW from GitHub Release page.

### Requirement

Before running this script, you need to install these programs first :

* g++
* gcc
* unzip
* bison
* flex
* make
* makeinfo
* patch
* zlib header/library
* curl (for Cygwin/OSX/Linux)
* wget (for MinGW)

Depend on your system, install procedure maybe different.

On Debian, you can install these programs by :

```
sudo apt-get update
sudo apt-get install unzip curl zlib1g-dev
```

Ubuntu :

```
sudo apt-get update
sudo apt-get install gcc curl unzip bison flex make texinfo g++
```

Fedora :

```
sudo yum install gcc-c++ bison flex texinfo patch zlib-devel
```

MinGW :

```
mingw-get update
mingw-get install msys-unzip
mingw-get install libz-dev
mingw-get install msys-wget
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

Default installed gcc compiler version is 4.8.2, You can change to gcc 4.7.3 by set environment variable *OPT_FILE* to ./gcc473.opt :

```
OPT_FILE=./gcc473.opt
```

### Build DJGPP compiler

Just run:

```
./build-djgpp.sh
```

It will download all necessary files, build DJGPP compiler and binutils, and install it.

### Use DJGPP compiler

There are 2 methods to run the compiler (*BASE_DIR* is your DJGPP install location).

* Use compiler full name :

    ```
	BASE_DIR/bin/i586-pc-msdosdjgpp-g++ hello.cpp
	```

* Or, use compiler short name, you have to change environment variables :

	```
	PATH=BASE_DIR/i586-pc-msdosdjgpp/bin/:$PATH
	GCC_EXEC_PREFIX=BASE_DIR/lib/gcc/
	g++ hello.cpp
	```

### Successful build

* OSX 10.9.1 / 10.8.5
* Debian 7 (32bit)
* Ubuntu 12 (64bit)
* Cygwin (32bit Windows XP)
* MinGW (32bit Windows XP, gcc 4.8.2 only)

### Thanks

This script is based on spec file from DJGPP source rpm files by Andris Pavenis :

<http://ap1.pp.fi/djgpp/index.html>
