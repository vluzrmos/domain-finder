FROM golang:1.22-alpine3.20 AS builder

ARG SUBFINDER_VERSION=2.6.7
ARG DNSX_VERSION=1.2.1
ARG ALTERX_VERSION=0.0.4

RUN go install github.com/projectdiscovery/alterx/cmd/alterx@v${ALTERX_VERSION} && \
    go install github.com/projectdiscovery/dnsx/cmd/dnsx@v${DNSX_VERSION} && \
    go install github.com/projectdiscovery/subfinder/v2/cmd/subfinder@v${SUBFINDER_VERSION}

FROM alpine:3

## install dnsutils like dig then clear apk cache
RUN apk add --no-cache bind-tools bash jq curl && \
    rm -rf /var/cache/apk/*

COPY --from=builder /go/bin/alterx /usr/local/bin/alterx
COPY --from=builder /go/bin/dnsx /usr/local/bin/dnsx
COPY --from=builder /go/bin/subfinder /usr/local/bin/subfinder

COPY main.sh /usr/local/bin/domain-finder

# Set the working directory
WORKDIR /app

RUN chmod +x /usr/local/bin/domain-finder

ENTRYPOINT [ "domain-finder" ]
