#!/usr/bin/env bash

set -ex

source cf-deployment-concourse-tasks/shared-functions

write_uptimer_deploy_config() {
  local deployment_name
  deployment_name=${1}

  local manifest
  manifest=${2}

  # Give bogus values for TCP_DOMAIN and AVAILABLE_PORT
  # so that we don't have to do jq magic.
  local tcp_domain
  tcp_domain=${TCP_DOMAIN:-" "}
  local available_port
  available_port=${AVAILABLE_PORT:-"-1"}

  set +x
  local cf_admin_password

  cf_admin_password=$(get_password_from_credhub cf_admin_password)

  echo '{}' | jq --arg cf_api api.${SYSTEM_DOMAIN} \
    --arg admin_password ${cf_admin_password} \
    --arg app_domain ${SYSTEM_DOMAIN} \
    --arg manifest ${manifest} \
    --arg deployment_name ${deployment_name} \
    --arg run_app_syslog_availability ${MEASURE_SYSLOG_AVAILABILITY} \
    --arg args ${BOSH_RESTART_ARGS} \
    --arg tcp_domain "${tcp_domain}" \
    --arg available_port ${available_port} \
    --arg app_pushability ${APP_PUSHABILITY_THRESHOLD} \
    --arg http_availability ${HTTP_AVAILABILITY_THRESHOLD} \
    --arg recent_logs ${RECENT_LOGS_THRESHOLD} \
    --arg streaming_logs ${STREAMING_LOGS_THRESHOLD} \
    --arg use_single_app_instance ${USE_SINGLE_APP_INSTANCE} \
    --arg app_syslog_availability ${APP_SYSLOG_AVAILABILITY_THRESHOLD} \
    '{
      "while": [{
        "command":"bosh",
        "command_args":(["--tty", "-n", "-d", $deployment_name, "restart"] + ($args | split(" ")))
      }],
      "cf": {
        "api": $cf_api,
        "app_domain": $app_domain,
        "admin_user": "admin",
        "admin_password": $admin_password,
        "tcp_domain": $tcp_domain,
        "available_port": $available_port | tonumber,
        "use_single_app_instance": $use_single_app_instance | ascii_downcase | contains("true")
      },
      "allowed_failures": {
        "app_pushability": $app_pushability | tonumber,
        "http_availability": $http_availability | tonumber,
        "recent_logs": $recent_logs | tonumber,
        "streaming_logs": $streaming_logs | tonumber,
        "app_syslog_availability": $app_syslog_availability | tonumber
      },
      "optional_tests": {
        "run_app_syslog_availability": $run_app_syslog_availability | ascii_downcase | contains("true")
      }
    }'
  set -x
}

function bosh_restart() {
  local deployment_name
  deployment_name=$(bosh interpolate "${INTERPOLATED_MANIFEST}" --path /name)

  if ${DEPLOY_WITH_UPTIME_MEASUREMENTS}; then
    uptimer_bosh_deploy
  else
    bosh \
      -n \
      -d "${deployment_name}" \
      restart \
      ${BOSH_RESTART_ARGS}
  fi
}


function main() {
  check_input_params
  setup_bosh_env_vars
  bosh_interpolate

  # shellcheck disable=SC2086
  bosh_restart
}

main "${PWD}"
