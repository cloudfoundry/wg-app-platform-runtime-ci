function credhub_save_lb_cert() {
    if [[ -z "${BBL_STATE_DIR}"]]; then
        set +e
        cert="$(openssl s_client -showcerts -connect "any.${CF_SYSTEM_DOMAIN}:443" </dev/null 2>/dev/null)"
        set -e

        local cert_file="$(mktemp)"

        echo "${cert}" | openssl x509 > "${cert_file}"
    else
        cert_file="env/${BBL_STATE_DIR}/lb_certs/${BBL_STATE_DIR}.arp.cloudfoundry.org.crt"
    fi


    credhub set \
        --name "/bosh-${CF_ENVIRONMENT_NAME}/cf/lb_cert" \
        --type certificate \
        --certificate "${cert_file}"
}
