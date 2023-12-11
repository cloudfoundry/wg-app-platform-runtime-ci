all: check-env clean garden-rootfs.tar garden-fuse.tar

garden-rootfs.tar: check-env
	docker build --build-arg BUSYBOX_VERSION=1.31 -t garden-rootfs ./garden-rootfs/
	docker run --name garden-rootfs garden-rootfs
	mkdir -p $(LOCATION)
	docker export -o $(LOCATION)/garden-rootfs.tar garden-rootfs  
	docker rm -f garden-rootfs

garden-fuse.tar: check-env
	docker build -t garden-fuse ./garden-fuse/
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
