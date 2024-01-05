build: go-binaries rust-binaries

go-binaries: build/artifacts-publisher 

rust-binaries: build/desecreter build/deployer

build/artifacts-publisher: artifacts/*.go
	mkdir -p build
	go build -o build/artifacts-publisher artifacts/*.go

build/desecreter: desecreter/* desecreter/src/*
	mkdir -p build
	cd desecreter && cargo build && cp target/debug/desecreter ../build/desecreter

build/deployer: deployer/* deployer/src/*
	mkdir -p build
	cd deployer && cargo build && cp target/debug/deployer ../build/deployer

clean:
	rm -rf build

.PHONY: build clean
