all: plan

dev: .terraform
	terraform workspace select dev

prod: .terraform
	terraform workspace select prod

plan: .terraform build/fk_cron_every_five.zip
	terraform workspace list
	terraform plan -out=terraform.tfplan

apply: terraform.tfplan
	terraform apply
	@terraform output > deployed.json

.terraform:
	terraform init

build/fk_cron_every_five.zip: fk_cron_every_five.py
	mkdir -p build
	zip -o $@ $^ && touch $@

clean:
	rm -f terraform.tfplan build

.PHONY: all apply clean
