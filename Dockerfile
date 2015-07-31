# Build a notary-signer container without the build environment

FROM ubuntu:14.04

RUN apt-get update && \
    apt-get install -y libltdl7 sqlite3 ca-certificates && \
    rm -rf /var/lib/apt/lists/*

RUN buildDeps=' \
	autoconf \
	automake \
	build-essential \
	libtool \
	libssl-dev \
	libsqlite3-dev \
	git \
    ' \
    && set -x \
    && apt-get update && apt-get install -y $buildDeps --no-install-recommends \
    && rm -rf /var/lib/apt/lists/* \
    && git clone https://github.com/opendnssec/SoftHSMv2.git /usr/src/SoftHSMv2 \
    && cd /usr/src/SoftHSMv2 \
    && sh autogen.sh \
    && ./configure --with-objectstore-backend-db \
    && make \
    && make install \
    && rm -rf /usr/src/SoftHSMv2 \
    && apt-get purge -y --auto-remove $buildDeps \
    && mkdir -p /softhsm2/tokens

# Default locations for the SoftHSM2 configuration and PKCS11 bindings
ENV SOFTHSM2_CONF="/etc/softhsm2/softhsm2.conf"
ENV LIBDIR="/usr/local/lib/softhsm/"

COPY ./notary-signer/notary-signer /bin/notary-signer
COPY ./notary-signer/config.json /etc/docker/notary-signer/config.json
COPY ./notary-signer/fixtures /fixtures
COPY ./notary-signer/softhsm2.conf /etc/softhsm2/softhsm2.conf

EXPOSE 4443
ENTRYPOINT ["/bin/notary-signer"]
CMD ["-config", "/etc/docker/notary-signer/config.json"]
