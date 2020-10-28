docker-image:
	docker build -t temp .

docker-test: docker-image
	docker run --rm -p 8080:8080 temp

test:
	webpack-dev-server

pack:
	webpack --mode production

clean:
	rm -rf node_modules
