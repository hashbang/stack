FROM debian:buster

RUN apt update \
    && apt install -y git curl vim nano build-essential docker.io

WORKDIR /src

ENV PATH=/home/build/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
ADD images/stack-shared/host-env /usr/local/bin/host-env

WORKDIR /src
ENTRYPOINT ["/usr/local/bin/host-env"]
CMD ["/bin/bash"]
