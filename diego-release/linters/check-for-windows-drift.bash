#!/bin/bash

set -eu
set -o pipefail

function run() {
    local repo_path=${1:?Provide a path to the repository}
    local exit_on_error=${2:-"false"}

    pushd "${repo_path}" > /dev/null

    local error=""

    rep_json=$(cat jobs/rep/templates/rep.json.erb |  grep -v declarative_healthcheck_path |  grep -v declarative_healthcheck_user | grep -v container_proxy_path)
    rep_windows_json=$(cat jobs/rep_windows/templates/rep.json.erb | grep -v declarative_healthcheck_path |  grep -v declarative_healthcheck_user | grep -v container_proxy_path)

    if ! diff -u <(echo -e "$rep_windows_json") <(echo -e "$rep_json"); then
        error=$(printf "%s\nrep json have drifted" ${error})
    fi

    rep_properties=$(cat jobs/rep/spec | sed -n '/properties/,$P' | grep -E '^  [a-z].*$' | tr -d '[:blank:]' | grep -v bpm | grep -v set_kernel_parameters | grep -v diego.executor.volman.driver_paths | grep -v diego.rep.max_containers | grep -v diego.rep.enable_cf_pcap | sort)
    rep_windows_properties=$(cat jobs/rep_windows/spec | sed -n '/properties/,$P' | grep -E '^  [a-z].*$' | grep -v syslog | grep -v diego.rep.open_bindmounts_acl | grep -v declarative_healthcheck_path | tr -d '[:blank:]' | sort)

    if ! diff -u <(echo -e "$rep_properties") <(echo -e "$rep_windows_properties"); then
        error=$(printf "%s\nrep specs have drifted" ${error})
    fi

    route_emitter_json=$(cat jobs/route_emitter/templates/route_emitter.json.erb | grep -v register_direct_instance_routes )
    route_emitter_windows_json=$(cat jobs/route_emitter_windows/templates/route_emitter.json.erb )
    if ! diff -u <(echo -e "$route_emitter_json") <(echo -e "$route_emitter_windows_json"); then
        error=$(printf "%s\nroute emitter json have drifted" ${error})
    fi

    route_emitter_properties=$(cat jobs/route_emitter/spec | sed -n '/properties/,$P' | grep -E '^  [a-z].*$' | grep -v register_direct_instance_routes | tr -d '[:blank:]' | grep -v bpm | sort)
    route_emitter_windows_properties=$(cat jobs/route_emitter_windows/spec | sed -n '/properties/,$P' | grep -E '^  [a-z].*$' | grep -v syslog | tr -d '[:blank:]' | sort)

    if ! diff -u <(echo -e "$route_emitter_properties") <(echo -e "$route_emitter_windows_properties"); then
        error=$(printf "%s\nroute emitter specs have drifted" ${error})
    fi
    popd > /dev/null

    if [[ "$exit_on_error" == "true" ]] && [[ "${error}" != "" ]]; then
        echo "${error}"
        exit 1
    fi
}

run "$@"
