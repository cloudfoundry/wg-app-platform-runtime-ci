function cf_target(){
    export CF_SYSTEM_DOMAIN="$(cf_system_domain)"
    export CF_ADMIN_PASSWORD=$(bosh_get_password_from_credhub cf_admin_password)
    export CF_ENVIRONMENT_NAME=$(jq -r .name env/metadata)
    export CF_TCP_DOMAIN="tcp.${CF_SYSTEM_DOMAIN}"
    export CF_MANIFEST_VERSION=$(bosh int <(bosh_manifest) --path /manifest_version)

    cf_login
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
    local domain_exists=$(cf curl /v2/domains | jq ".resources[] | select(.entity.name == \"$CF_TCP_DOMAIN\")")

    if [[ "${domain_exists:=empty}" == "empty" ]] ; then
      echo "Create TCP domain"
      cf_command create-shared-domain "$CF_TCP_DOMAIN" --router-group default-tcp
    fi
}

function cf_command() {
    local cmd=$@
    debug "Running CF Command with Args: $cmd"
    eval "cf $cmd"
}
