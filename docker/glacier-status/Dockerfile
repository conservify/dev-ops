FROM golang:1.8.1
RUN mkdir -p /app/work
WORKDIR /app/work
RUN apt-get update && apt-get install unzip
# RUN wget https://github.com/Conservify/glacier/archive/master.zip && unzip master.zip
COPY glacier /app/work/glacier-master
RUN go get github.com/hpcloud/tail
RUN go get github.com/sfreiberg/gotwilio
COPY secrets.go /app/work/glacier-master/log-monitor
RUN cd glacier-master/log-monitor && go build -o log-monitor *.go && mv log-monitor /app/work && mv static /app/work
RUN rm -rf glacier-master
EXPOSE 8000
ENTRYPOINT ["/app/work/log-monitor", "/var/log/syslog"]
