FROM debian:buster as build

RUN echo "deb http://deb.debian.org/debian buster-backports main contrib" >> \
    /etc/apt/sources.list

RUN apt update \
    && apt install -y git \
    && apt install -yt buster-backports golang

ARG URL
ARG REF
RUN git clone $URL /src \
    && cd /src \
    && git checkout $REF

WORKDIR /src

ENV GOBIN=/src/bin \
    GOPATH=/src/go \
    CGO_ENABLED=0 \
    GO11MODULE=on \
    GOOS=linux \
    GOARCH=amd64 \
    GOPROXY=direct

ARG BIN
RUN go mod download
RUN go build -v -trimpath -ldflags="-w" -o /src/bin/$BIN

FROM scratch
COPY --from=build /src/bin/$BIN /$BIN
CMD ["/bin/$BIN"]
