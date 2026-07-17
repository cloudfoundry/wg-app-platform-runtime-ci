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

    pushd $DIR > /dev/null
    bosh_target
    cf_target
    popd

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
        elif [[ "$entry" == "uptimer-bosh-restart" ]]; then
            uptimer_bosh_restart "built-acceptance-test-configs/uptimer-bosh-restart.json"
        elif [[ "$entry" == "volume-services-acceptance-tests" ]]; then
            volume_services_acceptance_tests "built-acceptance-test-configs/volume-services-acceptance-tests.json"
        else
            echo "Unable to generate config for $entry"
            exit 1
        fi
    done
}

function cats() {
    local file="${1?Provide config file}"

    local with_apps="${WITH_APPS:-true}"
    local with_container_networking="${WITH_CONTAINER_NETWORKING:-true}"
    local with_detect="${WITH_DETECT:-true}"
    local with_deployments="${WITH_DEPLOYMENTS:-true}"
    local with_docker="${WITH_DOCKER:-true}"
    local with_internet_dependent="${WITH_INTERNET_DEPENDENT:-true}"
    local with_route_services="${WITH_ROUTE_SERVICES:-true}"
    local with_routing="${WITH_ROUTING:-true}"
    local with_security_groups="${WITH_SECURITY_GROUPS:-true}"
    local with_services="${WITH_SERVICES:-true}"
    local with_service_discovery="${WITH_SERVICE_DISCOVERY:-true}"
    local with_service_instance_sharing="${WITH_SERVICE_INSTANCE_SHARING:-true}"
    local with_ssh="${WITH_SSH:-true}"
    local with_sso="${WITH_SSO:-true}"
    local with_tasks="${WITH_TASKS:-true}"
    local with_tcp_routing="${WITH_TCP_ROUTING:-true}"
    local with_user_provided_services="${WITH_USER_PROVIDED_SERVICES:-true}"
    local with_v3="${WITH_V3:-true}"
    local with_zipkin="${WITH_ZIPKIN:-true}"
    local with_routing_isoseg="${WITH_ROUTING_ISOSEG:-${WITH_ISOSEG}}"
    local with_tcp_isoseg="${WITH_TCP_ISOSEG:-${WITH_ISOSEG}}"
    local credhub_mode="${CREDHUB_MODE:-assisted}"
    local credhub_client=""
    local credhub_secret=""
    if [[ "${credhub_mode}" == "assisted" ]]; then
        credhub_client="credhub_admin_client"
        credhub_secret="$(bosh_get_password_from_credhub credhub_admin_client_secret)"
    fi
    local isoseg_domain
    if [[ -n "${ISOSEG_DOMAIN:-}" ]]; then
        isoseg_domain="${ISOSEG_DOMAIN}"
    elif [[ -n "${ISOSEG_DOMAIN_SUFFIX:-}" ]]; then
        isoseg_domain="${ISOSEG_DOMAIN_SUFFIX}.${CF_SYSTEM_DOMAIN#sys.}"
    else
        isoseg_domain="iso-seg.${CF_SYSTEM_DOMAIN}"
    fi

    echo "Creating ${file}"
    cat << EOF > "${file}"
{
    "admin_password": "${CF_ADMIN_PASSWORD}",
    "admin_user": "admin",
    "api": "api.${CF_SYSTEM_DOMAIN}",
    "apps_domain": "${CF_APPS_DOMAIN}",
    "artifacts_directory": "logs",
    "credhub_mode": "${credhub_mode}",
    "credhub_client": "${credhub_client}",
    "credhub_secret": "${credhub_secret}",
    "include_apps": ${with_apps},
    "include_container_networking": ${with_container_networking},
    "include_detect": ${with_detect},
    "include_deployments": ${with_deployments},
    "include_docker": ${with_docker},
    "include_http2_routing": ${WITH_HTTP2},
    "include_internet_dependent": ${with_internet_dependent},
    "include_routing_isolation_segments": ${with_routing_isoseg},
    "include_isolation_segments": ${WITH_ISOSEG},
    "dynamic_asgs_enabled": ${WITH_DYNAMIC_ASG},
    "include_route_services": ${with_route_services},
    "include_routing": ${with_routing},
    "include_security_groups": ${with_security_groups},
    "include_services": ${with_services},
    "include_service_discovery": ${with_service_discovery},
    "include_service_instance_sharing": ${with_service_instance_sharing},
    "include_ssh": ${with_ssh},
    "include_sso": ${with_sso},
    "include_tasks": ${with_tasks},
    "include_tcp_isolation_segments": ${with_tcp_isoseg},
    "include_tcp_routing": ${with_tcp_routing},
    "include_user_provided_services": ${with_user_provided_services},
    "include_v3": ${with_v3},
    "include_volume_services": ${WITH_VOLUME_SERVICES},
    "include_zipkin": ${with_zipkin},
    "isolation_segment_name": "${ISOSEG_NAME}",
    "isolation_segment_domain": "${isoseg_domain}",
    "isolation_segment_tcp_domain": "${CF_TCP_DOMAIN}",
    "skip_dns_validation": ${SKIP_DNS_VALIDATION:-false},
    "skip_ssl_validation": true,
    "stacks": ["cflinuxfs4"],
    "tcp_domain": "${CF_TCP_DOMAIN}",
    "timeout_scale": 2,
    "use_http": true,
    "volume_service_name": "${VOLUME_SERVICE_SERVICE_NAME:-}",
    "volume_service_plan_name": "${VOLUME_SERVICE_PLAN_NAME:-}",
    "volume_service_create_config": "${VOLUME_SERVICE_CREATE_CONFIG:-}",
    "volume_service_bind_config": "${VOLUME_SERVICE_BIND_CONFIG:-}",
    "volume_service_broker_name": "${VOLUME_SERVICE_BROKER_NAME:-}"
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
  "tcp_apps_domain": "${CF_TCP_DOMAIN}",
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
  "skip_ssl_validation": true,
  "timeout_scale": 2
}
EOF
}

