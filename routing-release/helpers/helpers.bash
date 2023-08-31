function upload_cert_to_credhub() {
    set +e                                                     
    cert="$(openssl s_client -showcerts -connect "any.${CF_SYSTEM_DOMAIN}:443" </dev/null 2>/dev/null)"
    set -e                                                     

    local cert_file="$(mktemp)"

    echo "${cert}" | openssl x509 > "${cert_file}"                                       

    credhub set \
        --name "/bosh-${CF_ENVIRONMENT_NAME}/cf/lb_cert" \
        --type certificate \
        --certificate "${cert_file}"
}
export -f upload_cert_to_credhub
