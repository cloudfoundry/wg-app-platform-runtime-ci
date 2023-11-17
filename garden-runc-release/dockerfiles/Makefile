all: check-env clean garden-runc-release-rootfs.tar garden-runc-release-fuse-rootfs.tar

garden-runc-release-rootfs.tar: check-env
	docker build --build-arg BUSYBOX_VERSION=1.31 -t garden-runc-release-rootfs ./garden-runc-release-rootfs/
	docker run --name garden-runc-release-rootfs garden-runc-release-rootfs
	mkdir -p $(LOCATION)
	docker export -o $(LOCATION)/garden-runc-release-rootfs.tar garden-runc-release-rootfs  
	docker rm -f garden-runc-release-rootfs

garden-runc-release-fuse-rootfs.tar: check-env
	docker build -t garden-runc-release-fuse-rootfs ./garden-runc-release-fuse-rootfs/
	docker run --name garden-runc-release-fuse-rootfs garden-runc-release-fuse-rootfs
	mkdir -p $(LOCATION)
	docker export -o $(LOCATION)/garden-runc-release-fuse-rootfs.tar garden-runc-release-fuse-rootfs  
	docker rm -f garden-runc-release-fuse-rootfs

clean: check-env
	rm -f $(LOCATION)/*.tar
	docker rm -f garden-runc-release-rootfs
	docker rm -f garden-runc-release-fuse-rootfs

check-env:
ifndef LOCATION
	$(error LOCATION enviornment variable is undefined)
endif
