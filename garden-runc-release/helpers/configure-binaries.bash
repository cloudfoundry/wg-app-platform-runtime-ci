function configure_gdn() {
  ${GDN_BINARY} \
    server \
    --depot="/tmp/gdn" \
    --bind-ip=${GDN_BIND_IP} \
    --bind-port="${GDN_BIND_PORT}" \
    --debug-bind-ip=0.0.0.0 \
    --debug-bind-port="${GDN_DEBUG_PORT}" \
    --network-pool=10.254.1.0/24 \
    --log-level="error" \
    --image-plugin-extra-arg=--config \
    --image-plugin-extra-arg=${GROOTFS_REGULAR_CONFIG} \
    --privileged-image-plugin-extra-arg=--config \
    --privileged-image-plugin-extra-arg=${GROOTFS_PRIVILEGED_CONFIG} \
    --default-rootfs=${GARDEN_TEST_ROOTFS} &

  for i in {1..5}; do
    curl "${GDN_BIND_IP}:${GDN_BIND_PORT}/ping" && break || sleep 5
  done
}
export -f configure_gdn
