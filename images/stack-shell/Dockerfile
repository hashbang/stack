FROM debian:buster as build

RUN echo "deb http://deb.debian.org/debian buster-backports main contrib" >> \
    /etc/apt/sources.list

RUN apt update \
    && apt install -y git curl vim nano build-essential docker.io

WORKDIR /src

ENV PATH=/home/build/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
ADD images/stack-shared/host-env /usr/local/bin/host-env

WORKDIR /src
ENTRYPOINT ["/usr/local/bin/host-env"]
CMD ["/bin/bash"]
