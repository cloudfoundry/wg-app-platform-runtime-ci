# Dockerfile name: postgres
# should be located at cloudfoundry/tas-runtime-postgres
###
ARG BUILD_URI

FROM ${BUILD_URI} AS build

LABEL org.cloudfoundry.tas-runtime-postgres.dockerfile.url="https://github.com/cloudfoundry/wg-app-platform-runtime-ci/blob/main/shared/dockerfiles/tas-runtime-postgres/Dockerfile"
LABEL org.cloudfoundry.tas-runtime-postgres.notes.md="Build upon tas-runtime-build with postgres"

ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update -y && apt-get install -y --no-install-recommends \
  g++ \
  netcat \
  postgresql-common \
  gnupg2 \
  gosu \
  &&  apt-get autoremove -yqq \
  &&  apt-get clean \
  &&  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# https://wiki.postgresql.org/wiki/Apt
RUN yes | sh /usr/share/postgresql-common/pgdg/apt.postgresql.org.sh \
  && apt-get install postgresql -y --no-install-recommends


### The following section is from https://github.com/docker-library/postgrstartes/blob/master/15/bullseye/Dockerfile ###
RUN mkdir /docker-entrypoint-initdb.d

RUN set -eux; \
# create the postgres user's home directory with appropriate permissions
# see https://github.com/docker-library/postgres/issues/274
	mkdir -p /var/lib/postgresql; \
	chown -R postgres:postgres /var/lib/postgresql


# make the "en_US.UTF-8" locale so postgres will be utf-8 enabled by default
RUN set -eux; \
	apt-get update; apt-get install -y --no-install-recommends locales; rm -rf /var/lib/apt/lists/*; \
	localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8
ENV LANG en_US.utf8


# make the sample config easier to munge (and "correct by default")
RUN set -eux; \
    export PG_MAJOR=$(ls /usr/lib/postgresql/); \
    dpkg-divert --add --rename --divert "/usr/share/postgresql/postgresql.conf.sample.dpkg" "/usr/share/postgresql/$PG_MAJOR/postgresql.conf.sample"; \
	cp -v /usr/share/postgresql/postgresql.conf.sample.dpkg /usr/share/postgresql/postgresql.conf.sample; \
	ln -sv ../postgresql.conf.sample "/usr/share/postgresql/$PG_MAJOR/"; \
	sed -ri "s!^#?(listen_addresses)\s*=\s*\S+.*!\1 = '*'!" /usr/share/postgresql/postgresql.conf.sample; \
	grep -F "listen_addresses = '*'" /usr/share/postgresql/postgresql.conf.sample

RUN set -eux; \
    export PG_MAJOR=$(ls /usr/lib/postgresql/); \
    ln -sv /usr/lib/postgresql/$PG_MAJOR/bin /usr/lib/postgresql/bin

ENV PATH $PATH:/usr/lib/postgresql/bin


RUN mkdir -p /var/run/postgresql && chown -R postgres:postgres /var/run/postgresql && chmod 2777 /var/run/postgresql

ENV PGDATA /var/lib/postgresql/data

# this 777 will be replaced by 700 at runtime (allows semi-arbitrary "--user" values)
RUN mkdir -p "$PGDATA" && chown -R postgres:postgres "$PGDATA" && chmod 777 "$PGDATA"
VOLUME /var/lib/postgresql/data
  
ENV POSTGRES_HOST_AUTH_METHOD trust

COPY postgres-entrypoint.sh /postgres-entrypoint.sh
RUN chmod +x /postgres-entrypoint.sh

ENTRYPOINT ["/postgres-entrypoint.sh"]

# We set the default STOPSIGNAL to SIGINT, which corresponds to what PostgreSQL
# calls "Fast Shutdown mode" wherein new connections are disallowed and any
# in-progress transactions are aborted, allowing PostgreSQL to stop cleanly and
# flush tables to disk, which is the best compromise available to avoid data
# corruption.
#
# Users who know their applications do not keep open long-lived idle connections
# may way to use a value of SIGTERM instead, which corresponds to "Smart
# Shutdown mode" in which any existing sessions are allowed to finish and the
# server stops when all sessions are terminated.
#
# See https://www.postgresql.org/docs/12/server-shutdown.html for more details
# about available PostgreSQL server shutdown signals.
#
# See also https://www.postgresql.org/docs/12/server-start.html for further
# justification of this as the default value, namely that the example (and
# shipped) systemd service files use the "Fast Shutdown mode" for service
# termination.
#
STOPSIGNAL SIGINT
#
# An additional setting that is recommended for all users regardless of this
# value is the runtime "--stop-timeout" (or your orchestrator/runtime's
# equivalent) for controlling how long to wait between sending the defined
# STOPSIGNAL and sending SIGKILL (which is likely to cause data corruption).
#
# The default in most runtimes (such as Docker) is 10 seconds, and the
# documentation at https://www.postgresql.org/docs/12/server-start.html notes
# that even 90 seconds may not be long enough in many instances.

EXPOSE 5432
### End Section ###

CMD ["postgres"]
