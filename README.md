## Building DJGPP cross compiler on Windows, Mac OSX and Linux

build-djgpp : Build DJGPP cross compiler and binutils on Windows (MinGW/Cygwin), Mac OSX and Linux

### Prebuilt binary files

If you don't want build DJGPP by yourself, you can download prebuilt DJGPP binary files for MinGW, OSX and Linux from GitHub Release page.

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

./build-djgpp.sh *djgpp-version*

Currently supported djgpp-version :

* 4.7.3
* 4.8.4
* 4.9.2

For example, to build DJGPP for gcc 4.9.2 :

```
./build-djgpp.sh 4.9.2
```

It will download all necessary files, build DJGPP compiler and binutils, and install it.

### Using DJGPP compiler

There are 2 methods to run the compiler (*BASE_DIR* is your DJGPP install location).

* Use compiler full name :

    ```
	BASE_DIR/bin/i586-pc-msdosdjgpp-g++ hello.cpp
	```

* Or, use compiler short name, you have to change environment variables :

	```
	export PATH=BASE_DIR/i586-pc-msdosdjgpp/bin/:$PATH
	export GCC_EXEC_PREFIX=BASE_DIR/lib/gcc/
	g++ hello.cpp
	```

	If you are using Windows command prompt :

	```
	PATH=BASE_DIR/i586-pc-msdosdjgpp/bin;%PATH%
	set GCC_EXEC_PREFIX=BASE_DIR/lib/gcc/
	g++ hello.cpp
	```

### Successful build

* OSX 10.10.4 / 10.9.5 / 10.8.5
* Debian 7 (32bit)
* Ubuntu 12 (64bit)
* Cygwin (32bit Windows XP)
* MinGW (32bit Windows XP, gcc 4.8.x / 4.9.x)

### Thanks

This script is based on spec file from DJGPP source rpm files by Andris Pavenis :

<http://ap1.pp.fi/djgpp/index.html>
