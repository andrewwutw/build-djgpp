# build-djgpp : Build DJGPP cross compiler on OSX/Linux/Cygwin

Just run:

```
./build-djgpp.sh
```

It will download all necessary files, build DJGPP compiler, and install into /usr/local/djgpp .

You can change install location by settting environment variable DJGPP_PREFIX :

```
DJGPP_PREFIX=/usr/local/my-djgpp ./build-djgpp.sh
```

By default, it only builds C and C++ compiler, you can change supported languages by setting environment variable ENABLE_LANGUAGES :

```
ENABLE_LANGUAGES=c,c++,f95,objc,obj-c++ ./build-djgpp.sh
```

By default, it builds gcc 4.8.2. if you want to use gcc 4.7.3, set environment variable OPT_FILE to ./gcc473.opt :

```
OPT_FILE=./gcc473.opt ./build-djgpp.sh
```

Tested on :

* OSX 10.9.1 / 10.8.5
* Debian 7 (32bit)
* Ubuntu 12 (64bit)
* Cygwin (32bit Windows XP)


This script is based on spec file from DJGPP source rpm files :

<http://ap1.pp.fi/djgpp/index.html>
