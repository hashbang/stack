ARG GIT_FROM
ARG BUILD_FROM

FROM ${GIT_FROM} as git
FROM ${BUILD_FROM} as build

## Build gitea binary
ARG URL
ARG REF
RUN git clone ${URL} ~/src \
    && cd ~/src \
    && git checkout ${REF} \
    && TAGS="bindata sqlite sqlite_unlock_notify" make build \
    && file ./gitea | grep "statically linked"

## Build rootfs
RUN mkdir -p ~/rootfs/etc ~/rootfs/tmp ~/rootfs/git ~/rootfs/data \
    && echo "nogroup:*:100:nobody" > ~/rootfs/etc/group \
    && echo "nobody:*:100:100:::" > ~/rootfs/etc/passwd \
    && cp ~/src/gitea ~/rootfs/

## Create bare minimum output image
FROM scratch
COPY --from=build --chown=100:100 /home/build/rootfs /
COPY --from=git --chown=100:100 / /bin
STOPSIGNAL SIGQUIT
EXPOSE 8080
USER 100:100
ENV GITEA_CUSTOM /data
ENV GITEA_TEMP /tmp
ENV GITEA_APP_INI /app.ini
ENV HOME /git
ENV PATH /bin
VOLUME ["/data"]
ENTRYPOINT ["/gitea"]
