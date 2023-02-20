ARG distr=bullseye
FROM debian:${distr}
ARG distr

ENV DEBIAN_FRONTEND noninteractive
MAINTAINER itaru2622

RUN echo "deb http://deb.debian.org/debian/ bullseye-backports main contrib non-free" | tee -a /etc/apt/sources.list.d/backports.list; \
    apt update && apt install -y vim procps make net-tools bash-completion curl bind9 dnsutils -t bullseye-backports

#  webmin:       cf. https://webmin.com/download/
RUN curl -o /tmp/setup-repo.sh -L https://raw.githubusercontent.com/webmin/webmin/master/setup-repos.sh; \
    yes | sh /tmp/setup-repo.sh; \
    apt-get install -y webmin systemctl; \
    sed -i 's/ssl=1/ssl=0/' /etc/webmin/miniserv.conf

ARG zoneDir=/etc/bind
ARG dnsdip=127.0.0.1
ARG forwarder=8.8.8.8
ARG rootpwd=root

RUN mv /etc/bind /etc/bind.orig; mkdir -p ${zoneDir}
COPY     Makefile README.md    ${zoneDir}/
RUN echo "root:${rootpwd}" | chpasswd; \
    make initConf -C  ${zoneDir}

WORKDIR  ${zoneDir}
EXPOSE   53 53/udp  10000
VOLUME   ["${zoneDir}"]
CMD      make start -C ${zoneDir}
ENV      zoneDir ${zoneDir}

LABEL baseImage debian:${distr}

# https://www.atmarkit.co.jp/ait/articles/0103/20/news002.html
# https://www.qoosky.io/techs/e6d99b0e7a
# https://www.internic.net/domain/named.root
