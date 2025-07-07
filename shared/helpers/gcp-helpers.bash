projects=(
    "cf-diego-pivotal"
    "app-runtime-platform-wg"
)

function login() {
    for p in "${projects[@]}";
    do
        set +e
        test_response=$(gcloud compute disks list --project "${p}" 2>&1)
        set -e
        if [[ "$test_response" =~ "ERROR" ]]; then
            gcloud auth login --project  "${p}"
        fi
    done
}

function get_unattached_disks_per_project_json() {
    project="${1}"
    gcloud compute disks list --filter="users:null" --project "${project}" --format json
}

function list_unattached_disks_locally() {
    for p in "${projects[@]}";
    do
        disk_info_json="$(get_unattached_disks_per_project_json "${p}")"
        disk_count=$(echo "${disk_info_json}" | jq -r '. | length')
        echo "* project '${project}' has '${disk_count}' unattached disks"
        if [[ "${disk_count}" != 0 ]]; then
            while read -r disk; do
                echo "------------------------"
                disk_name=$(echo "${disk}" | jq -r .name)
                last_attach=$(echo "${disk}" | jq -r .lastAttachTimestamp)
                last_detach=$(echo "${disk}" | jq -r .lastDetachTimestamp)
                zone=$(echo "${disk}" | jq -r .zone | cut  -d "/" -f9)
                echo "Name: ${disk_name}"
                echo "LastAttach: ${last_attach}"
                echo "LastDetach: ${last_detach}"
                echo "To remove: gcloud compute disks delete ${disk_name} --project ${project} --zone ${zone}"
                echo "------------------------"
                echo ""
            done <<< "$(echo "${disk_info_json}" | jq -cr '.[]')"
        fi
    done
}

function list_running_vms_locally() {
    for p in "${projects[@]}";
    do
        vm_info_json=$(get_running_vms_per_project_json "${p}")
        vm_count=$(echo "${vm_info_json}" | jq -r '.[] | length')
        echo "* project '${p}' has '${vm_count}' running VMs"
        echo "${vm_info_json}" | jq -r .vms[] | sort | uniq -c
        echo ""
    done
}

function get_running_info_from_gcp_json() {
    project="${1}"
    gcloud compute instances list --filter "status:RUNNING" --project "${project}" --format json
}

function get_running_vms_per_project_json() {
    project="${1}"
    JSON='{"vms":[]}'
    vm_info_json="$(get_running_info_from_gcp_json "${project}")"
    while read -r vm; do
        local name
        name=$(get_gcp_vm_identifier "${vm}")
        JSON="$(jq --arg name "$name" '.vms += [$name]' <<< "$JSON")"
    done <<< "$(echo "${vm_info_json}" | jq -cr '.[]')"
    echo "${JSON}"
}


