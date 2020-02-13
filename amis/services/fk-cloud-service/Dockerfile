FROM conservify/fk-cloud:master AS fk

FROM envoyproxy/envoy-alpine-dev:latest AS envoy

ADD ./service-envoy.yaml /etc/service-envoy.yaml
ADD ./startup.sh /usr/local/bin/startup.sh
RUN chmod u+x /usr/local/bin/startup.sh

COPY --from=fk /api /app
COPY --from=fk /server /app
COPY --from=fk /portal /app
COPY --from=fk /ocr-portal /app
COPY --from=fk /legacy /app

ENTRYPOINT /usr/local/bin/startup.sh