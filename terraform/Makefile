all: fk_enqueue.zip terraform.tfplan 

apply: terraform.tfplan
	terraform apply

terraform.tfplan:
	terraform plan -out=terraform.tfplan

clean:
	rm -rf terraform.tfplan

fk_enqueue.zip: fk_enqueue.py
	zip -o $@ $^

setup:
	go get -u github.com/coreos/terraform-provider-ct

.PHONY: all apply clean
