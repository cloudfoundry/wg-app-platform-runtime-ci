function cf_target(){
    BBL_STATE_DIR=${BBL_STATE_DIR:=""}
    BOSH_DEPLOYMENT="$(bosh_cf_deployment_name)" bosh_manifest > ./env/cf.yml
    CF_SYSTEM_DOMAIN="$(cf_system_domain)"
    CF_ADMIN_PASSWORD=$(cf_password)
    CF_DEPLOYMENT=$(bosh_cf_deployment_name)
    if [[ -n "${BBL_STATE_DIR}" ]]; then
        CF_ENVIRONMENT_NAME=$(jq -r .envID "$(env_metadata)")
    elif [[ "$(is_shepherd_v1_deployment)" == "yes" ]]; then
        CF_ENVIRONMENT_NAME=$(yq .vcenter.hostname "$(env_metadata)")
    else
        CF_ENVIRONMENT_NAME=$(jq -r .name "$(env_metadata)")
    fi
    CF_TCP_DOMAIN="tcp.${CF_SYSTEM_DOMAIN}"
    CF_MANIFEST_VERSION=$(cf_manifest_version)
    CF_MANIFEST_FILE="env/cf.yml"
    export CF_SYSTEM_DOMAIN CF_ADMIN_PASSWORD CF_DEPLOYMENT CF_ENVIRONMENT_NAME CF_TCP_DOMAIN CF_MANIFEST_VERSION CF_MANIFEST_FILE
}

function cf_system_domain(){
    # For cf-deployment bbl envs
    local system_domain
    if [[ "$(is_shepherd_v1_deployment)" == "yes" ]]; then
        system_domain=$(bosh int <(bosh_manifest) --path /instance_groups/name=blobstore?/jobs/name=blobstore/properties/system_domain)
        echo "$system_domain"
        return
    fi

    system_domain=$(jq -r .cf.api_url < "$(env_metadata)" | cut -d "." -f2-)
    # fall back to checking the manifest with multiple instance group name options
    if [[ "${system_domain:=null}" == "null" ]] ; then
        system_domain=$(bosh int <(bosh_manifest) --path /instance_groups/name=singleton-blobstore?/jobs/name=blobstore/properties/system_domain)
    fi
    if [[ "${system_domain:=null}" == "null" ]] ; then
        system_domain=$(bosh int <(bosh_manifest) --path /instance_groups/name=blobstore?/jobs/name=blobstore/properties/system_domain)
    fi
    echo "$system_domain"
}

function cf_login(){
    cf_command api --skip-ssl-validation "https://api.${CF_SYSTEM_DOMAIN}"
    cf_command auth admin "${CF_ADMIN_PASSWORD}"
}

function cf_create_tcp_domain(){
    if [[ "$(is_env_cf_deployment)" == "yes" ]]; then
        cf_login

        local domain_exists
        domain_exists=$(cf curl /v3/domains | jq ".resources[] | select(.name == \"$CF_TCP_DOMAIN\")")

        if [[ "${domain_exists:=empty}" == "empty" ]] ; then
            echo "Create TCP domain"
            cf_command create-shared-domain "$CF_TCP_DOMAIN" --router-group default-tcp
        fi
    else
        echo "Skipping creating cf_domain"
    fi

}

function cf_command() {
    local cmd=("$@")
    debug "Running CF Command with Args: ${cmd[*]}"
    cf "${cmd[@]}"
}

function cf_password() {
    if [[ "$(is_env_cf_deployment)" == "yes" ]]; then
        bosh_get_password_from_credhub cf_admin_password
    else
        bosh_get_password_from_credhub 'uaa/admin_credentials' '.value.password'
    fi
}

function cf_manifest_version() {
    if [[ "$(is_env_cf_deployment)" == "yes" ]]; then
        local version
        version=$(bosh int <(bosh_manifest) --path /manifest_version)
        if [[ "${version:=null}" == "null" ]]; then
            echo "no-version"
        fi
    else
        echo "no-version"
    fi

}
