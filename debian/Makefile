PACKAGES=djgpp-cvs binutils gcc gdb watt32

all: build

build:
	./build-djgpp.sh --batch --build-deb --no-download --prefix=/usr --destdir=`pwd`/install $(PACKAGES)

install:
	sed -i 's/\/usr\/bin\/i386/usr\/bin\/i386/' install/usr/bin/i386-pc-msdosdjgpp-link-i586
	cd install && ./usr/bin/i386-pc-msdosdjgpp-link-i586
	cp -rp install/* $(DESTDIR)/

clean:
	cp LICENSE debian/copyright
	cp LICENSE debian/binutils-djgpp.copyright
	cp LICENSE debian/gdb-djgpp.copyright
	cp debian/djgpp.copyright debian/djgpp-doc.copyright
	cp debian/gcc-djgpp.copyright debian/gcc-djgpp-doc.copyright
	cp debian/gcc-djgpp.copyright debian/gcc-djgpp-extra.copyright
	cp debian/binutils-djgpp.copyright debian/binutils-djgpp-doc.copyright
	cp debian/gdb-djgpp.copyright debian/gdb-djgpp-doc.copyright
	cp debian/gdb-djgpp.copyright debian/gdb-djgpp-extra.copyright
	-rm -rf build/ install/
	-find download/*/* ! -wholename '*/.git/*' -delete

.PHONY: all build install clean
