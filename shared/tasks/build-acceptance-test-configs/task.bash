#!/bin/bash

set -eEu
set -o pipefail

THIS_FILE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
export TASK_NAME="$(basename $THIS_FILE_DIR)"
source "$THIS_FILE_DIR/../../../shared/helpers/helpers.bash"
source "$THIS_FILE_DIR/../../../shared/helpers/bosh-helpers.bash"
source "$THIS_FILE_DIR/../../../shared/helpers/cf-helpers.bash"
unset THIS_FILE_DIR

function run(){
    local task_tmp_dir="${1:?provide temp dir for task}"
    shift 1

    local env_file="$(mktemp -p ${task_tmp_dir} -t 'XXXXX-env.bash')"
    expand_envs "${env_file}"
    . "${env_file}"

    bosh_target
    cf_target

    for entry in ${CONFIGS}
    do
        if [[ "$entry" == "cats" ]]; then
            cats "built-acceptance-test-configs/cats.json"
        elif [[ "$entry" == "wats" ]]; then
            wats "built-acceptance-test-configs/wats.json"
        elif [[ "$entry" == "rats" ]]; then
            rats "built-acceptance-test-configs/rats.json"
        elif [[ "$entry" == "drats" ]]; then
            drats "built-acceptance-test-configs/drats.json"
        elif [[ "$entry" == "cfsmoke" ]]; then
            cfsmoke "built-acceptance-test-configs/cfsmoke.json"
        elif [[ "$entry" == "cf-networking-acceptance-tests" ]]; then
            cf_networking_acceptance_tests "built-acceptance-test-configs/cf-networking-acceptance-tests.json"
        elif [[ "$entry" == "service-discovery-acceptance-tests" ]]; then
            cf_networking_acceptance_tests "built-acceptance-test-configs/service-discovery-acceptance-tests.json"
        elif [[ "$entry" == "service-discovery-performance-tests" ]]; then
            service_discovery_performance_tests "built-acceptance-test-configs/service-discovery-performance-tests.json"
        else
            echo "Unable to generate config for $entry"
            exit 1
        fi
    done
}

function cats() {
    local file="${1?Provide config file}"
    echo "Creating ${file}"
    cat << EOF > "${file}" 
{
    "admin_password": "${CF_ADMIN_PASSWORD}",
    "admin_user": "admin",
    "api": "api.${CF_SYSTEM_DOMAIN}",
    "apps_domain": "${CF_SYSTEM_DOMAIN}",
    "artifacts_directory": "logs",
    "backend": "diego",
    "include_apps": true,
    "include_backend_compatibility": false,
    "include_detect": true,
    "include_docker": false,
    "include_http2_routing": false,
    "include_internet_dependent": true,
    "include_routing_isolation_segments": ${WITH_ISOSEG},
    "include_isolation_segments": ${WITH_ISOSEG},
    "include_privileged_container_support": false,
    "include_route_services": true,
    "include_routing": true,
    "include_security_groups": ${WITH_DYNAMIC_ASG},
    "include_services": true,
    "include_ssh": false,
    "include_sso": false,
    "include_tasks": false,
    "include_tcp_isolation_segments": ${WITH_ISOSEG},
    "include_v3": false,
    "include_zipkin": true,
    "isolation_segment_name": "persistent_isolation_segment",
    "isolation_segment_domain": "iso-seg.${CF_SYSTEM_DOMAIN}",
    "skip_ssl_validation": true,
    "stacks": ["cflinuxfs4"],
    "timeout_scale": 2,
    "use_http": true
}
EOF
}

function rats() {
    local file="${1?Provide config file}"
    echo "Creating ${file}"
    cat << EOF > "${file}" 
{
  "addresses": [
    "${CF_TCP_DOMAIN}"
  ],
  "api": "api.${CF_SYSTEM_DOMAIN}",
  "admin_user": "admin",
  "admin_password": "${CF_ADMIN_PASSWORD}",
  "skip_ssl_validation": true,
  "use_http": true,
  "apps_domain": "${CF_SYSTEM_DOMAIN}",
  "include_http_routes": true,
  "default_timeout": 120,
  "cf_push_timeout": 120,
  "tcp_router_group": "default-tcp",
  "oauth": {
    "token_endpoint": "https://uaa.${CF_SYSTEM_DOMAIN}",
    "client_name": "routing_api_client",
    "client_secret": "$(bosh_get_password_from_credhub routing_api_client)",
    "port": 443,
    "skip_ssl_validation": true
  }
}
EOF
}

