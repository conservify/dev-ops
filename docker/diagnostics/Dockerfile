FROM node:11.13.0-alpine AS js
WORKDIR /app
COPY . /app/
RUN yarn install
RUN node_modules/.bin/webpack --mode production
RUN ls -alh
RUN ls -alh public

FROM golang:latest
RUN mkdir -p /data /app
WORKDIR /app

COPY . /app/
COPY --from=js /app/public/* /app/static/

RUN go build -o diagnostics *.go

RUN ls -alh
RUN ls -alh /app/static/

ENTRYPOINT [ "/app/diagnostics", "--strip", "1", "--path", "/data" ]
