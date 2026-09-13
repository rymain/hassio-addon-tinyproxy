ARG BUILD_FROM=alpine:3.21
FROM ${BUILD_FROM}

RUN apk add --no-cache tinyproxy jq

COPY run.sh /run.sh
RUN chmod +x /run.sh

ENTRYPOINT ["/run.sh"]

ARG BUILD_ARCH
ARG BUILD_VERSION
LABEL \
  io.hass.name="Tinyproxy" \
  io.hass.description="Private HTTP/HTTPS forward proxy" \
  io.hass.type="addon" \
  io.hass.arch="${BUILD_ARCH}" \
  io.hass.version="${BUILD_VERSION}" \
  org.opencontainers.image.source="https://github.com/rymain/hassio-addon-tinyproxy"
