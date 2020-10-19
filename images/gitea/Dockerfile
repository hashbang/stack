ARG DEBIAN_IMAGE_HASH

FROM debian@sha256:${DEBIAN_IMAGE_HASH} as build

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    TZ=UTC \
    HOME=/home/build \
    PATH=/home/build/.local/bin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

RUN echo "deb http://deb.debian.org/debian buster-backports main contrib" >> \
    /etc/apt/sources.list

RUN apt update \
    && apt install -y git curl build-essential docker.io file \
    && apt install -yt buster-backports golang

ADD files /

## Create user and pivot to it
RUN useradd -ms /bin/bash build
WORKDIR /home/build
USER build

ENV GOBIN=/home/build/src/bin \
    GOPATH=/home/build/src/go \
    CGO_ENABLED=0 \
    GOOS=linux \
    GOARCH=amd64

## Build binary
ARG VERSION
RUN git clone https://github.com/go-gitea/gitea.git ~/src
RUN cd ~/src \
    && git checkout ${VERSION} \
    && make backend \
    && file ./gitea | grep "statically linked"

## Build rootfs
RUN mkdir -p ~/rootfs/etc \
    && echo "nogroup:*:100:nobody" > ~/rootfs/etc/group \
    && echo "nobody:*:100:100:::" > ~/rootfs/etc/passwd \
    && mkdir ~/rootfs/data \
    && cp src/gitea ~/rootfs/

## Create bare minimum output image
FROM scratch
COPY --from=build --chown=100:100 /home/build/rootfs /
STOPSIGNAL SIGQUIT
EXPOSE 8080
USER 100:100
ENV GITEA_CUATOM /data
VOLUME ["/data"]
ENTRYPOINT ["/gitea"]
