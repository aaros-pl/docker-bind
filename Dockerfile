FROM ubuntu:jammy-20220428 AS add-apt-repositories

RUN apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y gnupg wget \
 && wget http://www.webmin.com/jcameron-key.asc \
 && gpg --no-default-keyring --keyring ./temp-keyring.gpg --import jcameron-key.asc \
 && mkdir /etc/keyrings \
 && gpg --no-default-keyring --keyring ./temp-keyring.gpg --export --output /etc/keyrings/jcameron-key.gpg && rm temp-keyring.gpg \
 && echo "deb [signed-by=/etc/keyrings/jcameron-key.gpg] http://download.webmin.com/download/repository sarge contrib" >> /etc/apt/sources.list.d/webmin.list

FROM ubuntu:jammy-20220428

LABEL maintainer="aaros.pl@gmail.com"

ENV BIND_USER=bind \
    BIND_VERSION=9.18.3 \
    WEBMIN_VERSION=1.993 \
    DATA_DIR=/data \
    WEBMIN_DIR=/webmin

COPY --from=add-apt-repositories /etc/keyrings/jcameron-key.gpg /etc/keyrings/jcameron-key.gpg

COPY --from=add-apt-repositories /etc/apt/sources.list.d/webmin.list /etc/apt/sources.list.d/webmin.list

RUN rm -rf /etc/apt/apt.conf.d/docker-gzip-indexes \
 && apt-get update \
 && apt-get install -y software-properties-common \
 && add-apt-repository -y ppa:isc/bind
RUN apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y \
      bind9=1:${BIND_VERSION}* bind9-host=1:${BIND_VERSION}* dnsutils \
      webmin=${WEBMIN_VERSION}* \
 && rm -rf /var/lib/apt/lists/* \
 && apt-get --purge -y autoremove policykit-1

COPY entrypoint.sh /sbin/entrypoint.sh

RUN chmod 755 /sbin/entrypoint.sh

EXPOSE 53/udp 53/tcp 10000/tcp

ENTRYPOINT ["/sbin/entrypoint.sh"]

CMD ["/usr/sbin/named"]
