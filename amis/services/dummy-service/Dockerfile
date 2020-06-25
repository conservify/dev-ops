FROM envoyproxy/envoy-alpine-dev:latest

RUN apk update && apk add python3 bash curl py3-pip
RUN which python3
RUN which pip3
RUN pip3 install -q Flask==0.11.1 requests==2.18.4

RUN mkdir /code

ADD ./service-envoy.yaml /etc/service-envoy.yaml
ADD ./service.py /code
ADD ./startup.sh /usr/local/bin/startup.sh
RUN chmod u+x /usr/local/bin/startup.sh

ENTRYPOINT /usr/local/bin/startup.sh
