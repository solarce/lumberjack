VERSION=0.0.1

CFLAGS+=-Ibuild/include 
CFLAGS+=-D_POSIX_C_SOURCE=199309 -std=c99 -Wall -Wextra -Werror -pipe -g 
LDFLAGS+=-pthread
LDFLAGS+=-Lbuild/lib -Wl,-rpath,'$$ORIGIN/../lib'
LIBS=-lzmq -ljansson

PREFIX?=/opt/lumberjack

default: build/bin/lumberjack
include Makefile.ext

clean:
	-@rm -fr lumberjack unixsock *.o build
	-@make -C vendor/jansson/ clean
	-@make -C vendor/zeromq/ clean

rpm deb:
	fpm -s dir -t $@ -n lumberjack -v $(VERSION) --prefix /opt/lumberjack \
		bin/lumberjack build/lib

#install: build/bin/lumberjack build/lib/libzmq.$(LIBEXT)
# install -d -m 755 build/bin/* $(PREFIX)/bin/lumberjack
# install -d build/lib/* $(PREFIX)/lib

#unixsock.c: build/include/insist.h
backoff.c: backoff.h
harvester.c: harvester.h
emitter.c: emitter.h
lumberjack.c: build/include/insist.h build/include/zmq.h build/include/jansson.h
lumberjack.c: backoff.h harvester.h emitter.h

build/bin/pushpull: | build/lib/libzmq.$(LIBEXT) build/lib/libjansson.$(LIBEXT) build/bin
build/bin/pushpull: pushpull.o
	$(CC) $(LDFLAGS) -o $@ $^ $(LIBS)

build/bin/lumberjack: | build/bin build/lib/libzmq.$(LIBEXT) build/lib/libjansson.$(LIBEXT)
build/bin/lumberjack: lumberjack.o backoff.o harvester.o emitter.o
	$(CC) $(LDFLAGS) -o $@ $^ $(LIBS)
	@echo " => Build complete: $@"
	@echo " => Run 'make rpm' to build an rpm (or deb or tarball)"


build/include/insist.h: | build/include
	curl -s -o $@ https://raw.github.com/jordansissel/experiments/master/c/better-assert/insist.h

build/include/zmq.h build/lib/libzmq.$(LIBEXT): | build
	$(MAKE) -C vendor/zeromq/ install PREFIX=$$PWD/build

#build/include/msgpack.h build/lib/libmsgpack.$(LIBEXT): | build
#	$(MAKE) -C vendor/msgpack/ install PREFIX=$$PWD/build

build/include/jansson.h build/lib/libjansson.$(LIBEXT): | build
	$(MAKE) -C vendor/jansson/ install PREFIX=$$PWD/build

build:
	mkdir $@

build/include: | build
	mkdir $@

build/bin: | build
	mkdir $@
