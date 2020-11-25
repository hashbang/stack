ARG FROM
FROM ${FROM} as build

#CC="musl-gcc" \
ARG URL
ARG REF
RUN git clone ${URL} ~/src \
    && cd ~/src \
    && git checkout ${REF} \
    && make CFLAGS="-static -static-libgcc" git \
    && file ${HOME}/src/git | grep "statically linked"

RUN mkdir -p ~/rootfs/etc \
    && echo "nogroup:*:100:nobody" > ~/rootfs/etc/group \
    && echo "nobody:*:100:100:::" > ~/rootfs/etc/passwd \
    && cp ~/src/git ~/rootfs/

FROM scratch
COPY --from=build --chown=100:100 /home/build/rootfs /
ENTRYPOINT ["/git"]
