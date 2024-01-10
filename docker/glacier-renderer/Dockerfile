FROM golang:1.21.5-bullseye
RUN mkdir -p /app/work && mkdir -p /svr0/glacier/archive
WORKDIR /app/work
RUN apt-get update && apt-get install unzip
RUN wget https://github.com/Conservify/glacier/archive/master.zip && unzip master.zip
RUN cd glacier-master/rendering && go build -o glacier-renderer *.go && mv glacier-renderer /app/work && mv static /app/work
RUN rm -rf glacier-master
EXPOSE 9090
ENTRYPOINT ["/app/work/glacier-renderer", "--web", "/app/work/static", "--recurse", "--watch", "--syslog", "renderer", "/svr1/glacier/archive"]
