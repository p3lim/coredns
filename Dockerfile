ARG COREDNS_VERSION=1.11.1
FROM golang:1.20-bookworm AS build
ARG COREDNS_VERSION

ARG DEBIAN_FRONTEND=noninteractive
RUN <<EOF
  # install ca certs
  apt-get update
  apt-get -y install ca-certificates
  apt-get clean

  # clone coredns
  git clone --branch "v${COREDNS_VERSION}" --depth 1 https://github.com/coredns/coredns

  # inject plugin in a certain order (which is important)
  sed -i 's/^#.*//g; /^$/d; 50 i docker:github.com/kevinjqiu/coredns-dockerdiscovery' coredns/plugin.cfg

  # generate and update deps
  (cd coredns; go generate)
  (cd coredns; go mod tidy)

  # build
  (cd coredns; make)
EOF

# can't run rootless like the original coredns image because of the dockerdiscovery plugin
FROM scratch

# copy the binary and cert data
COPY --from=build /go/coredns/coredns /coredns
COPY --from=build /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/

EXPOSE 53 53/udp
ENTRYPOINT ["/coredns"]
