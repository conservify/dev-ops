all: terraform.tfplan

plan: build/fk_cron_every_five.zip
	terraform workspace list
	terraform plan -out=terraform.tfplan

dev:
	terraform workspace select dev

prod:
	terraform workspace select prod

apply: terraform.tfplan
	terraform apply
	@terraform output > deployed.json

terraform.tfplan:
	terraform get
	terraform plan -out=terraform.tfplan

build/fk_cron_every_five.zip: fk_cron_every_five.py
	mkdir -p build
	zip -o $@ $^ && touch $@

setup: ~/.terraformrc
	terraform init

vars:
	terraform output > deployed.json

graph:
	@rm -f graph.png
	@terraform graph -draw-cycles -module-depth=-1 | dot -Tpng > graph.png

clean:
	rm -f terraform.tfplan graph.png

.PHONY: all apply clean
