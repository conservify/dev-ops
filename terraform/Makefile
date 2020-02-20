TERRAFORM := $(abspath bin/terraform)
BUILD := $(abspath build)
DEPLOY_JSON := $(BUILD)/deploy.json
FK_PLAN := $(BUILD)/fk/terraform.tfplan
CRON_PLAN := $(BUILD)/cron/terraform.tfplan

default: all

all: plan

dev: fk/.terraform
	cd fk && $(TERRAFORM) workspace select dev

prod: fk/.terraform
	cd fk && $(TERRAFORM) workspace select prod

plan: fk/.terraform $(BUILD)
	cd fk && $(TERRAFORM) plan -out=$(FK_PLAN)

plan-cron: cron/.terraform $(BUILD)/fk_cron_every_five.zip
	cd cron && $(TERRAFORM) plan -out=$(CRON_PLAN)

apply: fk/.terraform $(BUILD) $(FK_PLAN)
	cd fk && $(TERRAFORM) apply $(FK_PLAN)
	cd fk && $(TERRAFORM) output -json > $(DEPLOY_JSON)

env: fk/.terraform $(BUILD)
	cd fk && $(TERRAFORM) output -json > $(DEPLOY_JSON)

$(BUILD):
	mkdir -p $(BUILD) $(BUILD)/fk $(BUILD)/cron

$(BUILD)/fk_cron_every_five.zip: $(BUILD) cron/fk_cron_every_five.py
	zip -o $@ $^ && touch $@

$(TERRAFORM):
	rm -rf bin && mkdir -p bin
	cd bin && wget https://releases.hashicorp.com/terraform/0.12.20/terraform_0.12.20_linux_amd64.zip && unzip *.zip

fk/.terraform: $(TERRAFORM)
	cd fk && $(TERRAFORM) init

cron/.terraform: $(TERRAFORM)
	cd cron && $(TERRAFORM) init

clean:
	rm -rf $(BUILD)
