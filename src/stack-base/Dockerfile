ARG DEBIAN_IMAGE_HASH

FROM debian@sha256:${DEBIAN_IMAGE_HASH} as build

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    TZ=UTC \
    HOME=/home/build \
    PATH=/home/build/.local/bin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

ADD files /

RUN apt-install

RUN enable-faketime

RUN useradd -ms /bin/bash build
USER build
WORKDIR /home/build
RUN mkdir -p /home/build/.local/bin
