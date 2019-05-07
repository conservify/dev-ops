build:
	docker build --rm -t fk-landing-redirected .

test:
	docker run --name fk-landing-redirected-test -p 8080:80 --rm --add-host="parent:172.17.0.1" fk-landing-redirected
