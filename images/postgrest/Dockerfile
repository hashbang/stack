ARG FROM
FROM ${FROM} as build

ARG URL
ARG REF
RUN git clone ${URL} ~/src \
    && cd ~/src \
    && git checkout ${REF} \
    && stack upgrade \
    && ~/.local/bin/stack build \
        --install-ghc \
        --copy-bins \
        --local-bin-path ~/out

RUN mkdir -p \
        ~/rootfs/etc \
        ~/rootfs/lib64/x86_64-linux-gnu \
        ~/rootfs/lib/x86_64-linux-gnu \
        ~/rootfs/usr/lib/x86_64-linux-gnu \
    && echo "nobody:x:100" > ~/rootfs/etc/group \
    && echo "nobody:x:100:100:nobody:/:/usr/bin/nologin" > ~/rootfs/etc/passwd \
    && cp -a ~/out/postgrest ~/rootfs/ \
    && cp /lib64/ld-linux-x86-64.so.2 ~/rootfs/lib64/x86_64-linux-gnu \
    && cp /lib/x86_64-linux-gnu/libm.so.6 ~/rootfs/lib/x86_64-linux-gnu \
    && cp /lib/x86_64-linux-gnu/libz.so.1 ~/rootfs/lib/x86_64-linux-gnu \
    && cp /lib/x86_64-linux-gnu/libpthread.so.0 ~/rootfs/lib/x86_64-linux-gnu \
    && cp /lib/x86_64-linux-gnu/librt.so.1 ~/rootfs/lib/x86_64-linux-gnu \
    && cp /lib/x86_64-linux-gnu/libutil.so.1 ~/rootfs/lib/x86_64-linux-gnu \
    && cp /lib/x86_64-linux-gnu/libdl.so.2 ~/rootfs/lib/x86_64-linux-gnu \
    && cp /lib/x86_64-linux-gnu/libc.so.6 ~/rootfs/lib/x86_64-linux-gnu \
    && cp /lib/x86_64-linux-gnu/libcom_err.so.2 ~/rootfs/lib/x86_64-linux-gnu \
    && cp /lib/x86_64-linux-gnu/libkeyutils.so.1 ~/rootfs/lib/x86_64-linux-gnu \
    && cp /lib/x86_64-linux-gnu/libresolv.so.2 ~/rootfs/lib/x86_64-linux-gnu \
    && cp /usr/lib/x86_64-linux-gnu/libgmp.so.10 ~/rootfs/usr/lib/x86_64-linux-gnu \
    && cp /usr/lib/x86_64-linux-gnu/libpq.so.5 ~/rootfs/usr/lib/x86_64-linux-gnu \
    && cp /usr/lib/x86_64-linux-gnu/libssl.so.1.1 ~/rootfs/usr/lib/x86_64-linux-gnu \
    && cp /usr/lib/x86_64-linux-gnu/libcrypto.so.1.1 ~/rootfs/usr/lib/x86_64-linux-gnu \
    && cp /usr/lib/x86_64-linux-gnu/libgssapi_krb5.so.2 ~/rootfs/usr/lib/x86_64-linux-gnu \
    && cp /usr/lib/x86_64-linux-gnu/libldap_r-2.4.so.2 ~/rootfs/usr/lib/x86_64-linux-gnu \
    && cp /usr/lib/x86_64-linux-gnu/libkrb5.so.3 ~/rootfs/usr/lib/x86_64-linux-gnu \
    && cp /usr/lib/x86_64-linux-gnu/libk5crypto.so.3 ~/rootfs/usr/lib/x86_64-linux-gnu \
    && cp /usr/lib/x86_64-linux-gnu/libkrb5support.so.0 ~/rootfs/usr/lib/x86_64-linux-gnu \
    && cp /usr/lib/x86_64-linux-gnu/liblber-2.4.so.2 ~/rootfs/usr/lib/x86_64-linux-gnu \
    && cp /usr/lib/x86_64-linux-gnu/libsasl2.so.2 ~/rootfs/usr/lib/x86_64-linux-gnu \
    && cp /usr/lib/x86_64-linux-gnu/libgnutls.so.30 ~/rootfs/usr/lib/x86_64-linux-gnu \
    && cp /usr/lib/x86_64-linux-gnu/libp11-kit.so.0 ~/rootfs/usr/lib/x86_64-linux-gnu \
    && cp /usr/lib/x86_64-linux-gnu/libidn2.so.0 ~/rootfs/usr/lib/x86_64-linux-gnu \
    && cp /usr/lib/x86_64-linux-gnu/libunistring.so.2 ~/rootfs/usr/lib/x86_64-linux-gnu \
    && cp /usr/lib/x86_64-linux-gnu/libtasn1.so.6 ~/rootfs/usr/lib/x86_64-linux-gnu \
    && cp /usr/lib/x86_64-linux-gnu/libnettle.so.6 ~/rootfs/usr/lib/x86_64-linux-gnu \
    && cp /usr/lib/x86_64-linux-gnu/libhogweed.so.4 ~/rootfs/usr/lib/x86_64-linux-gnu \
    && cp /usr/lib/x86_64-linux-gnu/libffi.so.6 ~/rootfs/usr/lib/x86_64-linux-gnu/

COPY postgrest.conf /home/build/rootfs/postgrest.conf

FROM scratch
COPY --from=build --chown=100:100 /home/build/rootfs /
STOPSIGNAL SIGQUIT
EXPOSE 3000
USER 100:100
ENV PATH=/bin \
    PGRST_DB_URI= \
    PGRST_DB_SCHEMA=public \
    PGRST_DB_ANON_ROLE= \
    PGRST_DB_POOL=100 \
    PGRST_DB_EXTRA_SEARCH_PATH=public \
    PGRST_SERVER_HOST=*4 \
    PGRST_SERVER_PORT=3000 \
    PGRST_SERVER_PROXY_URI= \
    PGRST_JWT_SECRET= \
    PGRST_SECRET_IS_BASE64=false \
    PGRST_JWT_AUD= \
    PGRST_MAX_ROWS= \
    PGRST_PRE_REQUEST= \
    PGRST_ROLE_CLAIM_KEY=".role" \
    PGRST_ROOT_SPEC= \
    PGRST_RAW_MEDIA_TYPES=
ENTRYPOINT ["/postgrest"]
CMD ["/postgrest.conf"]
