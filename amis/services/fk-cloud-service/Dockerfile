FROM conservify/fk-cloud:main AS fk

FROM envoyproxy/envoy-alpine:v1.16.0 AS envoy

RUN mkdir -p /app/api /app/portal /app/ocr-portal /app/legacy
RUN mkdir -p /etc/ssl/certs/

COPY --from=fk /ingester /app
COPY --from=fk /server /app
COPY --from=fk /api /app/api
COPY --from=fk /portal/ /app/portal
COPY --from=fk /ca-certificates.crt /etc/ssl/certs
COPY --from=fk /static.env /etc/static.env

ADD ./service-envoy.yaml /etc/service-envoy.yaml
ADD ./startup.sh /usr/local/bin/startup.sh
RUN chmod u+x /usr/local/bin/startup.sh

ENTRYPOINT [ "/usr/local/bin/startup.sh" ]
CMD []
