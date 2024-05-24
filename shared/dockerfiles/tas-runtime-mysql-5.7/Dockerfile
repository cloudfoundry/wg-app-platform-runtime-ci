# Dockerfile name: mysql-5.7
# should be located at cloudfoundry/tas-runtime-mysql-5.7
#
# Notice that this deviates from the standard images! This is because Jammy is
# an unsupported OS for MySQL 5.7.
#
###
ARG MYSQL_URI
FROM ${MYSQL_URI}

LABEL org.cloudfoundry.tas-runtime-mysql-5.7.dockerfile.url="https://github.com/cloudfoundry/wg-app-platform-runtime-ci/blob/main/shared/dockerfiles/tas-runtime-mysql-5.7/Dockerfile"
LABEL org.cloudfoundry.tas-runtime-mysql-5.7.notes.md="Build from debian image with 5.7-debian tag"

ENV DEBIAN_FRONTEND noninteractive

# install build dependencies
# - graphviz is for rendering heap w/ pprof
# other dependencies came from cf-networking-mysql and diego-units(-mysql)
# totally unsure what's necessary
RUN rm /etc/apt/sources.list.d/mysql.list
RUN \
  apt-get update && \
  apt-get -y install \
    bison \
    build-essential \
    ca-certificates \
    curl \
    dnsutils \
    g++ \
    git \
    graphviz \
    htop \
    iproute2 \
    iptables \
    iputils-ping \
    jq \
    kmod \
    libffi-dev \
    libgdbm-dev \
    libncurses5-dev \
    libreadline-dev \
    libssl-dev \
    libyaml-dev \
    lsof \
    mercurial \
    netcat \
    nginx \
    procps \
    psmisc \
    python \
    rsyslog \
    strace \
    unzip \
    vim \
    wget \
    zlib1g-dev \
  && apt-get autoremove -yqq \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN \
  cf_cli_version="$(curl -s https://api.github.com/repos/cloudfoundry/cli/releases | jq -r '.[0].name' | sed 's/v//g')" && \
  url="https://packages.cloudfoundry.org/stable?release=linux64-binary&version=${cf_cli_version}&source=github-rel" && \
  curl -L "${url}" | tar -xz -C /tmp/ && \
  install /tmp/cf8 /usr/local/bin/cf8 && ln -sf /usr/local/bin/cf8 /usr/local/bin/cf

RUN \
  url="$(curl -s https://api.github.com/repos/mikefarah/yq/releases | jq -r '.[0].assets[] | select((.name | contains("linux")) and (.name | contains("tar")) and (.name | contains("amd")) ).browser_download_url')" && \
  curl -L "${url}" | tar -xz -C /tmp/ && \
  install /tmp/yq_linux_amd64 /usr/local/bin/yq

ARG GO_VERSION
RUN rm -rf /usr/local/go
RUN wget -qO- "https://dl.google.com/go/go${GO_VERSION}.linux-amd64.tar.gz" | tar -C /usr/local -xzf -
ENV PATH=$PATH:/usr/local/go/bin:/root/go/bin

ARG RUBY_INSTALLER_VERSION
RUN curl -L "https://github.com/postmodern/ruby-install/archive/v${RUBY_INSTALLER_VERSION}.tar.gz" | tar -zx -C /tmp/ && \
  cd "/tmp/ruby-install-${RUBY_INSTALLER_VERSION}" && \
  make install

ARG RUBY_VERSION
RUN ruby-install ruby "${RUBY_VERSION}" -- --disable-install-rdoc
ENV PATH ${PATH}:/root/.gem/ruby/${RUBY_VERSION}/bin:/opt/rubies/ruby-${RUBY_VERSION}/lib/ruby/gems/${RUBY_VERSION}/bin:/opt/rubies/ruby-${RUBY_VERSION}/bin
RUN \
  gem install \
    bundler \
    cf-uaac \
    debugger-ruby_core_source

#    staticcheck
RUN \
  url="$(curl -s https://api.github.com/repos/dominikh/go-tools/releases | jq -r '.[0].assets[] | select((.name | contains("linux")) and (.name | contains("tar")) and (.name | contains("amd")) and (.name | contains("sha256") |not )).browser_download_url')" && \
  curl -L "${url}" | tar -xz -C /tmp/ && \
  install /tmp/staticcheck/staticcheck /usr/local/bin/staticcheck

# Delete apt caches after intalling everything (especially ruby which does its own apt stuff apparently)
RUN rm -rf /var/lib/apt/lists/*

COPY protocols /etc/protocols
RUN ln -sf /usr/local/bin/docker-entrypoint.sh /mysql-entrypoint.sh
