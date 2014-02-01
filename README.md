# build-djgpp : Build DJGPP cross compiler on OSX/Linux/Cygwin

Just run:

```
./build-djgpp.sh
```

It will download all necessary files, build DJGPP compiler, and install into /usr/local/djgpp .

It builds gcc 4.8.2 and binutils 2.24 .

Tested on :

* OSX 10.9.1 / 10.8.5
* Debian 7 (32bit)
* Ubuntu 12 (64bit)
* Cygwin (32bit Windows XP)


This script is based on spec file from DJGPP source rpm files :

<http://ap1.pp.fi/djgpp/index.html>