function wats() {
    local file="${1?Provide config file}"
    echo "Creating ${file}"
    cat << EOF > "${file}"
{
  "admin_password": "${CF_ADMIN_PASSWORD}",
  "admin_user":"admin",
  "api": "api.${CF_SYSTEM_DOMAIN}",
  "apps_domain": "${CF_SYSTEM_DOMAIN}",
  "credhub_client": "credhub_admin_client",
  "credhub_mode": "assisted",
  "credhub_secret": "$(credhub_admin_client_secret)",
  "include_apps": false,
  "include_container_networking": false,
  "include_detect": false,
  "include_docker": false,
  "include_http2_routing": false,
  "include_internet_dependent": true,
  "include_internetless": false,
  "include_isolation_segments": false,
  "include_private_docker_registry": false,
  "include_route_services": false,
  "include_routing": false,
  "include_routing_isolation_segments": false,
  "include_security_groups": true,
  "dynamic_asgs_enabled": ${WITH_DYNAMIC_ASG},
  "include_service_discovery": false,
  "include_service_instance_sharing": false,
  "include_services": false,
  "include_ssh": false,
  "include_sso": false,
  "include_tasks": false,
  "include_tcp_routing": false,
  "include_user_provided_services": false,
  "include_v3": false,
  "include_windows": true,
  "include_zipkin": false,
  "comma_delim_asgs_enabled": ${WITH_COMMA_DELIMITED_ASG_DESTINATIONS},
  "skip_ssl_validation": true,
  "timeout_scale": 1,
  "default_timeout": 240,
  "unallocated_ip_for_security_group": "10.0.244.255",
  "use_http": false,
  "use_windows_context_path": true,
  "use_windows_test_task": true,
  "windows_stack": "${CF_WINDOWS_STACK:-windows}"
}
EOF
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
    "dynamic_asgs_enabled": ${WITH_DYNAMIC_ASG},
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

function volume_services_acceptance_tests() {
    local file="${1?Provide config file}"
    echo "Creating ${file}"
    cat << EOF > "${file}"
{
  "admin_password": "$CF_ADMIN_PASSWORD",
  "admin_user": "admin",
  "api": "api.${CF_SYSTEM_DOMAIN}",
  "apps_domain": "${CF_SYSTEM_DOMAIN}",
  "default_timeout": 30,
  "skip_ssl_validation": true,
  "isolation_segment_name": "persistent_isolation_segment",
  "isolation_segment_domain": "iso-seg.${CF_SYSTEM_DOMAIN}",
  "isolation_segment_tcp_domain": "tcp.${CF_SYSTEM_DOMAIN}",
  "service_name": "${VOLUME_SERVICE_SERVICE_NAME:-}",
  "broker_name": "${VOLUME_SERVICE_BROKER_NAME:-}",
  "plan_name": "${VOLUME_SERVICE_PLAN_NAME:-}",
  "include_multi_cell": true,
  "include_isolation_segment": ${WITH_ISOSEG},
  "username": "${VOLUME_SERVICE_USERNAME:-}",
  "password": "${VOLUME_SERVICE_PASSWORD:-}"
}
EOF
}

function uptimer_bosh_restart() {
    local file="${1?Provide config file}"
    echo "Creating ${file}"
    jq -n \
        --arg deployment_name $(bosh_cf_deployment_name) \
        --arg admin_password ${CF_ADMIN_PASSWORD} \
        --arg api "https://api.${CF_SYSTEM_DOMAIN}" \
        --arg app_domain ${CF_SYSTEM_DOMAIN} \
        --arg tcp_domain ${TCP_DOMAIN:-" "} \
        --arg restart_args ${BOSH_RESTART_ARGS} \
        '{
           "while": [{
             "command":"bosh",
             "command_args":(["--tty", "-n", "-d", $deployment_name, "restart"] + ($restart_args | split(" ")))
           }],
           "cf": {
             "api": $api,
             "app_domain": $app_domain,
             "admin_user": "admin",
             "admin_password": $admin_password,
             "tcp_domain": $tcp_domain,
             "available_port": -1,
             "use_single_app_instance": true
           },
           "allowed_failures": {
             "app_pushability": 0,
             "http_availability": 0,
             "recent_logs": 0,
             "streaming_logs": 0,
             "app_syslog_availability": 0
           },
           "optional_tests": {
             "run_app_syslog_availability": false
           }
         }' > $file
}

function cleanup() {
    rm -rf $task_tmp_dir
}

task_tmp_dir="$(mktemp -d -t 'XXXX-task-tmp-dir')"
trap cleanup EXIT
trap 'err_reporter $LINENO' ERR
run $task_tmp_dir "$@"
