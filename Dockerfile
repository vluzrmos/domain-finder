FROM golang:1.22-alpine3.20 AS builder

RUN go install github.com/projectdiscovery/alterx/cmd/alterx@latest && \
    go install github.com/projectdiscovery/dnsx/cmd/dnsx@latest && \
    go install github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest

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
