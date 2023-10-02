
STACKS ?= dummy-stack proxy-stack auth-stack portal-stack charting-stack influxdb-stack postgres-stack
IMAGES ?= dummy-proxy dummy-service proxy-service auth-keycloak portal-service charting-service influxdb-service postgres-service

# NOTE: This fails miserably with spaces.
BUILD := $(abspath build)
DEPDIR := $(abspath .deps)
DATED_TAG := $(shell date "+%Y%m%d-%H%M%S")
TAG ?= $(DATED_TAG)

default: repository-stacks

repository-stacks: dummy-stack proxy-stack auth-stack influxdb-stack postgres-stack

$(DEPDIR)/rules.mk: Makefile
	@rm -rf $(DEPDIR)
	@mkdir -p $(DEPDIR)
	@for s in services/*; do                                                                    \
		service_name=`basename $$s`                           	                           ;\
		echo ".PHONY: $$service_name" >> $@                   	                           ;\
		for f in $$s/*; do                                                                  \
			if [ -f $$f ]; then                                                         \
				echo $$service_name: including $$f                                 ;\
				echo "$(BUILD)/$$service_name.di: $$f" >> $@                       ;\
			fi                                                                          \
		done                                                                                \
	done
	@for s in stacks/*; do                                                                      \
		stack_name=`basename $$s`                                                          ;\
		echo ".PHONY: $$stack_name" >> $@                                                  ;\
		echo "$$stack_name: $$s/docker-compose.yaml" >> $@                                 ;\
		echo "$$stack_name: $(BUILD)/$$stack_name.tar" >> $@                               ;\
		for f in $$s/*; do                                                                  \
			if [ -d $$f ]; then                                                         \
				service_name=`basename $$f`                                        ;\
				echo $$stack_name: including $$service_name                        ;\
				echo "$(BUILD)/$$stack_name.tar: $(BUILD)/$$service_name.di" >> $@ ;\
			fi                                                                          \
		done                                                                                \
	done
	echo TAG=$(TAG) >> $@

-include $(DEPDIR)/rules.mk

bare-ami:
	./build-ami.sh bare.json

stacked-ami: stacks
	./build-ami.sh stacked.json

clean:
	rm -rf $(BUILD) $(DEPDIR)

.PHONY: $(IMAGES)

$(IMAGES):
$(IMAGES):
	mkdir -p $(BUILD)
	false && docker rmi -f `docker images --filter=reference='conservify/$@' -q` || true
	cd services/$@ && docker build --rm -t conservify/$@:${TAG} .
	docker tag conservify/$@:$(TAG) conservify/$@:active

$(BUILD)/%.di: NAME = ${@:${BUILD}/%.di=%}

$(BUILD)/%.di:
	$(MAKE) $(NAME)
	@mkdir -p $(BUILD)
	docker save conservify/$(NAME):$(TAG) > $@
	echo "TAG=$(TAG)" > $(BUILD)/10_tag.env
	cd $(BUILD) && tar cf $(BUILD)/$(NAME).tar 10_tag.env $(NAME).di
	docker tag conservify/$(NAME):$(TAG) conservify/$(NAME):active

STACK_ARCHIVES := $(STACKS:%=$(BUILD)/%.tar)

stacks: $(STACK_ARCHIVES)

$(STACK_ARCHIVES): SOURCES = $(abspath stacks/$(@:$(BUILD)/%.tar=%))
$(STACK_ARCHIVES): WORK = $(BUILD)/$(@:$(BUILD)/%.tar=%)
$(STACK_ARCHIVES):
$(STACK_ARCHIVES):
	@mkdir -p $(WORK)
	@echo $@: building from $(SOURCES)
	@for f in $(SOURCES)/*; do                                           \
		if [ -d $$f ]; then                                          \
			name=`basename $$f`                                 ;\
			echo $@: including $$name                           ;\
			ln -sf ../$$name.di $(WORK)/$$name.di               ;\
		fi                                                           \
	done
	echo "TAG=$(TAG)" > $(WORK)/10_tag.env
	cp $(SOURCES)/*.yaml $(WORK)
	cp $(SOURCES)/*.sh $(WORK)
	ls -alh $(WORK)
	cd $(WORK) && tar chf $@ *
	rm -rf $(WORK)

tools: .bin/yq

.bin/yq:
	mkdir -p .bin
	wget https://github.com/mikefarah/yq/releases/download/3.1.1/yq_linux_amd64 -O .bin/yq
	chmod 755 .bin/yq

RUN_STACK_TARGETS := $(STACKS:%=run-%)

$(RUN_STACK_TARGETS): NAME = $(@:run-%=%)
$(RUN_STACK_TARGETS): tools
	$(MAKE) $(NAME)
	@echo $(TAG)
	@mkdir -p $(BUILD)
	.bin/yq d stacks/$(NAME)/docker-compose.yaml "services.*.logging" > $(BUILD)/docker-compose.yaml
	cp 99_local.env $(BUILD)
	cat $(BUILD)/*_*.env > build/.env
	cd $(BUILD) && docker-compose up

.PHONY: default stacks
