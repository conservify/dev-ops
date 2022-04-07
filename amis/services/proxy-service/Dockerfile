FROM envoyproxy/envoy:v1.21.1

RUN apt-get update && apt-get -q install -y curl && rm -rf /var/lib/{apt,dpkg,cache,log}/

COPY envoy-proxy.yaml /etc

CMD [ "/usr/local/bin/envoy", "-c", "/etc/envoy-proxy.yaml", "--service-cluster proxy" ]
