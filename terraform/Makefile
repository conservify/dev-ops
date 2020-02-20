TERRAFORM := $(abspath bin/terraform)

all: plan

dev: .terraform
	$(TERRAFORM) workspace select dev

prod: .terraform
	$(TERRAFORM) workspace select prod

plan: .terraform build/fk_cron_every_five.zip
	$(TERRAFORM) workspace list
	$(TERRAFORM) plan -out=build/terraform.tfplan

apply: .terraform build/terraform.tfplan
	$(TERRAFORM) apply build/terraform.tfplan
	$(TERRAFORM) output > deployed.json

env: .terraform
	rm -f deploy.env
	$(TERRAFORM) output -json > deploy.json
	echo DATABASE_URL=`$(TERRAFORM) output database_url` > deploy.env

$(TERRAFORM):
	rm -rf bin && mkdir -p bin
	cd bin && wget https://releases.hashicorp.com/terraform/0.12.20/terraform_0.12.20_linux_amd64.zip && unzip *.zip

.terraform: $(TERRAFORM)
	$(TERRAFORM) init

build/fk_cron_every_five.zip: fk_cron_every_five.py
	mkdir -p build
	zip -o $@ $^ && touch $@

clean:
	rm -rf build bin

.PHONY: all apply clean
