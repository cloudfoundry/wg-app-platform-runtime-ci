function bosh_target(){
    BBL_STATE_DIR=${BBL_STATE_DIR:=""}
    if [[ "$(is_shepherd_v1_deployment)" == "yes" ]]; then
        env_name="shepherd_v1"
        https_proxy=$(yq '"http://\(.http_proxy_username):\(.http_proxy_password)@\(.http_proxy)"' "$(env_metadata)")
        # log the change to the https_proxy environment variable, but hide the password credential
        echo >&2 "export https_proxy=$(yq '"http://\(.http_proxy_username):########@\(.http_proxy)"' "$(env_metadata)")"
        export https_proxy
        OM_SKIP_SSL_VALIDATION=1
        OM_TARGET=$(yq '.["ops manager"]["url"]' "$(env_metadata)")
        OM_USERNAME=$(yq '.["ops manager"]["username"]' "$(env_metadata)")
        OM_PASSWORD=$(yq '.["ops manager"]["password"]' "$(env_metadata)")
        export OM_SKIP_SSL_VALIDATION OM_TARGET OM_USERNAME OM_PASSWORD
        eval "$(om bosh-env)"

        jumpbox_user=$(yq '.http_proxy_username' "$(env_metadata)")
        jumpbox_host=$(yq '.http_proxy|sub(":80$","")' "$(env_metadata)")
        jumpbox_private_key=$(mktemp -t "${env_name}_XXXXXXXXXX.key")
        trap 'rm -f "$jumpbox_private_key"' EXIT
        yq '.["ops manager"]["private key"]' "$(env_metadata)" >"${jumpbox_private_key}"
    elif [[ "$(is_env_cf_deployment)" == "yes" ]]; then
        if [[ -n "${BBL_STATE_DIR}" ]]; then
            export BBL_STATE_DIRECTORY="env/${BBL_STATE_DIR}"
            eval "$(bbl print-env)"
            ENVIRONMENT_NAME="$(jq -r .envID "$(env_metadata)")"
        elif [[ "${BOSH_CREDS:=empty}" != "empty" ]]; then
            eval "${BOSH_CREDS}"
            ENVIRONMENT_NAME="UNDEFINED"
        else
            eval "$(bbl print-env --metadata-file "$(env_metadata)")"
            ENVIRONMENT_NAME="$(jq -r .name "$(env_metadata)")"
        fi
        export ENVIRONMENT_NAME
    elif [[ "${BBL_STATE_DIR:-empty}" != "empty" ]]; then
        eval "$(bbl print-env --metadata-file "$(env_metadata)")"
    else
        OM_SKIP_SSL_VALIDATION=true
        OM_USERNAME="$(jq -r .ops_manager.username "$(env_metadata)")"
        OM_PASSWORD="$(jq -r .ops_manager.password "$(env_metadata)")"
        OM_TARGET="$(jq -r .ops_manager.url "$(env_metadata)")"
        OM_PRIVATE_KEY="$(jq -r .ops_manager_private_key "$(env_metadata)")"
        OM_PUBLIC_IP="$(jq -r .ops_manager_public_ip "$(env_metadata)")"
        ENVIRONMENT_NAME="$(jq -r .name "$(env_metadata)")"
        export OM_USERNAME OM_PASSWORD OM_TARGET OM_PRIVATE_KEY OM_PUBLIC_IP ENVIRONMENT_NAME OM_SKIP_SSL_VALIDATION
        echo "${OM_PRIVATE_KEY}" > "/tmp/${ENVIRONMENT_NAME}.key"
        chmod 600 "/tmp/${ENVIRONMENT_NAME}.key"
        BOSH_ALL_PROXY="ssh+socks5://ubuntu@${OM_PUBLIC_IP}:22?private-key=/tmp/${ENVIRONMENT_NAME}.key"
        CREDHUB_PROXY="ssh+socks5://ubuntu@${OM_PUBLIC_IP}:22?private-key=/tmp/${ENVIRONMENT_NAME}.key"
        GCP_SERVICE_ACCOUNT_KEY_JSON="$(om curl -s -p /api/v0/staged/director/manifest | jq -r .manifest.cloud_provider.properties.google.json_key -r)"
        export BOSH_ALL_PROXY CREDHUB_PROXY GCP_SERVICE_ACCOUNT_KEY_JSON
        eval "$(om bosh-env)"
    fi
}

function bosh_manifest(){
    local manifest
    manifest=$(bosh -d "$(bosh_cf_deployment_name)" manifest)
    if [[ "${manifest:=null}" == "null" ]]; then
        manifest="{}"
    fi
    echo "${manifest}"
}

function bosh_cloud_config(){
    local name=${1:-default}
    bosh cloud-config --name "${name}"
}

function bosh_is_cf_deployed() {
    local name
    name=$(bosh ds --column=name --json | jq -r '.Tables[].Rows[] | select (.name |contains("cf")).name')
    if [[ "${name:=null}" == "null" ]]; then
        echo no
    fi
    echo yes
}

function bosh_cf_deployment_name(){
    local name
    name=$(bosh ds --column=name --json | jq -r '.Tables[].Rows[] | select (.name |contains("cf")).name')
    # we may not have an active deployment
    if [[ "${name:=null}" == "null" ]]; then
        name="cf"
    fi
    echo $name
}

