#!/bin/bash

set -eu

. ci/helpers/helpers.bash
. ci/helpers/bosh-helpers.bash
. ci/helpers/cf-helpers.bash

cf_target
cf_create_tcp_domain

echo '[{"protocol":"all","destination":"'"${AD_SUBNET}"'"}]' > dc.json
if ! cf_command security-group grep active-directory-domain-controllers; then
  cf_command create-security-group active-directory-domain-controllers dc.json
else
  cf_command update-security-group active-directory-domain-controllers dc.json
fi

cf_command bind-staging-security-group active-directory-domain-controllers
cf_command bind-running-security-group active-directory-domain-controllers

cf_command create-org -o "${APP_ORG}"
cf_command create-space -o "${APP_ORG}" -s "${APP_SPACE}"
cf_command target -o "${APP_ORG}" -s "${APP_SPACE}"
cf_command push "${APP_DOMAIN}" -m 1g -s windows -i 2 -b hwc_buildpack -p repo/src/WindowsAuth --no-route
cf_command map_route "${APP_DOMAIN}" "${APP_DOMAIN}" -n "${APP_HOSTNAME}"
cf_command map_route "${APP_DOMAIN}" "${CF_TCP_DOMAIN}" -p "${APP_TCP_PORT}"