function drats() {
    local file="${1?Provide config file}"
    local ssh_proxy_host=$(echo $BOSH_ALL_PROXY | sed "s|ssh+socks5://.*@||g" | sed "s|\:.*$||g")
    echo "Creating ${file}"

    jq -n \
      --arg cf_api_url "https://api.${CF_SYSTEM_DOMAIN}" \
      --arg cf_deployment_name "cf" \
      --arg cf_admin_username "admin" \
      --arg cf_admin_password "${CF_ADMIN_PASSWORD}" \
      --arg bosh_environment "$BOSH_ENVIRONMENT" \
      --arg bosh_client "$BOSH_CLIENT" \
      --arg bosh_client_secret "$BOSH_CLIENT_SECRET" \
      --arg bosh_ca_cert "$BOSH_CA_CERT" \
      --arg ssh_proxy_cidr "10.0.0.0/8" \
      --arg ssh_proxy_user "jumpbox" \
      --arg ssh_proxy_host "$ssh_proxy_host" \
      --arg ssh_proxy_private_key "$(cat $JUMPBOX_PRIVATE_KEY)" \
      '{
        "cf_api_url": $cf_api_url,
        "cf_deployment_name": $cf_deployment_name,
        "cf_admin_username": $cf_admin_username,
        "cf_admin_password": $cf_admin_password,
        "bosh_environment": $bosh_environment,
        "bosh_client": $bosh_client,
        "bosh_client_secret": $bosh_client_secret,
        "bosh_ca_cert": $bosh_ca_cert,
        "ssh_proxy_cidr": $ssh_proxy_cidr,
        "ssh_proxy_user": $ssh_proxy_user,
        "ssh_proxy_host": $ssh_proxy_host,
        "ssh_proxy_private_key": $ssh_proxy_private_key,
        "include_cf-routing": true
      }' > $file
}

function cfsmoke() {
    local file="${1?Provide config file}"
    echo "Creating ${file}"
    cat << EOF > "${file}" 
{
  "suite_name": "CF_SMOKE_TESTS",
  "api": "api.${CF_SYSTEM_DOMAIN}",
  "apps_domain": "${CF_SYSTEM_DOMAIN}",
  "user": "admin",
  "password": "${CF_ADMIN_PASSWORD}",
  "org": "",
  "space": "",
  "isolation_segment_space": "",
  "cleanup": true,
  "use_existing_org": false,
  "use_existing_space": false,
  "logging_app": "",
  "runtime_app": "",
  "enable_windows_tests": false,
  "windows_stack": "windows",
  "enable_etcd_cluster_check_tests": false,
  "etcd_ip_address": "",
  "backend": "diego",
  "isolation_segment_name": "persistent_isolation_segment",
  "isolation_segment_domain": "iso-seg.${CF_SYSTEM_DOMAIN}",
  "enable_isolation_segment_tests": ${WITH_ISOSEG},
  "skip_ssl_validation": true
}
EOF
}

function wats() {
    echo "not yet implemented"
    exit 1
}

function cf_networking_acceptance_tests() {
    local file="${1?Provide config file}"
    echo "Creating ${file}"
    cat << EOF > "${file}"
{
    "admin_password": "$CF_ADMIN_PASSWORD",
    "admin_secret": "$(bosh_get_password_from_credhub uaa_admin_client_secret)",
    "admin_user":"admin",
    "api": "api.${CF_SYSTEM_DOMAIN}",
    "apps_domain": "${CF_SYSTEM_DOMAIN}",
    "default_security_groups": [ "dns", "public_networks" ],
    "dynamic_asgs_enabled": "${WITH_DYNAMIC_ASG}",
    "extra_listen_ports": 2,
    "nodes": 1,
    "prefix":"test-",
    "proxy_applications": 1,
    "proxy_instances": 1,
    "run_custom_iptables_compatibility_test": true,
    "run_experimental_outbound_conn_limit_test": true,
    "skip_search_domain_tests": true,
    "skip_space_developer_policy_test": true,
    "skip_ssl_validation":true,
    "test_app_instances": 3,
    "test_applications": 2,
    "include_security_groups": true,
    "use_http":true
}
EOF
}

function service_discovery_performance_tests() {
    local file="${1?Provide config file}"
    echo "Creating ${file}"
    cat << EOF > "${file}"
{
    "nats_url": "$NATS_IP",
    "nats_username": "nats",
    "nats_password": "$NATS_PASSWORD",
    "nats_monitoring_port": $NATS_PORT,
    "num_messages": 100000,
    "num_publishers": 10
}
EOF
}

function cleanup() {
    rm -rf $task_tmp_dir
}

task_tmp_dir="$(mktemp -d -t 'XXXX-task-tmp-dir')"
trap cleanup EXIT
trap 'err_reporter $LINENO' ERR
run $task_tmp_dir "$@"
