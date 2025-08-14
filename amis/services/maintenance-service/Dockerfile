FROM envoyproxy/envoy-alpine:v1.16.2

RUN apk update && apk add python3 bash curl py3-pip
RUN which python3
RUN which pip3
RUN pip3 install -q flask requests

RUN mkdir /code

ADD ./service-envoy.yaml /etc/service-envoy.yaml
ADD ./service.py /code
ADD ./startup.sh /usr/local/bin/startup.sh
ADD ./static /code/static
RUN chmod u+x /usr/local/bin/startup.sh

EXPOSE 8000

ENTRYPOINT [ "/usr/local/bin/startup.sh" ]
