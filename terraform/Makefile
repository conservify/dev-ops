all: plan

dev: .terraform
	terraform workspace select dev

prod: .terraform
	terraform workspace select prod

plan: .terraform build/fk_cron_every_five.zip
	terraform workspace list
	terraform plan -out=build/terraform.tfplan

apply: build/terraform.tfplan
	terraform apply build/terraform.tfplan
	@terraform output > deployed.json

.terraform:
	terraform init

build/fk_cron_every_five.zip: fk_cron_every_five.py
	mkdir -p build
	zip -o $@ $^ && touch $@

clean:
	rm -rf build

.PHONY: all apply clean
