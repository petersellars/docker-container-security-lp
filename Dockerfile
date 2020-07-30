FROM alpine:3.12

LABEL maintainer="Anshuman Purohit<apurohit@enoviti.com>"

RUN apk add --no-cache \
    curl \
    git \
    openssh-client \
    rsync

ENV VERSION 0.64.0
WORKDIR  /usr/local/src 
SHELL ["/bin/ash", "-eo", "pipefail", "-c"]
# Install Hugo
RUN curl -L -o hugo_${VERSION}_Linux-64bit.tar.gz https://github.com/gohugoio/hugo/releases/download/v${VERSION}/hugo_${VERSION}_Linux-64bit.tar.gz \
    && curl -L https://github.com/gohugoio/hugo/releases/download/v${VERSION}/hugo_${VERSION}_checksums.txt | grep hugo_${VERSION}_Linux-64bit.tar.gz | sha256sum -c \
    && tar -xf hugo_${VERSION}_Linux-64bit.tar.gz \
    && rm hugo_${VERSION}_Linux-64bit.tar.gz \
    && mv hugo /usr/local/bin/hugo 
# Create hugo User and Group
RUN addgroup -Sg 1000 hugo \
    && adduser -SG hugo -u 1000 -h /src hugo

USER hugo
HEALTHCHECK --timeout=3s CMD hugo env || exit 1

WORKDIR /src

EXPOSE 1313