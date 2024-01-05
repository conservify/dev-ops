build: build/artifacts-publisher build/desecreter build/deployer

build/artifacts-publisher: artifacts/*.go
	mkdir -p build
	go build -o build/artifacts-publisher artifacts/*.go

build/desecreter: desecreter/* desecreter/src/*
	cd desecreter && cargo build && cp target/debug/desecreter ../build/desecreter

build/deployer: deployer/* deployer/src/*
	cd deployer && cargo build && cp target/debug/deployer ../build/deployer

clean:
	rm -rf build

.PHONY: build clean
