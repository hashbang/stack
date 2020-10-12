ARG DEBIAN_IMAGE_HASH

FROM debian@sha256:${DEBIAN_IMAGE_HASH} as build

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    TZ=UTC \
    HOME=/home/build \
    PATH=/home/build/.local/bin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

ADD files /

## Install packages from packages.list with retry
RUN apt-install

## Globally freeze time/date syscalls for determinism
RUN enable-faketime

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
RUN git clone https://github.com/docker/distribution.git ~/src
RUN cd ~/src \
    && git checkout ${VERSION} \
    && CGO_ENABLED=0 make PREFIX=~/src/go binaries \
    && file ./bin/registry | grep "statically linked"

## Build rootfs
RUN mkdir -p ~/rootfs/etc \
    && echo "nogroup:*:100:nobody" > ~/rootfs/etc/group \
    && echo "nobody:*:100:100:::" > ~/rootfs/etc/passwd \
    && cp src/bin/registry ~/rootfs/ \
    && cp src/cmd/registry/config-dev.yml ~/rootfs/config.yml

## Create bare minimum output image
FROM scratch
COPY --from=build --chown=100:100 /home/build/rootfs /
STOPSIGNAL SIGQUIT
EXPOSE 8080
USER 100:100
VOLUME ["/var/lib/registry"]
ENTRYPOINT ["/registry"]
CMD ["serve", "/config.yml"]
