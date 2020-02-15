
STACKS ?= dummy-stack fk-cloud-stack
IMAGES ?= dummy-proxy dummy-service fk-cloud-proxy fk-cloud-service
TAG ?= $(shell date "+%Y%m%d-%H%M%S")

# NOTE: This fails miserably with spaces.
BUILD := $(abspath build)
DEPDIR := $(abspath .deps)

default: stacks

$(DEPDIR)/rules.mk: Makefile
	@rm -rf $(DEPDIR)
	@mkdir -p $(DEPDIR)
	@for s in services/*; do                                                        \
		service_name=`basename $$s`                           	                   ;\
		echo ".PHONY: $$service_name" >> $@                   	                   ;\
		for f in $$s/*; do                                                          \
			if [ -f $$f ]; then                                                     \
				echo $$service_name: including $$f                                 ;\
				echo "$(BUILD)/$$service_name.di: $$f" >> $@                       ;\
			fi                                                                      \
		done                                                                        \
	done
	@for s in stacks/*; do                                                          \
		stack_name=`basename $$s`                                                  ;\
		echo ".PHONY: $$stack_name" >> $@                                          ;\
		echo "$$stack_name: $$s/docker-compose.yaml" >> $@                         ;\
		echo "$$stack_name: $(BUILD)/$$stack_name.tar" >> $@                       ;\
		for f in $$s/*; do                                                          \
			if [ -d $$f ]; then                                                     \
				service_name=`basename $$f`                                        ;\
				echo $$stack_name: including $$service_name                        ;\
				echo "$(BUILD)/$$stack_name.tar: $(BUILD)/$$service_name.di" >> $@ ;\
			fi                                                                      \
		done                                                                        \
	done

-include $(DEPDIR)/rules.mk

bare-ami:
	./build-ami.sh bare.json

stacked-ami: stacks
	./build-ami.sh stacked.json

clean:
	rm -rf $(BUILD) $(DEPDIR)

.PHONY: $(IMAGES)

$(IMAGES):
	docker rmi -f `docker images --filter=reference='conservify/$@' -q` || true
	cd services/$@ && docker build --rm -t conservify/$@:${TAG} .

$(BUILD)/%.di: NAME = ${@:${BUILD}/%.di=%}

$(BUILD)/%.di:
	TAG=$(TAG) $(MAKE) $(NAME)
	mkdir -p $(BUILD)
	docker save conservify/$(NAME):$(TAG) > $@

STACK_ARCHIVES := $(STACKS:%=$(BUILD)/%.tar)

stacks: $(STACK_ARCHIVES)

$(STACK_ARCHIVES): SOURCES = $(abspath stacks/$(@:$(BUILD)/%.tar=%))
$(STACK_ARCHIVES): WORK = $(BUILD)/$(@:$(BUILD)/%.tar=%)
$(STACK_ARCHIVES): $(BUILD)/10_tag.env
$(STACK_ARCHIVES):
	@mkdir -p $(WORK)
	@echo $@: building from $(SOURCES)
	@for f in $(SOURCES)/*; do                                   \
		if [ -d $$f ]; then                                      \
			name=`basename $$f`                                 ;\
			echo $@: including $$name                           ;\
			ln -sf ../$$name.di $(WORK)/$$name.di               ;\
		fi                                                       \
	done
	cp $(BUILD)/*.env $(SOURCES)/*.yaml $(WORK)
	cd $(WORK) && tar chf $@ *.env *.yaml *.di
	rm -rf $(WORK)

$(BUILD)/10_tag.env:
	mkdir -p $(BUILD)
	echo "TAG=${TAG}" > $@

tools: .bin/yq

.bin/yq:
	mkdir -p .bin
	wget https://github.com/mikefarah/yq/releases/download/3.1.1/yq_linux_amd64 -O .bin/yq
	chmod 755 .bin/yq

fk-cloud-stack-run: tools fk-cloud-stack
	mkdir -p build
	.bin/yq d stacks/fk-cloud-stack/docker-compose.yaml "services.*.logging" > build/docker-compose.yaml
	cp 99_local.env build
	cat build/*_*.env > build/.env

.PHONY: default stacks
