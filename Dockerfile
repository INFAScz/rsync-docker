FROM alpine

LABEL maintainer="Daniel Prim <prim@infas.cz>"
LABEL forked.from="https://github.com/ogivuk/rsync-docker"

RUN apk add --update-cache \
    rsync \
    bash \
    openssh-client \
    tzdata \
 && rm -rf /var/cache/apk/*

RUN mkdir -p /data

WORKDIR /data
VOLUME /data

COPY rsync.sh .

ENTRYPOINT [ "./rsync.sh" ]
