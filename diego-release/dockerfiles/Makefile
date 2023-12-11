all: check-env clean diego-docker-app diego-inigo-ci-rootfs.tar

diego-docker-app: check-env
	docker build -t cloudfoundry/diego-docker-app ./diego-docker-app

diego-inigo-ci-rootfs.tar: check-env
	docker build -t diego-inigo-ci-rootfs ./diego-inigo-ci-rootfs/
	docker run --name diego-inigo-ci-rootfs diego-inigo-ci-rootfs
	mkdir -p $(LOCATION)
	docker export -o $(LOCATION)/diego-inigo-ci-rootfs.tar diego-inigo-ci-rootfs  
	docker rm -f diego-inigo-ci-rootfs

clean: check-env
	rm -f $(LOCATION)/*.tar
	docker rm -f diego-inigo-ci-rootfs

check-env:
ifndef LOCATION
	$(error LOCATION enviornment variable is undefined)
endif
