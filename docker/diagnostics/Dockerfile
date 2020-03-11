FROM golang:latest

RUN mkdir -p /data /app

WORKDIR /app

ADD go.* main.go /app/
RUN go build -o diagnostics *.go

ENTRYPOINT [ "/app/diagnostics", "--strip", "1", "--path", "/data" ]
