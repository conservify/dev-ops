all: fk_cron_every_five.zip terraform.tfplan

apply: terraform.tfplan
	terraform apply

terraform.tfplan:
	terraform get
	terraform plan -out=terraform.tfplan

fk_cron_every_five.zip: fk_cron_every_five.py
	zip -o $@ $^ && touch $@

clean:
	rm -f terraform.tfplan 

.PHONY: all apply clean
