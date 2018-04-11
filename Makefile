build: artifacts/*.go
	mkdir -p build
	go build -o build/artifacts-publisher artifacts/*.go

clean:
	rm -rf build

.PHONY: build clean
