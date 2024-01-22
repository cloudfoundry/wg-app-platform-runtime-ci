#!/bin/bash

# Based on https://github.com/concourse/docker-image-resource/blob/master/assets/common.sh
# Based https://raw.githubusercontent.com/taylorsilva/dcind/main/docker-lib.sh

LOG_FILE=${LOG_FILE:-/tmp/docker.log}
SKIP_PRIVILEGED=${SKIP_PRIVILEGED:-false}
STARTUP_TIMEOUT=${STARTUP_TIMEOUT:-20}
DOCKER_DATA_ROOT=${DOCKER_DATA_ROOT:-/scratch/docker}

function download_docker() {
  local version="$1"
  local dest="$2"
  local dir="$(mktemp -d --suffix docker)"
  wget --quiet "https://download.docker.com/linux/static/stable/x86_64/docker-${version}.tgz" -O "$dir/docker.tgz"
  tar -xzf "$dir/docker.tgz" -C "$dir"
  mkdir -p "$dest"
  mv $dir/docker/* "$dest"
  rm -rf $dir
  export PATH="$PATH:$dest"
}

sanitize_cgroups() {
  mkdir -p /sys/fs/cgroup
  mountpoint -q /sys/fs/cgroup || \
    mount -t tmpfs -o uid=0,gid=0,mode=0755 cgroup /sys/fs/cgroup

  mount -o remount,rw /sys/fs/cgroup

  unset IFS
  sed -e 1d /proc/cgroups | while  read sys hierarchy num enabled; do
    if [ "$enabled" != "1" ]; then
      # subsystem disabled; skip
      continue
    fi

    grouping="$(cat /proc/self/cgroup | cut -d: -f2 | grep "\\<$sys\\>")" || true
    if [ -z "$grouping" ]; then
      # subsystem not mounted anywhere; mount it on its own
      grouping="$sys"
    fi

    mountpoint="/sys/fs/cgroup/$grouping"

    mkdir -p "$mountpoint"

    # clear out existing mount to make sure new one is read-write
    if mountpoint -q "$mountpoint"; then
      umount "$mountpoint"
    fi

    mount -n -t cgroup -o "$grouping" cgroup "$mountpoint"

    if [ "$grouping" != "$sys" ]; then
      if [ -L "/sys/fs/cgroup/$sys" ]; then
        rm "/sys/fs/cgroup/$sys"
      fi

      ln -s "$mountpoint" "/sys/fs/cgroup/$sys"
    fi
  done

  if ! test -e /sys/fs/cgroup/systemd ; then
    mkdir /sys/fs/cgroup/systemd
    mount -t cgroup -o none,name=systemd none /sys/fs/cgroup/systemd
  fi
}

start_docker() {
  echo "Starting Docker..."

  if [ -f /tmp/docker.pid ]; then
    echo "Docker is already running"
    return
  fi

  mkdir -p /var/log
  mkdir -p /var/run

  if [ "$SKIP_PRIVILEGED" = "false" ]; then
    sanitize_cgroups

    # check for /proc/sys being mounted readonly, as systemd does
    if grep '/proc/sys\s\+\w\+\s\+ro,' /proc/mounts >/dev/null; then
      mount -o remount,rw /proc/sys
    fi
  fi

  local mtu=$(cat /sys/class/net/$(ip route get 8.8.8.8|awk '{ print $5 }')/mtu)
  local server_args="--mtu ${mtu}"
  local registry="${1:-""}"
  local mirror="${2:-""}"

  if [[ -n "${registry}" ]]; then
    server_args="${server_args} --insecure-registry ${registry}"
  fi 

  if [ -n "${mirror}" ]; then
    server_args="${server_args} --registry-mirror ${mirror}"
  fi

  export server_args LOG_FILE DOCKER_DATA_ROOT

  trap "rm /tmp/docker.pid" ERR
  try_start() {
    dockerd --data-root $DOCKER_DATA_ROOT ${server_args} >$LOG_FILE 2>&1 &
    echo $! > /tmp/docker.pid

    sleep 1

    echo waiting for docker to come up...
    until docker info >/dev/null 2>&1; do
      sleep 1
      if ! kill -0 "$(cat /tmp/docker.pid)" 2>/dev/null; then
        return 1
      fi
    done
  }

  if [ "$(command -v declare)" ]; then
    declare -fx try_start

    if ! timeout ${STARTUP_TIMEOUT} bash -ce 'while true; do try_start && break; done'; then
      echo Docker failed to start within ${STARTUP_TIMEOUT} seconds.
      return 1
    fi
  else
    try_start
  fi
}

stop_docker() {
  echo "Stopping Docker..."

  if [ ! -f /tmp/docker.pid ]; then
    return 0
  fi

  local pid=$(cat /tmp/docker.pid)
  if [ -z "$pid" ]; then
    return 0
  fi

  kill -TERM $pid
  rm /tmp/docker.pid
}
