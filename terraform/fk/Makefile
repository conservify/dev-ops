all: terraform.tfplan

plan:
	terraform plan -out=terraform.tfplan

plan-test:
	terraform plan -var=enable_test_server=true -out=terraform.tfplan

apply: terraform.tfplan
	terraform apply

terraform.tfplan:
	terraform get
	terraform plan -out=terraform.tfplan

setup: ~/.terraformrc
	terraform init

graph:
	@rm -f graph.png
	@terraform graph -draw-cycles -module-depth=-1 | dot -Tpng > graph.png

clean:
	rm -f terraform.tfplan graph.png

.PHONY: all apply clean
