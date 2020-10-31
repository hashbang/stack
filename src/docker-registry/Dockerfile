ARG FROM
FROM ${FROM} as build

## Build binary
ARG URL
ARG REF
RUN git clone ${URL} ~/src \
    && cd ~/src \
    && git checkout ${REF} \
    && go get . \
    && make PREFIX=~/src/go binaries \
    && file ./bin/registry | grep "statically linked"

## Build rootfs
RUN mkdir -p ~/rootfs/etc \
    && echo "nogroup:*:100:nobody" > ~/rootfs/etc/group \
    && echo "nobody:*:100:100:::" > ~/rootfs/etc/passwd \
    && mkdir ~/rootfs/data \
    && cp ~/src/bin/registry ~/rootfs/ \
    && cp ~/src/cmd/registry/config-dev.yml ~/rootfs/config.yml

## Create bare minimum output image
FROM scratch
COPY --from=build --chown=100:100 /home/build/rootfs /
STOPSIGNAL SIGQUIT
EXPOSE 5000
USER 100:100
ENV REGISTRY_STORAGE_FILESYSTEM_ROOTDIRECTORY=/data
VOLUME ["/data"]
ENTRYPOINT ["/registry"]
CMD ["serve", "/config.yml"]
