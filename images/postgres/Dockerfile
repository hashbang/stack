ARG FROM
FROM ${FROM} as build

ARG URL
ARG REF
RUN git clone ${URL} ~/src \
    && cd ~/src \
    && git checkout ${REF} \
    && autoconf \
    && ./configure --prefix=${HOME}/out \
    && make install

RUN mkdir -p \
        ~/rootfs/etc \
        ~/rootfs/lib/x86_64-linux-gnu \
        ~/rootfs/lib64 \
        ~/rootfs/data \
        ~/rootfs/bin \
        ~/rootfs/tmp \
    && echo "nobody:x:100" > ~/rootfs/etc/group \
    && echo "nobody:x:100:100:nobody:/:/usr/bin/nologin" > ~/rootfs/etc/passwd \
    && cp /lib/x86_64-linux-gnu/libpthread.so.0 ~/rootfs/lib/x86_64-linux-gnu \
	&& cp /lib/x86_64-linux-gnu/librt.so.1 ~/rootfs/lib/x86_64-linux-gnu \
	&& cp /lib/x86_64-linux-gnu/libdl.so.2 ~/rootfs/lib/x86_64-linux-gnu \
	&& cp /lib/x86_64-linux-gnu/libm.so.6 ~/rootfs/lib/x86_64-linux-gnu \
	&& cp /lib/x86_64-linux-gnu/libc.so.6 ~/rootfs/lib/x86_64-linux-gnu \
	&& cp /lib64/ld-linux-x86-64.so.2 ~/rootfs/lib64 \
    && cp -a ~/out/. ~/rootfs/ \
    && chmod -R 700 ~/rootfs/data/ \
    && PGDATA=~/rootfs/data/ ~/rootfs/bin/pg_ctl initdb \
    && echo "listen_addresses='*'" > ~/rootfs/data/postgresql.conf

FROM scratch
COPY --from=build --chown=100:100 /home/build/rootfs /
STOPSIGNAL SIGQUIT
EXPOSE 5432
USER 100:100
ENV PGDATA=/data
ENV PATH=/bin
ENTRYPOINT ["/bin/postgres"]
