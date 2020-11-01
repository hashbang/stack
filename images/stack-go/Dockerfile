ARG FROM
FROM ${FROM}

## Fetch/Verify Sources
ARG VERSION=1.15.3
ARG HASH=896a602570e54c8cdfc2c1348abd4ffd1016758d0bd086ccd9787dbfc9b64888
ARG URL=https://storage.googleapis.com/golang/go1.15.3.src.tar.gz
ARG KEY=EB4C1BFD4F042F6DDDCCEC917721F63BD38B4796

RUN set -eux; \
    wget -O go.tgz.asc ${URL}.asc; \
    wget -O go.tgz ${URL}; \
    echo "${HASH} *go.tgz" | sha256sum --strict --check -; \
    export GNUPGHOME="$(mktemp -d)"; \
	gpg --batch --keyserver ha.pool.sks-keyservers.net --recv-keys ${KEY}; \
	gpg --batch --verify go.tgz.asc go.tgz; \
	gpgconf --kill all; \
	rm -rf "$GNUPGHOME" go.tgz.asc; \
	tar -C .local -xzf go.tgz; \
	rm go.tgz;

# Build
RUN ( cd .local/go/src && ./make.bash; ); \
    go install -race std; \
    rm -rf \
		/usr/local/go/pkg/*/cmd \
		/usr/local/go/pkg/bootstrap \
		/usr/local/go/pkg/obj \
		/usr/local/go/pkg/tool/*/api \
		/usr/local/go/pkg/tool/*/go_bootstrap \
		/usr/local/go/src/cmd/dist/dist \
	; \
    mv .local/go/bin/* .local/bin/; \
    go version

ENV GOBIN=/home/build/src/bin \
    GOPATH=/home/build/src/go \
    CGO_ENABLED=0 \
    GOOS=linux \
    GOARCH=amd64 \
    GO11MODULE=on \
    GOPROXY=direct

WORKDIR /src
ENTRYPOINT ["/usr/local/bin/host-env"]
CMD ["/usr/local/bin/build"]
