fly_pipeline() {
  pipelineName="${1}"
  shift

  local yttRenderedConfigFilePath="$(mktemp -d)/pipeline.yml"

  ytt "${@}" > "${yttRenderedConfigFilePath}"

  fly --target "${FLY_TARGET}" set-pipeline \
    --team "${FLY_TEAM}" \
    --pipeline "${pipelineName}" \
    --config "${yttRenderedConfigFilePath}"
  rm "${yttRenderedConfigFilePath}"
}

fly_login() {
  fly --target "${FLY_TARGET}" sync
  fly --target "${FLY_TARGET}" status || fly --target "${FLY_TARGET}" login --open-browser
}
