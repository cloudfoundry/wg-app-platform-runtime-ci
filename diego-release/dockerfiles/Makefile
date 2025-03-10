all: check-env clean diego-docker-app diego-inigo-ci-rootfs.tar diego-extra-rootfs.tar

diego-docker-app: check-env
	docker build -t cloudfoundry/diego-docker-app ./diego-docker-app

diego-inigo-ci-rootfs.tar: check-env
	docker build -t diego-inigo-ci-rootfs ./diego-inigo-ci-rootfs/
	docker run --name diego-inigo-ci-rootfs diego-inigo-ci-rootfs
	mkdir -p $(LOCATION)
	docker export -o $(LOCATION)/diego-inigo-ci-rootfs.tar diego-inigo-ci-rootfs  
	docker rm -f diego-inigo-ci-rootfs

diego-extra-rootfs.tar: check-env
	docker build -t diego-extra-rootfs ./diego-extra-rootfs/
	docker run --name diego-extra-rootfs diego-extra-rootfs
	mkdir -p $(LOCATION)
	docker export -o $(LOCATION)/diego-extra-rootfs.tar diego-extra-rootfs
	docker rm -f diego-extra-rootfs

clean: check-env
	rm -f $(LOCATION)/*.tar
	docker rm -f diego-inigo-ci-rootfs
	docker rm -f diego-extra-rootfs

check-env:
ifndef LOCATION
	$(error LOCATION enviornment variable is undefined)
endif
