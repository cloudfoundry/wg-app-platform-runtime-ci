ARCH := $(shell uname -p)

all: check-env clean garden-rootfs.tar garden-fuse.tar

garden-rootfs.tar: check-env
ifeq ($(ARCH), aarch64)
	docker build --build-arg BUSYBOX_VERSION=1.26.2 --build-arg BUSYBOX_IMAGE=arm64v8/busybox -t garden-rootfs ./garden-rootfs/
else
	docker build --build-arg BUSYBOX_VERSION=1.26.2 --build-arg BUSYBOX_IMAGE=busybox -t garden-rootfs ./garden-rootfs/
endif
	docker run --name garden-rootfs garden-rootfs
	mkdir -p $(LOCATION)
	docker export -o $(LOCATION)/garden-rootfs.tar garden-rootfs  
	docker rm -f garden-rootfs

garden-fuse.tar: check-env
ifeq ($(ARCH), aarch64)
	docker build -t garden-fuse --build-arg DEBIAN_IMAGE=arm64v8/debian ./garden-fuse/
else
	docker build -t garden-fuse ./garden-fuse/
endif
	docker run --name garden-fuse garden-fuse
	mkdir -p $(LOCATION)
	docker export -o $(LOCATION)/garden-fuse.tar garden-fuse  
	docker rm -f garden-fuse

clean: check-env
	rm -f $(LOCATION)/*.tar
	docker rm -f garden-rootfs
	docker rm -f garden-fuse

check-env:
ifndef LOCATION
	$(error LOCATION enviornment variable is undefined)
endif
