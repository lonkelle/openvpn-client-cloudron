FROM cloudron/base:2.0.0@sha256:f9fea80513aa7c92fe2e7bf3978b54c8ac5222f47a9a32a7f8833edf0eb5a4f4

EXPOSE 8000

# install tini
ADD https://github.com/krallin/tini/releases/download/v0.19.0/tini-amd64 /usr/bin/tini
RUN chmod +x /usr/bin/tini

# Install OpenVPN
RUN apt-get update -y
RUN apt-get -y install openvpn iptables && rm -rf /var/cache/apt /var/lib/apt/lists

RUN addgroup --system vpn

RUN mkdir -p /app/code
RUN mknod -m 0666 /app/code/net-tun c 10 200
RUN echo "nameserver 1.1.1.1" > /etc/resolv.conf

# configure apache
RUN rm /etc/apache2/sites-enabled/*
RUN sed -e 's,^ErrorLog.*,ErrorLog "|/bin/cat",' -i /etc/apache2/apache2.conf
RUN a2disconf other-vhosts-access-log
ADD apache.conf /etc/apache2/sites-enabled/vpn.conf
RUN echo "Listen 8000" > /etc/apache2/ports.conf
RUN a2enmod proxy proxy_http rewrite 

COPY openvpn.sh /usr/bin/
COPY index.html /app/code/
COPY vpn.conf /app/data/

HEALTHCHECK --interval=60s --timeout=15s --start-period=120s \
             CMD curl -LSs 'https://api.ipify.org'

WORKDIR /app/data

ENTRYPOINT ["/usr/bin/tini", "--", "/usr/bin/openvpn.sh"]