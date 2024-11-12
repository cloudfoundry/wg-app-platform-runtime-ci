all: check-env clean groot-windows-test-link groot-windows-test-regularfile groot-windows-test-servercore groot-windows-test-whiteout

groot-windows-test-link: check-env
	docker build -t cloudfoundry/groot-windows-test:link ./link

groot-windows-test-regularfile: check-env
	docker build -t cloudfoundry/groot-windows-test:regularfile ./regularfile

groot-windows-test-servercore: check-env
	docker build -t cloudfoundry/groot-windows-test:servercore ./servercore

groot-windows-test-whiteout: check-env
	docker build -t cloudfoundry/groot-windows-test:whiteout ./whiteout

clean: check-env
	rm -f $(LOCATION)/*.tar
	docker rm -f groot-windows-test:link
	docker rm -f groot-windows-test:regularfile
	docker rm -f groot-windows-test:servercore
	docker rm -f groot-windows-test:whiteout

check-env:
ifndef LOCATION
	$(error LOCATION environment variable is undefined)
endif
