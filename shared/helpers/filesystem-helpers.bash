# copied from https://github.com/concourse/concourse/blob/master/jobs/baggageclaim/templates/baggageclaim_ctl.erb#L54
# break out of bosh-lite device limitations
function filesystem_permit_device_control() {
  if grep -q devices /proc/self/cgroup; then
    local devices_mount_info
    devices_mount_info="$( cat /proc/self/cgroup | grep devices )"

    if [ -z "$devices_mount_info" ]; then
      # cgroups not set up; must not be in a container
      echo "No devices mount info found in cgroup. Is this running in a container?" >&2
      return
    fi

    local devices_subsytems
    devices_subsytems="$( echo "$devices_mount_info" | cut -d: -f2 )"

    local devices_subdir
    devices_subdir="$( echo "$devices_mount_info" | cut -d: -f3 )"

    if [ "$devices_subdir" = "/" ]; then
      # we're in the root devices cgroup; must not be in a container
      return
    fi

    cgroup_dir=/devices-cgroup

    if [ ! -e "${cgroup_dir}" ]; then
      # mount our container's devices subsystem somewhere
      mkdir "$cgroup_dir"
    fi

    if ! mountpoint -q "$cgroup_dir"; then
      mount -t cgroup -o "$devices_subsytems" none "$cgroup_dir"
    fi

    mkdir -p "${cgroup_dir}${devices_subdir}"

    # permit our cgroup to do everything with all devices
    echo a > "${cgroup_dir}${devices_subdir}/devices.allow" || true

    umount "$cgroup_dir"
  else
    echo "skipping devices setup for cgroups v2"
    if [ ! -f /sys/fs/cgroup/cgroup.controllers ]; then
      mount cgroup2 /sys/fs/cgroup --type cgroup2
    fi
  fi
}

function filesystem_create_loop_devices() {
  local re_enableerrexit
  re_enableerrexit=0
  if set -p -o errexit | grep "set -o errexit" || true >/dev/null; then
    re_enableerrexit=1
    set +e
  fi
  LOOP_CONTROL=/dev/loop-control
  if [ ! -c $LOOP_CONTROL ]; then
    mknod $LOOP_CONTROL c 10 237
    chown root:disk $LOOP_CONTROL
    chmod 660 $LOOP_CONTROL
  fi

  amt=${1:-256}
  for i in $( seq 0 "$amt" ); do
    mknod -m 0660 "/dev/loop${i}" b 7 "$i"
  done &> /dev/null 2>&1
  if [[ "$re_enableerrexit" == "1" ]]; then
  set -e
  fi
}

# workaround until Concourse's garden sets this up for us
function filesystem_mount_sysfs() {
  if ! grep -qs '/sys' /proc/mounts; then
    mount -t sysfs sysfs /sys
  fi
}

function filesystem_mount_storage() {
  mkdir -p /mnt/ext4
  truncate -s 256M /ext4_volume
  mkfs.ext4 /ext4_volume &> /dev/null
  mount /ext4_volume /mnt/ext4 &> /dev/null
  chmod 777 /mnt/ext4

  for i in {1..10}
  do
    # Make XFS Volume
    truncate -s 3G /xfs_volume_${i}
    mkfs.xfs -b size=4096 /xfs_volume_${i} &> /dev/null

    # Mount XFS
    mkdir /mnt/xfs-${i}
    if ! mount -t xfs -o pquota,noatime /xfs_volume_${i} /mnt/xfs-${i}; then
      free -h
      echo Mounting xfs failed, bailing out early!
      echo NOTE: this might be because of low system memory, please check out output from free above
      exit 13
    fi
    chmod 777 -R /mnt/xfs-${i}
  done
}

function filesystem_unmount_storage() {
  umount -l /mnt/ext4

  for i in {1..10}
  do
    umount -l /mnt/xfs-${i}
    rmdir /mnt/xfs-${i}
    rm /xfs_volume_${i}
  done

  rmdir /mnt/ext4
  rm /ext4_volume
}

function filesystem_sudo_mount_storage() {
  local MOUNT_STORAGE_FUNC=$(declare -f filesystem_mount_storage)
  sudo bash -c "$MOUNT_STORAGE_FUNC; filesystem_mount_storage"
}

function filesystem_sudo_unmount_storage() {
  local UNMOUNT_STORAGE_FUNC=$(declare -f filesystem_unmount_storage)
  sudo bash -c "$UNMOUNT_STORAGE_FUNC; filesystem_unmount_storage"
}
