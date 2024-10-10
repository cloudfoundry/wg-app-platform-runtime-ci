fly_pipeline() {
  pipelineName="${1}"
  shift

  local yttRenderedConfigFilePath="$(mktemp -d)/pipeline.yml"

  ytt "${@}" > "${yttRenderedConfigFilePath}"

  fly --target "${FLY_TEAM}" set-pipeline \
    --team "${FLY_TEAM}" \
    --pipeline "${pipelineName}" \
    --config "${yttRenderedConfigFilePath}"
  rm "${yttRenderedConfigFilePath}"
}

fly_login() {
  fly --target "${FLY_TEAM}" status || fly --target "${FLY_TEAM}" login --open-browser
}
