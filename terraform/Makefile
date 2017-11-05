fk_enqueue.zip: fk_enqueue.py
	zip -o $@ $^

plan: fk_enqueue.zip
	terraform plan

apply: fk_enqueue.zip
	terraform apply

