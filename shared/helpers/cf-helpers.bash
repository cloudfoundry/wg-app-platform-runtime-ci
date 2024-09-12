function cf_target(){
    bosh_manifest > ./env/cf.yml
    export CF_SYSTEM_DOMAIN="$(cf_system_domain)"
    export CF_ADMIN_PASSWORD=$(cf_password)
    export CF_DEPLOYMENT=$(bosh_cf_deployment_name)
    export CF_ENVIRONMENT_NAME=$(jq -r .name env/metadata)
    export CF_TCP_DOMAIN="tcp.${CF_SYSTEM_DOMAIN}"
    export CF_MANIFEST_VERSION=$(cf_manifest_version)
    export CF_MANIFEST_FILE="env/cf.yml"
}

function cf_system_domain(){
    # For cf-deployment
    local system_domain=$(bosh int <(bosh_manifest) --path /instance_groups/name=singleton-blobstore?/jobs/name=blobstore/properties/system_domain)
    if [[ "${system_domain:=null}" == "null" ]] ; then 
        system_domain=$(bosh int <(bosh_manifest) --path /instance_groups/name=blobstore?/jobs/name=blobstore/properties/system_domain)
    fi
    echo $system_domain
}

function cf_login(){
    cf_command api --skip-ssl-validation "https://api.${CF_SYSTEM_DOMAIN}"
    cf_command auth admin "${CF_ADMIN_PASSWORD}"
}

function cf_create_tcp_domain(){
    if [[ "$(is_env_cf_deployment)" == "yes" ]]; then
        cf_login

        local domain_exists=$(cf curl /v2/domains | jq ".resources[] | select(.entity.name == \"$CF_TCP_DOMAIN\")")

        if [[ "${domain_exists:=empty}" == "empty" ]] ; then
            echo "Create TCP domain"
            cf_command create-shared-domain "$CF_TCP_DOMAIN" --router-group default-tcp
        fi
    else 
        echo "Skipping creating cf_domain"
    fi

}

function cf_command() {
    local cmd=$@
    debug "Running CF Command with Args: $cmd"
    eval "cf $cmd"
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
        bosh int <(bosh_manifest) --path /manifest_version 
    else
        echo "no-version"
    fi

}
