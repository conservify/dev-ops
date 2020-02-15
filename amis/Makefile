
STACKS ?= dummy-stack fk-cloud-stack
IMAGES ?= dummy-proxy dummy-service fk-cloud-proxy fk-cloud-service

# NOTE: This fails miserably with spaces.
BUILD := $(abspath build)
TAG := $(shell date "+%Y%m%d-%H%M%S")

# Paths to the exported docker images.
IMAGE_BUILD_TARGETS = ${IMAGES:%=${BUILD}/%.di}

# Paths to the archived stacks.
STACK_BUILD_TARGETS = $(STACKS:%=$(BUILD)/%.tar)

default: stacks

stacks: images $(STACK_BUILD_TARGETS)

bare-ami:
	./build-ami.sh bare.json

stacked-ami: stacks
	./build-ami.sh stacked.json

images: $(IMAGE_BUILD_TARGETS) ${BUILD}/10_tag.env

${BUILD}/10_tag.env:
	mkdir -p $(BUILD)
	echo "TAG=${TAG}" > $@

$(IMAGE_BUILD_TARGETS): NAME = ${@:${BUILD}/%.di=%}
$(IMAGE_BUILD_TARGETS):
	docker rmi -f `docker images --filter=reference='conservify/${NAME}' -q` || true
	cd services/$(NAME) && docker build --rm -t conservify/${NAME}:${TAG} .
	mkdir -p $(BUILD)
	docker save conservify/${NAME}:${TAG} > $@

$(STACK_BUILD_TARGETS): NAME = ${@:${BUILD}/%.tar=%}
$(STACK_BUILD_TARGETS): SOURCES = $(abspath stacks/${@:${BUILD}/%.tar=%})
$(STACK_BUILD_TARGETS): STACK_WORK = ${BUILD}/${@:${BUILD}/%.tar=%}
$(STACK_BUILD_TARGETS): $(IMAGE_BUILD_TARGETS)
	mkdir -p ${STACK_WORK}
	echo ${NAME}: building from ${SOURCES}
	@for f in ${SOURCES}/*; do                                   \
		if [ -d $$f ]; then                                      \
			name=`basename $$f`                                 ;\
			echo ${NAME}: including $$name                      ;\
			ln -sf ${BUILD}/$$name.di ${STACK_WORK}/$$name.di   ;\
		fi                                                       \
	done
	cp ${BUILD}/*.env ${SOURCES}/*.yaml $(STACK_WORK)
	cd ${STACK_WORK} && tar chf $@ *.env *.yaml *.di
	rm -rf ${STACK_WORK}

clean:
	rm -rf $(BUILD)

.PHONY: default
.PHONY: images

tools: .bin/yq

.bin/yq:
	mkdir -p .bin
	wget https://github.com/mikefarah/yq/releases/download/3.1.1/yq_linux_amd64 -O .bin/yq
	chmod 755 .bin/yq

fk-cloud-stack-run: tools images
	mkdir -p build
	.bin/yq d stacks/fk-cloud-stack/docker-compose.yaml "services.*.logging" > build/docker-compose.yaml
	cp 99_local.env build
	cat build/*_*.env > build/.env
	cd build && docker-compose rm -f
	cd build && docker-compose up || true
