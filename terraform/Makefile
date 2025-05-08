TERRAFORM := $(abspath bin/terraform)
BUILD := $(abspath build)
DEPLOY_JSON := $(BUILD)/deploy.json
FK_PLAN := $(BUILD)/fk/terraform.tfplan
CRON_PLAN := $(BUILD)/cron/terraform.tfplan

default: all certbot

all: plan

dev: fk/.terraform
	cd fk && $(TERRAFORM) workspace select dev

prod: fk/.terraform
	cd fk && $(TERRAFORM) workspace select prod

plan: fk/.terraform $(BUILD)
	cd fk && $(TERRAFORM) plan -out=$(FK_PLAN)

apply: fk/.terraform $(BUILD) $(FK_PLAN)
	cd fk && $(TERRAFORM) apply $(FK_PLAN)
	$(MAKE) env

cron-plan: cron/.terraform $(BUILD)/fk_cron_every_five.zip
	cd cron && $(TERRAFORM) plan -out=$(CRON_PLAN)

cron-apply: fk/.terraform $(BUILD) $(CRON_PLAN)
	cd fk && $(TERRAFORM) apply $(CRON_PLAN)
	$(MAKE) env

env: fk/.terraform $(BUILD)
	cd fk && $(TERRAFORM) output -json > $(DEPLOY_JSON)

env-all: fk/.terraform $(BUILD)
	cd fk && $(TERRAFORM) workspace select prod
	cd fk && $(TERRAFORM) output -json > $(BUILD)/deploy-prod.json
	cd fk && $(TERRAFORM) workspace select dev
	cd fk && $(TERRAFORM) output -json > $(BUILD)/deploy-dev.json

$(BUILD):
	mkdir -p $(BUILD) $(BUILD)/fk $(BUILD)/cron

$(BUILD)/fk_cron_every_five.zip: $(BUILD) cron/fk_cron_every_five.py
	cd cron && zip -o $@ *.py

$(TERRAFORM):
	rm -rf bin && mkdir -p bin
	cd bin && wget https://releases.hashicorp.com/terraform/1.1.7/terraform_1.1.7_linux_amd64.zip && unzip *.zip

fk/.terraform: $(TERRAFORM)
	cd fk && $(TERRAFORM) init

cron/.terraform: $(TERRAFORM)
	cd cron && $(TERRAFORM) init

clean:
	rm -rf $(BUILD)

