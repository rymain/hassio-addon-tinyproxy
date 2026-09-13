ARG BUILD_FROM
FROM ${BUILD_FROM}

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN apk add --no-cache tinyproxy

COPY rootfs /

RUN chmod a+x \
      /etc/s6-overlay/s6-rc.d/tinyproxy/run \
      /etc/s6-overlay/s6-rc.d/tinyproxy/finish

ARG BUILD_ARCH
ARG BUILD_VERSION
LABEL \
  io.hass.name="Tinyproxy" \
  io.hass.description="Private HTTP/HTTPS forward proxy" \
  io.hass.type="addon" \
  io.hass.arch="${BUILD_ARCH}" \
  io.hass.version="${BUILD_VERSION}"