function get_gcp_vm_identifier() {
    vm=${1}
    ## for cf bbl vms: bosh-bbl-garden-env
    name=$(echo "${vm}" | jq -r '.tags.items | select(. != null) | .[] | select(test(".-env$")) | select(test("bosh-bbl."))' | sed -nE 's/bbl-(.*)-env/\1/p')
    if [[ "${name}" == "" ]]; then
        ## for bosh bbl vms: bbl-nfs-volume-env-bosh-director
        name=$(echo "${vm}" | jq -r '.tags.items | select(. != null) | .[] | select(test(".-env-bosh-director$")) | select(test("bbl."))' | sed -nE 's/bbl-(.*)-env-bosh-director/\1/p') 
    fi
    if [[ "${name}" == "" ]]; then
        ## for bosh bbl vms: bbl-nfs-volume-env-jumpbox
        name=$(echo "${vm}" | jq -r '.tags.items | select(. != null) | .[] | select(test(".-env-jumpbox$")) | select(test("bbl."))' | sed -nE 's/bbl-(.*)-env-jumpbox/\1/p')
    fi
    if [[ "${name}" == "" ]]; then
        ## for bosh bbl vms: bosh-bbl-env-vanern-2020-12-04t22-44z-concourse
        name=$(echo "${vm}" | jq -r '.tags.items | select(. != null) | .[] | select(test(".-concourse$")) | select(test("bosh-bbl-env."))' | sed -nE 's/bosh-bbl-env-(.*)-concourse/\1/p')
    fi
    if [[ "${name}" == "" ]]; then
        ## for bosh bbl vms: bbl-env-vanern-2020-12-04t22-44z-bosh-director
        name=$(echo "${vm}" | jq -r '.tags.items | select(. != null) | .[] | select(test(".-bosh-director$")) | select(test("bbl-env."))' | sed -nE 's/bbl-env-(.*)-bosh-director/\1/p')
    fi
    if [[ "${name}" == "" ]]; then
        ## for bosh bbl vms: bbl-env-vanern-2020-12-04t22-44z-jumpbox
        name=$(echo "${vm}" | jq -r '.tags.items | select(. != null) | .[] | select(test(".-jumpbox$")) | select(test("bbl-env."))' | sed -nE 's/bbl-env-(.*)-jumpbox/\1/p')
    fi
    if [[ "${name}" == "" ]]; then
        ## for bosh bbl vms: diego-worker-cgroupsv2-worker
        name=$(echo "${vm}" | jq -r '.tags.items | select(. != null) | .[] | select(test("diego-worker-cgroupsv2-worker"))')
    fi
    if [[ "${name}" == "" ]]; then
        ## for other vms
        name=$(echo "${vm}" | jq -r '.name')
    fi
    echo "${name}"
}

function get_gcp_vm_name() {
    vm=${1}
    name=$(echo "${vm}" | jq -r '.name')
    echo "${name}"
}

function is_okay_to_be_long_running() {
    vm_id="${1}"
    okay_long_running_ids=(
        "concourse"
        "vanern-2020-12-04t22-44z"
        "diego-worker-cgroupsv2-worker"
    )
    local found
    found=false

    for ok_id in "${okay_long_running_ids[@]}"; do
      if [[ "$ok_id" == "$vm_id" ]]; then
        found=true
        break
      fi
    done

    echo "${found}"
}

function list_long_running_vms_locally() {
    for p in "${projects[@]}";
    do
        vm_info_json="$(get_long_running_vms_per_project_json "${p}")"
        vm_count=$(echo "${vm_info_json}" | jq -r '.[] | length')
        echo "* project '${p}' has '${vm_count}' suspicious long running VMs"

        if [[ "${vm_count}" != 0 ]]; then
            while read -r vm; do
                id=$(echo "${vm}" | jq -r .id)
                name=$(echo "${vm}" | jq -r .name)
                hours_running=$(echo "${vm}" | jq -r .hours_running)
                echo "     ${id} - ${name} - ${hours_running} hours"
            done <<< "$(echo "${vm_info_json}"| jq -cr '.vms[]')"
            echo ""
        fi
    done
}

function get_long_running_vms_per_project_json() {
    project="${1}"
    vm_info_json=$(get_running_info_from_gcp_json "${project}")
    JSON='{"vms":[]}'

    while read -r vm; do
        local name
        id=$(get_gcp_vm_identifier "${vm}")
        name=$(get_gcp_vm_name "${vm}")
        creation_time=$(echo "${vm}" | jq -r .lastStartTimestamp)
        hours_since="$(( ($(date +%s) - $(date -d "${creation_time}" +%s)) / (60*60) ))"
        if [[ "${hours_since}" -ge 12 ]]; then
            ok=$(is_okay_to_be_long_running "${id}")
            if [[ "${ok}" == false ]]; then
                JSON="$(jq --arg name $name --arg id $id --arg hours $hours_since '.vms += [{"name": $name, "id": $id, "hours_running": $hours}]' <<< "$JSON")"
            fi
        fi
    done <<< "$(get_running_info_from_gcp_json "${project}" | jq -cr '.[]')"
    echo "$JSON"
}

function list_gcp_status_locally() {
    login
    list_unattached_disks_locally
    list_running_vms_locally
    list_long_running_vms_locally
}
