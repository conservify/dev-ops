all: terraform.tfplan

apply: terraform.tfplan
	terraform apply

terraform.tfplan:
	terraform get
	terraform plan -out=terraform.tfplan

setup: ~/.terraformrc
	go get -u github.com/coreos/terraform-provider-ct
	terraform init

~/.terraformrc:
	cp .terraformrc ~/

graph:
	@rm -f graph.png
	@terraform graph -draw-cycles -module-depth=-1 | dot -Tpng > graph.png

clean:
	rm -f terraform.tfplan graph.png

.PHONY: all apply clean
