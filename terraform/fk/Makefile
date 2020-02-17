all: terraform.tfplan

plan:
	terraform plan -out=terraform.tfplan

apply: terraform.tfplan
	terraform apply
	@terraform output > deployed.json

terraform.tfplan:
	terraform get
	terraform plan -out=terraform.tfplan

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
