ARG COREDNS_VERSION=1.11.0
FROM golang:1.20-bookworm AS build
ARG COREDNS_VERSION

ARG DEBIAN_FRONTEND=noninteractive
RUN <<EOF
  # install deps for adjusting binary capabilities
  apt-get update
  apt-get -y install libcap2-bin
  apt-get clean

  # clone coredns
  git clone --branch "v${COREDNS_VERSION}" --depth 1 https://github.com/coredns/coredns

  # inject plugin
  echo 'docker:github.com/kevinjqiu/coredns-dockerdiscovery' >> coredns/plugin.cfg

  # build
  (cd coredns; make all)

  # adjust binary capabilities
  setcap cap_net_bind_service=+ep coredns/coredns
EOF

# base off original image
FROM coredns/coredns:$COREDNS_VERSION

# copy our modified coredns binary
COPY --from=build /go/coredns/coredns /coredns

# use fields from original image
USER nonroot:nonroot
EXPOSE 53 53/udp
ENTRYPOINT ["/coredns"]

# set custom command as default (just because it's annoying)
CMD ["-conf", "/Corefile"]

