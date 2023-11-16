LOCATION ?= $(PWD)

all: clean garden-runc-release-rootfs.tar garden-runc-release-fuse-rootfs.tar

garden-runc-release-rootfs.tar:
	docker build --build-arg BUSYBOX_VERSION=1.31 -t garden-runc-release-rootfs ./garden-runc-release-rootfs/
	docker run --name garden-runc-release-rootfs garden-runc-release-rootfs
	docker export -o $(LOCATION)/garden-runc-release-rootfs.tar garden-runc-release-rootfs  
	docker rm -f garden-runc-release-rootfs

garden-runc-release-fuse-rootfs.tar: 
	docker build -t garden-runc-release-fuse-rootfs ./garden-runc-release-fuse-rootfs/
	docker run --name garden-runc-release-fuse-rootfs garden-runc-release-fuse-rootfs
	docker export -o $(LOCATION)/garden-runc-release-fuse-rootfs.tar garden-runc-release-fuse-rootfs  
	docker rm -f garden-runc-release-fuse-rootfs

clean:
	rm -f $(LOCATION)/*.tar
