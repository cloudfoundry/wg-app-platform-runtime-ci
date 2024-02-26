# Dockerfile name: mysql-8.0
# should be located at cloudfoundry/tas-runtime-mysql-8.0
###
ARG BUILD_URI

FROM ${BUILD_URI} AS build

ARG MYSQL_MAJOR_VERSION
# MYSQL_VERSION needs to come from https://github.com/docker-library/mysql/blob/master/versions.json#L41 ultimately
ARG MYSQL_VERSION

LABEL org.cloudfoundry.tas-runtime-mysql-8.0.dockerfile.url="https://github.com/cloudfoundry/wg-app-platform-runtime-ci/blob/main/shared/dockerfiles/tas-runtime-mysql-8.0/Dockerfile"
LABEL org.cloudfoundry.tas-runtime-mysql-8.0.notes.md="Build upon tas-runtime-build with mysql"

### The following section is taken and modified from https://github.com/docker-library/mysql/ ###
#
# add our user and group first to make sure their IDs get assigned consistently, regardless of whatever dependencies get added
RUN groupadd -r mysql && useradd -r -g mysql mysql

ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends gnupg gosu dirmngr tzdata zstd && rm -rf /var/lib/apt/lists/*

RUN mkdir /docker-entrypoint-initdb.d

RUN set -eux; \
	key='bca43417c3b485dd128ec6d4b7b3b788a8d3785c'; \
	export GNUPGHOME="$(mktemp -d)"; \
	gpg --batch --keyserver keyserver.ubuntu.com --recv-keys "$key"; \
	mkdir -p /etc/apt/keyrings; \
	gpg --batch --export "$key" > /etc/apt/keyrings/mysql.gpg; \
	gpgconf --kill all; \
	rm -rf "$GNUPGHOME"

RUN export DISTRUBTION_CODENAME=$(cat /etc/lsb-release  | grep DISTRIB_CODENAME | cut -f 2 -d =); \
    echo "deb [ signed-by=/etc/apt/keyrings/mysql.gpg ] http://repo.mysql.com/apt/ubuntu/ ${DISTRUBTION_CODENAME} mysql-${MYSQL_MAJOR_VERSION}" > /etc/apt/sources.list.d/mysql.list

# the "/var/lib/mysql" stuff here is because the mysql-server postinst doesn't have an explicit way to disable the mysql_install_db codepath besides having a database already "configured" (ie, stuff in /var/lib/mysql/mysql)
# also, we set debconf keys to make APT a little quieter
RUN export DISTRUBTION_RELEASE=$(cat /etc/lsb-release  | grep DISTRIB_RELEASE | cut -f 2 -d =); \
    export MYSQL_PACKAGE_VERSION="${MYSQL_VERSION}-1ubuntu${DISTRUBTION_RELEASE}"; \
    echo "MYSQL_PACKAGE_VERSION: $MYSQL_PACKAGE_VERSION"; \
    { \
		echo mysql-community-server mysql-community-server/data-dir select ''; \
		echo mysql-community-server mysql-community-server/root-pass password ''; \
		echo mysql-community-server mysql-community-server/re-root-pass password ''; \
		echo mysql-community-server mysql-community-server/remove-test-db select false; \
	} | debconf-set-selections \
	&& apt-get update \
	&& apt-get install -y \
		mysql-community-client="${MYSQL_PACKAGE_VERSION}" \
		mysql-community-server-core="${MYSQL_PACKAGE_VERSION}" \
	&& rm -rf /var/lib/apt/lists/* \
	&& rm -rf /var/lib/mysql && mkdir -p /var/lib/mysql /var/run/mysqld \
	&& chown -R mysql:mysql /var/lib/mysql /var/run/mysqld \
# ensure that /var/run/mysqld (used for socket and lock files) is writable regardless of the UID our mysqld instance ends up having at runtime
	&& chmod 1777 /var/run/mysqld /var/lib/mysql

VOLUME /var/lib/mysql

# Config files
COPY config/ /etc/mysql/
COPY protocols /etc/protocols
COPY mysql-entrypoint.sh /mysql-entrypoint.sh
ENTRYPOINT ["/mysql-entrypoint.sh"]

EXPOSE 3306 33060
CMD ["mysqld"]
