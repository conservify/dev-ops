FROM conservify/fk-cloud:master AS fk

FROM envoyproxy/envoy-alpine-dev:latest AS envoy

ADD ./service-envoy.yaml /etc/service-envoy.yaml
ADD ./startup.sh /usr/local/bin/startup.sh
RUN chmod u+x /usr/local/bin/startup.sh

RUN mkdir -p /app/api
RUN mkdir -p /app/portal
RUN mkdir -p /app/ocr-portal
RUN mkdir -p /app/legacy

COPY --from=fk /ingester /app
COPY --from=fk /server /app
COPY --from=fk /api /app/api
COPY --from=fk /portal/ /app/portal
COPY --from=fk /ocr-portal /app/ocr-portal
COPY --from=fk /legacy /app/legacy

ENTRYPOINT /usr/local/bin/startup.sh