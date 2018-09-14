FROM golang:1.8.1
RUN mkdir -p /app/work && mkdir -p /svr0/glacier/archive
WORKDIR /app/work
RUN apt-get update && apt-get install unzip
RUN wget https://github.com/Conservify/glacier/archive/master.zip && unzip master.zip
RUN go get -u github.com/lucasb-eyer/go-colorful
RUN go get -u golang.org/x/sys/...
RUN go get -u github.com/fsnotify/fsnotify
RUN cd glacier-master/rendering && go build -o glacier-renderer *.go && mv glacier-renderer /app/work && mv static /app/work
RUN rm -rf glacier-master
EXPOSE 9090
ENTRYPOINT ["/app/work/glacier-renderer", "--web", "/app/work/static", "--watch", "--syslog", "renderer", "/svr0/glacier/archive"]
