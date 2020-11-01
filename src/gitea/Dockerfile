ARG FROM
FROM ${FROM} as build

## Build binary
ARG URL
ARG REF
RUN git clone ${URL} ~/src \
    && cd ~/src \
    && git checkout ${REF} \
    && make backend \
    && file ./gitea | grep "statically linked"

## Build rootfs
RUN mkdir -p ~/rootfs/etc \
    && echo "nogroup:*:100:nobody" > ~/rootfs/etc/group \
    && echo "nobody:*:100:100:::" > ~/rootfs/etc/passwd \
    && mkdir ~/rootfs/data \
    && cp ~/src/gitea ~/rootfs/

## Create bare minimum output image
FROM scratch
COPY --from=build --chown=100:100 /home/build/rootfs /
STOPSIGNAL SIGQUIT
EXPOSE 8080
USER 100:100
ENV GITEA_CUSTOM /data
VOLUME ["/data"]
ENTRYPOINT ["/gitea"]
