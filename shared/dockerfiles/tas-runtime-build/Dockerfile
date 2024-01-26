FROM ubuntu:jammy

RUN \
  export DEBIAN_FRONTEND=noninteractive && \
  apt-get update -y && apt-get install --assume-yes --no-install-recommends \
    apparmor \
    bsdextrautils \
    build-essential \
    ca-certificates \
    curl \
    dnsutils \
    dnsmasq \
    dos2unix \
    file \
    flex \
    gettext \
    git \
    gpg \
    graphviz \
    htop \
    iproute2 \
    iptables \
    iputils-ping \
    jq \
    kmod \
    libfontconfig1-dev \
    libfreetype6 \
    libjpeg-dev \
    libpng-dev \
    libpython3-dev \
    libreadline-dev\
    libseccomp-dev \
    libssl-dev \
    libxml2-dev \
    libxslt-dev \
    libyaml-dev \
    lsof \
    mercurial \
    mingw-w64 \
    netcat \
    netcat-openbsd \
    net-tools \
    openssh-client \
    openssl \
    psmisc \
    python3-pip \
    python3-venv \
    rsync \
    rsyslog \
    ssh \
    strace \
    sudo \
    uidmap \
    unzip \
    vim \
    wget \
    xfsprogs \
    zip \
    zlib1g-dev

# APT/DEB/GPG Config for extra APT repos + pkgs
#    Terraform CLI
RUN \
  curl -L "https://apt.releases.hashicorp.com/gpg" | gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg; \
  echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(cat /etc/os-release | grep VERSION_CODENAME | cut -d '=' -f 2) main" | tee /etc/apt/sources.list.d/hashicorp.list; \
  apt-get update && apt-get install --assume-yes --no-install-recommends terraform

#    gCloud CLI / SDK
RUN \
  curl -L "https://packages.cloud.google.com/apt/doc/apt-key.gpg" | gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg; \
  echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list; \
  apt-get update && apt-get install --assume-yes --no-install-recommends google-cloud-cli

#    GitHub CLI
RUN \
  curl -L "https://cli.github.com/packages/githubcli-archive-keyring.gpg" -o /usr/share/keyrings/githubcli-archive-keyring.gpg; \
  chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg; \
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list; \
  apt-get update && apt-get install --assume-yes --no-install-recommends gh


# Downloaded Utilities
#    cf cli
RUN \
  cf_cli_version="$(curl -s https://api.github.com/repos/cloudfoundry/cli/releases | jq -r '.[0].name' | sed 's/v//g')" && \
  url="https://packages.cloudfoundry.org/stable?release=linux64-binary&version=${cf_cli_version}&source=github-rel" && \
  curl -L "${url}" | tar -xz -C /tmp/ && \
  install /tmp/cf8 /usr/local/bin/cf8 && ln -sf /usr/local/bin/cf8 /usr/local/bin/cf

#    bosh cli
RUN \
  url="$(curl -s https://api.github.com/repos/cloudfoundry/bosh-cli/releases | jq -r '.[0].assets[] | select((.name | contains("linux")) and (.name | contains("amd"))).browser_download_url')" && \
  curl -L "${url}" -o /tmp/bosh && \
  install /tmp/bosh /usr/local/bin/bosh

#    bosh bootloader (BBL)
RUN \
  url="$(curl -s https://api.github.com/repos/cloudfoundry/bosh-bootloader/releases | jq -r '.[0].assets[] | select((.name | contains("linux")) and (.name | contains("amd"))).browser_download_url')" && \
  curl -L "${url}" -o /tmp/bbl && \
  install /tmp/bbl /usr/local/bin/bbl

#    credhub cli
RUN \
  url="$(curl -s https://api.github.com/repos/cloudfoundry/credhub-cli/releases | jq -r '.[0].assets[] | select((.name | contains("linux")) and (.name | contains("amd"))).browser_download_url')" && \
  curl -L "${url}" | tar -xz -C /tmp/ && \
  install /tmp/credhub /usr/local/bin/credhub

#    Routing API CLI (rtr)
RUN \
  url="$(curl -s https://api.github.com/repos/cloudfoundry/routing-api-cli/releases | jq -r '.[0].assets[] | select((.name | contains("linux")) and (.name | contains("amd"))).browser_download_url')" && \
  curl -L "${url}" | tar -xz -C /tmp/ && \
  install /tmp/rtr-linux-amd64 /usr/local/bin/rtr

#    aws cli
RUN \
  curl -L "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o /tmp/awscliv2.zip; \
  cd /tmp; \
    unzip awscliv2.zip; \
    ./aws/install

#    YTT
RUN \
  url="$(curl -s https://api.github.com/repos/carvel-dev/ytt/releases | jq -r '.[0].assets[] | select(.name == "ytt-linux-amd64").browser_download_url')" && \
  curl -L "${url}" -o /tmp/ytt && \
  install /tmp/ytt /usr/local/bin/ytt

#    grype
RUN \
  url="$(curl -s https://api.github.com/repos/anchore/grype/releases | jq -r '.[0].assets[] | select((.name | contains("linux")) and (.name | contains("tar")) and (.name | contains("amd"))).browser_download_url')" && \
  curl -L "${url}" | tar -xz -C /tmp/ && \
  install /tmp/grype /usr/local/bin/grype

#    syft
RUN \
  url="$(curl -s https://api.github.com/repos/anchore/syft/releases | jq -r '.[0].assets[] | select((.name | contains("linux")) and (.name | contains("tar")) and (.name | contains("amd"))).browser_download_url')" && \
  curl -L "${url}" | tar -xz -C /tmp/ && \
  install /tmp/syft /usr/local/bin/syft

#    staticcheck
RUN \
  url="$(curl -s https://api.github.com/repos/dominikh/go-tools/releases | jq -r '.[0].assets[] | select((.name | contains("linux")) and (.name | contains("tar")) and (.name | contains("amd")) and (.name | contains("sha256") |not )).browser_download_url')" && \
  curl -L "${url}" | tar -xz -C /tmp/ && \
  install /tmp/staticcheck/staticcheck /usr/local/bin/staticcheck

#    yq
RUN \
  url="$(curl -s https://api.github.com/repos/mikefarah/yq/releases | jq -r '.[0].assets[] | select((.name | contains("linux")) and (.name | contains("tar")) and (.name | contains("amd")) ).browser_download_url')" && \
  curl -L "${url}" | tar -xz -C /tmp/ && \
  install /tmp/yq_linux_amd64 /usr/local/bin/yq

#   cleanup afterwards
RUN \
  rm -rf /tmp/*; \
  chmod 1777 /tmp

# Install Programming Languages
#    golang
ARG GO_VERSION
RUN rm -rf /usr/local/go
RUN wget -qO- "https://dl.google.com/go/go${GO_VERSION}.linux-amd64.tar.gz" | tar -C /usr/local -xzf -
ENV PATH=$PATH:/usr/local/go/bin:/root/go/bin
RUN go install github.com/square/certstrap@latest
RUN go install github.com/onsi/ginkgo/v2/ginkgo@latest
RUN go install github.com/stephendotcarter/unpack@latest
RUN go install github.com/vito/gosub@master
RUN go install github.com/cloudfoundry/uptimer@latest

#    ruby
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

# Delete apt caches after intalling everything (especially ruby which does its own apt stuff apparently)
RUN rm -rf /var/lib/apt/lists/*

RUN groupadd -g 5000 nonroot && useradd -ms /bin/bash -u 5000 -g 5000 nonroot

CMD /bin/bash
