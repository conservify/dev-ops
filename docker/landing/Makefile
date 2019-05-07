build:
	docker build --rm -t fk-landing .

test:
	docker run --name fk-landing-test -p 8080:80 --rm --add-host="parent:172.17.0.1" fk-landing
