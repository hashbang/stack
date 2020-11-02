ARG FROM
FROM ${FROM} as build

## Build binary
ARG REF
ARG PCRE_HASH
ARG PCRE_VERSION
ADD --chown=build:build https://ftp.pcre.org/pub/pcre/pcre-${PCRE_VERSION}.tar.gz /tmp/pcre.tar.gz
RUN [ "$PCRE_HASH" = "$(sha256sum /tmp/pcre.tar.gz | awk '{print $1}')" ] \
    && tar -C /tmp/ -xf /tmp/pcre.tar.gz \
    && mv /tmp/pcre-${PCRE_VERSION} /home/build/pcre \
    && git clone https://github.com/nginx/nginx.git /home/build/nginx
RUN cd /home/build/nginx \
    && git checkout ${REF} \
    && ./auto/configure \
        --with-pcre=/home/build/pcre \
        --with-cc="musl-gcc" \
        --with-cc-opt="-static" \
        --with-ld-opt="-static" \
        --with-pcre \
        --with-http_sub_module \
        --with-stream \
        --with-threads \
        --without-http_gzip_module \
        --http-client-body-temp-path=/tmp/client-body \
        --http-proxy-temp-path=/tmp/proxy \
        --http-fastcgi-temp-path=/tmp/fastcgi \
        --http-uwsgi-temp-path=/tmp/uwsgi \
        --http-scgi-temp-path=/tmp/scgi \
        --http-log-path=/dev/stdout \
        --error-log-path=/dev/stderr \
        --conf-path=/nginx.conf \
        --pid-path=/tmp/nginx.pid \
        --sbin-path=/nginx \
    && make

## Build rootfs
RUN mkdir -p /home/build/rootfs/etc \
    && cp /home/build/nginx/objs/nginx /home/build/rootfs/ \
    && echo "nogroup:*:100:nobody" > /home/build/rootfs/etc/group \
    && echo "nobody:*:100:100:::" > /home/build/rootfs/etc/passwd \
    && mkdir /home/build/rootfs/tmp \
    && touch /home/build/rootfs/tmp/.keep
ADD nginx.conf /home/build/rootfs/

# Create bare minimum output image
FROM scratch
COPY --from=build --chown=100:100 /home/build/rootfs /
STOPSIGNAL SIGQUIT
EXPOSE 8080
USER 100:100
ENTRYPOINT ["/nginx"]
CMD ["-g", "daemon off;"]
