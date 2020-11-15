FROM node:11.13.0-alpine AS js

WORKDIR /app
COPY . /app/

RUN npm install
RUN npm run build

FROM golang:latest

RUN mkdir -p /data /app
WORKDIR /app

COPY . /app/
COPY --from=js /app/dist/ /app/public/

RUN go build -o diagnostics *.go

ENTRYPOINT [ "/app/diagnostics", "--strip", "1", "--path", "/data", "--slack-channel", "automation", "--url", "https://code.conservify.org/diagnostics/" ]
