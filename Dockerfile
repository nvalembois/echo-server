FROM golang:1.21.4 AS build

ARG TARGETOS
ARG TARGETARCH

USER 10000:10000

ADD . /go/src/github.com/nvalembois/echo-server
WORKDIR /go/src/github.com/nvalembois/echo-server

RUN CGO_ENABLED=0 GOOS=${TARGETOS} GOARCH=${TARGETARCH} \
    go build \
    -ldflags="-s -w" \
    -o echo-server .
RUN chmod u=rwx,g=rx,o=rx echo-server

RUN echo 'echo-server:x:10001:10001:echo-server:/:/usr/sbin/nologin' >/tmp/passwd \
 && echo 'echo-server:x:10001:' >/tmp/group \
 && chmod u=rw,g=r,o=r /tmp/passwd /tmp/group

FROM scratch
#LABEL maintainer="Nicolas Valembois <nvalembois@live.com>" \
#      org.opencontainers.image.authors="Nicolas Valembois <nvalembois@live.com>" \
#      org.opencontainers.image.description="Enregistrement DNS dans DuckDNS." \
#      org.opencontainers.image.licenses="Apache-2.0" \
#      org.opencontainers.image.source="git@github.com:nvalembois/duckdns-webhook" \
#      org.opencontainers.image.title="duckdns-webhook" \
#      org.opencontainers.image.url="https://github.com/nvalembois/duckdns-webhook"
COPY --from=build /go/src/github.com/nvalembois/echo-server/echo-server /echo-server
COPY --from=build /etc/ssl/certs /etc/ssl/certs
COPY --from=build --chown=0:0 /tmp/passwd /tmp/group /etc/

USER 10001:10001
EXPOSE 8080
ENTRYPOINT ["/echo-server"]
