all: terraform.tfplan

apply: terraform.tfplan
	terraform apply

terraform.tfplan: fk_enqueue.zip
	terraform plan -out=terraform.tfplan

clean:
	rm -rf terraform.tfplan

fk_enqueue.zip: fk_enqueue.py
	zip -o $@ $^

.PHONY: all apply clean