function bosh_extract_manifest_defaults_from_cf(){
    local manifest="${1:?Provide a manifest}"
    local cloud_config="${2:?Provide a cloud-config}"
    if [[ "$(is_env_cf_deployment)" == "yes" ]]; then
        echo  "export CF_STEMCELL_OS=$(bosh int "${manifest}" --path /stemcells/alias=default/os)
export CF_AZ=$(bosh int "${manifest}" --path /instance_groups/0/azs/0)
export CF_NETWORK=$(bosh int "${manifest}" --path /instance_groups/0/networks/0/name)
export CF_VM_TYPE=$(bosh int "${manifest}" --path /instance_groups/0/vm_type)"

    elif [[ "$(is_env_shepherd_v2)" == "yes"  ]]; then
        echo  "export CF_STEMCELL_OS=$(bosh int "${manifest}" --path /stemcells/0/os)
export CF_AZ=$(bosh int "${manifest}" --path /instance_groups/0/azs/0)
export CF_NETWORK=$(bosh int "${manifest}" --path /instance_groups/0/networks/0/name)
export CF_VM_TYPE=$(bosh int "${manifest}" --path /instance_groups/0/vm_type)"

    elif [[ "$(is_shepherd_v1_deployment)" == "yes" ]]; then
        echo  "export CF_STEMCELL_OS=$(bosh int "${manifest}" --path /stemcells/0/os)
export CF_AZ=$(bosh int "${manifest}" --path /instance_groups/0/azs/0)
export CF_NETWORK=$(bosh int "${cloud_config}" --path /networks/0/name)
export CF_NETWORK_CIDR=$(bosh int "${cloud_config}" --path /networks/0/subnets/0/range)
export CF_VM_TYPE=$(bosh int "${manifest}" --path /instance_groups/0/vm_type)"
    fi
}

function bosh_extract_vars_from_env_files(){
    local files=("${@}")
    debug "Creating bosh vars files from the following files: ${files[*]}"
    local arguments=""
    IFS=$' '
    for file in "${files[@]}"
    do
        debug "Adding arugment for file: $file"
        while IFS= read -r entry
        do
            local key
            key="$(echo "${entry}" | cut -d "=" -f1 | cut -d " " -f2)"
            eval "$entry"
            arguments="${arguments} --var=${key}=${!key}"
        done < "${file}"
    done
    echo "${arguments}"
}

#Copied from https://github.com/cloudfoundry/cf-deployment-concourse-tasks/blob/9d60cd05a75ae674706201fd083ae46617147373/shared-functions#L351-L369
function bosh_get_password_from_credhub() {
    local bosh_manifest_password_variable_name=$1
    local field="${2:-.value}"

    local credential_path
    credential_path=$(credhub find -j -n "${bosh_manifest_password_variable_name}" | jq -r .credentials[].name )
    local credential_paths_len
    credential_paths_len=$(echo "${credential_path}" | tr ' ' '\n' | wc -l)

    if [ "${credential_paths_len}" -gt 1 ]; then
        echo "ambiguous ${bosh_manifest_password_variable_name} variable name; expected one got ${credential_paths_len}" >&2
        echo "${credential_path}" | tr ' ' '\n' >&2
        return
    elif [ "${credential_paths_len}" -eq 0 ]; then
        echo "${bosh_manifest_password_variable_name} variable not found" >&2
        return
    fi

    credhub find -j -n "${bosh_manifest_password_variable_name}" | jq -r .credentials[].name | xargs credhub get -j -n | jq -r "$field"
}

function bosh_configure_private_yml() {
    set +x
    local private_yml="${1?Provide private yml path}"
    if [[ "${GCP_BLOBSTORE_SERVICE_ACCOUNT_KEY:-null}" != "null"  ]]; then
        debug "Using GCP"
        local formatted_key
        formatted_key="$(sed 's/^/      /' <(echo "${GCP_BLOBSTORE_SERVICE_ACCOUNT_KEY}"))"
        cat > "$private_yml" <<EOF
---
blobstore:
  options:
    credentials_source: static
    json_key: |
${formatted_key}
EOF

    elif [[ ${AWS_ACCESS_KEY_ID:-null} != "null" ]]; then
        debug "Using AWS Access Key"
        cat > "$private_yml" <<EOF
---
blobstore:
  options:
    secret_access_key: "${AWS_SECRET_ACCESS_KEY}"
    access_key_id: "${AWS_ACCESS_KEY_ID}"
EOF
        if [[ "${AWS_ASSUME_ROLE_ARN:-null}" != "null" ]]; then
            debug "Using AWS Role ARN"
            cat >> "$private_yml" <<EOF
    assume_role_arn: "${AWS_ASSUME_ROLE_ARN}"
EOF
        fi
    fi
}

function bosh_release_name() {
    local release_name
    release_name="$(yq -r '.final_name|select(.)' < ./config/final.yml)"
    if [[ -z "$release_name" ]] ; then
        release_name="$(yq -r .name < ./config/final.yml)"
    fi

    if [[ -z "$release_name" ]] ; then
        debug "Release name could not be found. Make sure the release's config/final.yml contains either a 'final_name' or 'name' field."
        exit 1
    fi
    echo "$release_name"
}

function wait_for_bosh_lock() {
    while [[ $(bosh tasks -d concourse --json | jq '.Tables[].Rows| length') != 0 ]]; do
        echo "Waiting for bosh task lock to clear:"
        bosh tasks
        sleep 60
    done
}

function credhub_admin_client_secret() {
    local value=$(bosh_get_password_from_credhub "credhub_admin")
    local regex="^[a-zA-Z0-9]+$"

    if [[ "$value" =~ $regex ]]; then
        echo $value
    else
        echo $value | jq -r .password
    fi

}
