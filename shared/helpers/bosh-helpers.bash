function bosh_target(){
    eval "$(bbl print-env --metadata-file env/metadata)"
    export ENVIRONMENT_NAME="$(jq -r .name env/metadata)"
}

function bosh_manifest(){
    bosh -d "$(bosh_cf_deployment_name)" manifest
}

function bosh_cf_deployment_name(){
    bosh ds --column=name --json | jq -r '.Tables[].Rows[] | select (.name |contains("cf")).name'
}

function bosh_extract_manifest_defaults_from_cf(){
    local manifest="${1:?Provide a manifest}"
    echo  "export CF_STEMCELL_OS=$(bosh int $manifest --path /stemcells/alias=default/os)
export CF_AZ=$(bosh int $manifest --path /instance_groups/0/azs/0)
export CF_NETWORK=$(bosh int $manifest --path /instance_groups/0/networks/0/name)
export CF_VM_TYPE=$(bosh int $manifest --path /instance_groups/0/vm_type)"
}

function bosh_extract_vars_from_env_files(){
    local files=${@}
    debug "Creating bosh vars files from the following files: $files"
    local arguments=""
    IFS=$' '
    for file in ${files}
    do
        debug "Adding arugment for file: $file"
        IFS=$'\n'
        for entry in $(cat $file)
        do
            local key=$(echo ${entry} | cut -d "=" -f1 | cut -d " " -f2)
            eval $entry
            arguments="${arguments} --var=${key}=${!key}"
        done
    done
    echo ${arguments}
}

#Copied from https://github.com/cloudfoundry/cf-deployment-concourse-tasks/blob/9d60cd05a75ae674706201fd083ae46617147373/shared-functions#L351-L369
function bosh_get_password_from_credhub() {
    set +x
    local bosh_manifest_password_variable_name=$1

    local credential_path=$(credhub find -j -n ${bosh_manifest_password_variable_name} | jq -r .credentials[].name )
    local credential_paths_len=$(echo ${credential_path} | tr ' ' '\n' | wc -l)

    if [ "${credential_paths_len}" -gt 1 ]; then
        echo "ambiguous ${bosh_manifest_password_variable_name} variable name; expected one got ${credential_paths_len}" >&2
        echo "${credential_path}" | tr ' ' '\n' >&2
        return
    elif [ "${credential_paths_len}" -eq 0 ]; then
        echo "${bosh_manifest_password_variable_name} variable not found" >&2
        return
    fi

    echo $(credhub find -j -n ${bosh_manifest_password_variable_name} | jq -r .credentials[].name | xargs credhub get -j -n | jq -r .value)
    set -x
}

function bosh_configure_private_yml() {
    set +x
    local private_yml="${1?Provide private yml path}"
    if [[ -n "${GCP_BLOBSTORE_SERVICE_ACCOUNT_KEY}" && "${GCP_BLOBSTORE_SERVICE_ACCOUNT_KEY}" != "null"  ]]; then
        debug "Using GCP"
        local formatted_key="$(sed 's/^/      /' <(echo "${GCP_BLOBSTORE_SERVICE_ACCOUNT_KEY}"))"
        cat > "$private_yml" <<EOF
---
blobstore:
  options:
    credentials_source: static
    json_key: |
${formatted_key}
EOF

    elif [[ -n ${AWS_ACCESS_KEY_ID} ]]; then
        debug "Using AWS Access Key"
        cat > "$private_yml" <<EOF
---
blobstore:
  options:
    secret_access_key: "${AWS_SECRET_ACCESS_KEY}"
    access_key_id: "${AWS_ACCESS_KEY_ID}"
EOF
        if [[ -n "${AWS_ASSUME_ROLE_ARN}" ]]; then
            debug "Using AWS Role ARN"
            cat >> "$private_yml" <<EOF
    assume_role_arn: "${AWS_ASSUME_ROLE_ARN}"
EOF
        fi
    fi
}

function bosh_release_name() {
    local release_name="$(yq -r '.final_name|select(.)' < ./config/final.yml)"
    if [[ -z "$release_name" ]] ; then
        release_name="$(yq -r .name < ./config/final.yml)"
    fi

    if [[ -z "$release_name" ]] ; then
        debug "Release name could not be found. Make sure the release's config/final.yml contains either a 'final_name' or 'name' field."
        exit 1
    fi
    echo "$release_name"
}
