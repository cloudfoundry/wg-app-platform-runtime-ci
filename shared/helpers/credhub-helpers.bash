function credhub_save_lb_cert() {
    local cert_file
    local credhub_path
    if [[ -z "${BBL_STATE_DIR}" ]]; then
        set +e
        cert="$(openssl s_client -showcerts -connect "any.${CF_SYSTEM_DOMAIN}:443" </dev/null 2>/dev/null)"
        set -e

        cert_file="$(mktemp)"
        credhub_path="/bosh-${CF_ENVIRONMENT_NAME}/cf/lb_cert"

        echo "${cert}" | openssl x509 > "${cert_file}"
    else
        cert_file="env/${BBL_STATE_DIR}/lb_certs/out/${BBL_STATE_DIR}.arp.cloudfoundry.org.crt"
        credhub_path="/bosh-${BBL_STATE_DIR}/cf/lb_cert"
    fi


    credhub set \
        --name "${credhub_path}" \
        --type certificate \
        --certificate "${cert_file}"
}
