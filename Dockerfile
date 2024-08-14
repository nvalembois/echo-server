FROM docker.io/library/golang:1.23.0@sha256:8e529b64d382182bb84f201dea3c72118f6ae9bc01d27190ffc5a54acf0091d2 AS build

ARG TARGETOS
ARG TARGETARCH

ADD . /go/src/github.com/nvalembois/echo-server
WORKDIR /go/src/github.com/nvalembois/echo-server

RUN ls
RUN CGO_ENABLED=0 GOOS=${TARGETOS} GOARCH=${TARGETARCH} \
    go build \
    -ldflags='-s -w' \
    -o echo-server echo-server.go
RUN chmod u=rwx,g=rx,o=rx echo-server

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

USER 10001:10001
EXPOSE 8080
ENTRYPOINT ["/echo-server"]
