FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
RUN dpkg --add-architecture i386 \
    && apt-get update \
    && apt-get install --no-install-recommends -y ca-certificates curl lib32gcc-s1 lib32stdc++6 python3 wireguard-tools iproute2 iptables gosu \
    && rm -rf /var/lib/apt/lists/* \
    && useradd --create-home steam \
    && mkdir -p /opt/steamcmd \
    && curl --fail --show-error --location --retry 3 \
       --output /tmp/steamcmd_linux.tar.gz \
       https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz \
    && tar -xzf /tmp/steamcmd_linux.tar.gz -C /opt/steamcmd \
    && rm /tmp/steamcmd_linux.tar.gz \
    && chown -R steam:steam /opt/steamcmd

COPY --chmod=0644 publish.py /opt/publish.py
COPY --chmod=0644 vpn.py /opt/vpn.py
USER root
ENV HOME=/home/steam
WORKDIR /opt/steamcmd
ENTRYPOINT ["python3", "/opt/vpn.py"]
