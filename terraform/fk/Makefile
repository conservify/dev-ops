all: fk_enqueue.zip terraform.tfplan

apply: terraform.tfplan
	terraform apply

terraform.tfplan:
	terraform get
	terraform plan -out=terraform.tfplan

fk_enqueue.zip: fk_enqueue.py
	zip -o $@ $^ && touch $@

setup: ~/.terraformrc
	go get -u github.com/coreos/terraform-provider-ct
	terraform init

~/.terraformrc:
	cp .terraformrc ~/

graph:
	@rm -f graph.png
	@terraform graph -draw-cycles -module-depth=-1 | dot -Tpng > graph.png

clean:
	rm -f terraform.tfplan fk_enqueue.zip graph.png

.PHONY: all apply clean
