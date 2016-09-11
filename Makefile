KUBE_FLUENTD_VERSION ?= 0.9.1
FLUENTD_VERSION ?= 0.12.29

REPOSITORY ?= 192.168.99.100:5000/fluentd
TAG ?= $(FLUENTD_VERSION)-$(KUBE_FLUENTD_VERSION)
IMAGE ?= $(REPOSITORY):$(TAG)
ALIAS ?= $(REPOSITORY):$(FLUENTD_VERSION)
LATEST ?= $(REPOSITORY):latest

BUILD_ROOT ?= build/$(TAG)
DOCKERFILE ?= $(BUILD_ROOT)/Dockerfile
ROOTFS ?= $(BUILD_ROOT)/rootfs
FLUENT_CONF ?= $(BUILD_ROOT)/fluent.conf
DOCKER_CACHE ?= docker-cache
SAVED_IMAGE ?= $(DOCKER_CACHE)/image-$(FLUENTD_VERSION).tar

.PHONY: build
build: $(DOCKERFILE) $(ROOTFS) $(FLUENT_CONF)
	cd $(BUILD_ROOT) && docker build -t $(IMAGE) . && docker tag $(IMAGE) $(ALIAS) && docker tag $(IMAGE) $(LATEST)

publish:
	docker push $(LATEST) && docker push $(IMAGE) && docker push $(ALIAS)

$(DOCKERFILE): $(BUILD_ROOT)
	sed 's/%%FLUENTD_VERSION%%/'"$(FLUENTD_VERSION)"'/g;' Dockerfile.template > $(DOCKERFILE)

$(ROOTFS): $(BUILD_ROOT)
	cp -R rootfs $(ROOTFS)

$(FLUENT_CONF): $(BUILD_ROOT)
	cp fluent.conf $(FLUENT_CONF)

$(BUILD_ROOT):
	mkdir -p $(BUILD_ROOT)

travis-env:
	travis env set DOCKER_EMAIL $(DOCKER_EMAIL)
	travis env set DOCKER_USERNAME $(DOCKER_USERNAME)
	travis env set DOCKER_PASSWORD $(DOCKER_PASSWORD)

test:
	@echo There are no tests available for now. Skipping

save-docker-cache: $(DOCKER_CACHE)
	docker save $(IMAGE) $(shell docker history -q $(IMAGE) | tail -n +2 | grep -v \<missing\> | tr '\n' ' ') > $(SAVED_IMAGE)
	ls -lah $(DOCKER_CACHE)

load-docker-cache: $(DOCKER_CACHE)
	if [ -e $(SAVED_IMAGE) ]; then docker load < $(SAVED_IMAGE); fi

$(DOCKER_CACHE):
	mkdir -p $(DOCKER_CACHE)

docker-run: DOCKER_CMD ?=
docker-run:
	docker run --rm -it \
	$(IMAGE) $(DOCKER_CMD)

clean:
	rm -fR ${BUILD_ROOT}
	docker rmi $(IMAGE) $(ALIAS) $(LATEST)
	
