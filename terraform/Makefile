all: fk_enqueue.zip terraform.tfplan 

apply: terraform.tfplan
	terraform apply

terraform.tfplan:
	terraform plan -out=terraform.tfplan

clean:
	rm -f terraform.tfplan fk_enqueue.zip

fk_enqueue.zip: fk_enqueue.py
	zip -o $@ $^ && touch $@

setup: ~/.terraformrc
	go get -u github.com/coreos/terraform-provider-ct
	terraform init

~/.terraformrc:
	cp .terraformrc ~/

.PHONY: all apply clean
