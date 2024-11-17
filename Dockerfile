FROM alpine:3

## install dnsutils like dig then clear apk cache
RUN apk add --no-cache bind-tools bash jq curl && \
    rm -rf /var/cache/apk/*

COPY --from=projectdiscovery/alterx:v0.0.4 /usr/local/bin/alterx /usr/local/bin/alterx
COPY --from=projectdiscovery/dnsx:v1.2.1 /usr/local/bin/dnsx /usr/local/bin/dnsx
COPY --from=projectdiscovery/subfinder:v2.6.7 /usr/local/bin/subfinder /usr/local/bin/subfinder

COPY main.sh /usr/local/bin/domain-finder
RUN chmod +x /usr/local/bin/domain-finder

# Set the working directory
WORKDIR /app

ENTRYPOINT [ "domain-finder" ]
