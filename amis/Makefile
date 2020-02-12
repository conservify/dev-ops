# NOTE: This fails miserably with spaces.
BUILD ?= $(abspath build)

TAG ?= $(shell date "+%Y%m%d-%H%M%S")

IMAGES ?= envoy-proxy dummy-service

IMAGE_BUILD_TARGETS = ${IMAGES:%=${BUILD}/%.di}

default: $(BUILD)/stack.tar

ami: default
	./build-ami.sh

$(BUILD)/.env:
	mkdir -p $(BUILD)
	echo "TAG=${TAG}" > $(BUILD)/10_tag.env
	echo "TAG=${TAG}" > $(BUILD)/.env

$(BUILD)/stack.tar: $(IMAGE_BUILD_TARGETS) $(BUILD)/.env docker-compose.yaml
	cp docker-compose.yaml $(BUILD)
	cd $(BUILD) && tar cf $@ *.di .env *.yaml

images: $(IMAGE_BUILD_TARGETS)

$(IMAGE_BUILD_TARGETS): NAME = ${@:${BUILD}/%.di=%}

$(IMAGE_BUILD_TARGETS):
	mkdir -p $(BUILD)
	cd $(NAME) && docker build --rm -t conservify/${NAME}:${TAG} .
	docker save conservify/${NAME}:${TAG} > $@

clean:
	rm -rf $(BUILD)

.PHONY: default
.PHONY: images
