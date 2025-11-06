
# standardized print function for a json structure.
# json must have 'title' key and 'values' array.
function print_json_for_release_note() {
  local JSON="${1}"
  local title="$(echo "${JSON}" | jq -r .title)"
  local length="$(echo "${JSON}" | jq -r '.values | length' )"

  if [ "$length" != "0" ]; then
    echo "## ${title}"
    while read -r i; do
      echo "${i}"
    done <<< "$(echo "${JSON}" | jq .values[] -cr)"
    echo
  fi
}

function get_blob_info_across_refs_json() {
  START_REF="${1}" # example: "v0.0.7"
  END_REF="${2}" # ex: "v0.0.8"
  BLOB_LOCATION="${3}" # ex: "config/blobs.yml"
  JSON='{"old_blobs":[], "new_blobs": []}'

  # loop through old blobs
  while read -r b; do
    if [[ $b == "" ]]; then # when there are no blobs
      continue
    fi
    JSON="$(jq --arg name "$b" '.old_blobs += [{name: $name}]' <<< "$JSON")"
  done <<< "$(git show "${START_REF}:${BLOB_LOCATION}" | yq keys[])"

  # loop through new blobs
  while read -r b; do
    if [[ $b == "" ]]; then # when there are no blobs
      continue
    fi
    JSON="$(jq --arg name "$b" '.new_blobs += [{name: $name}]' <<< "$JSON")"
  done <<< "$(git show "${END_REF}:${BLOB_LOCATION}" | yq keys[])"

  echo "${JSON}"
}


# $ display_blob_change_info v0.300.0 v0.341.0 config/blobs.yml
# ## Blob Changes
# * Bumped blob 'haproxy' from '2.8.9' to '2.8.15'
# * Bumped blob 'jq' from '1.7.1' to '1.8.0'
function display_blob_change_info() {
  START_REF="${1}" # example: "v0.0.7"
  END_REF="${2}" # ex: "v0.0.8"
  BLOB_LOCATION="${3}" # ex: "config/blobs.yml"

  blob_changes_json=$(get_blob_info_across_refs_json "${START_REF}" "${END_REF}" "${BLOB_LOCATION}")
  index=0
  while read -r b; do
    if [[ $b == "" ]]; then # when there are no blobs
      continue
    fi
    if [[ $index == 0 ]]; then
      echo "## Blob Updates"
      count="not-1"
    fi
    new_name="$(echo "${b}" | jq -r .name)"
    old_name="$(echo "${blob_changes_json}" | jq -r .old_blobs["${index}"].name)"

    if [ "$old_name" != "$new_name" ]; then
      echo "* Bumped blob '${old_name}' to '${new_name}'"
    fi
    index=$((index+1))
  done <<< "$(echo "${blob_changes_json}" | jq -cr .new_blobs[])"
}

# $ get_non_bot_commits v0.340.0 v0.341.0
# ## Changes
# * Update routing-api's bbr metadata to be overridable with a bosh property - Author: Geoff Franks - SHA: 0c093995d1e6c6f9174772020d9d7e80d5ef020d
# * cleanup logging format property - Author: kart2bc - SHA: 8649855084b57c3a24260473f4baa1473aff0125
function get_non_bot_commits() {
  START_REF="${1}"
  END_REF="${2}"
  OPTIONAL_SUBMODULE_NAME="${3:-}"
  local json="$(get_non_bot_commits_json $START_REF $END_REF $OPTIONAL_SUBMODULE_NAME)"
  print_json_for_release_note "${json}"
}


function get_non_bot_commits_json() {
  START_REF="${1}"
  END_REF="${2}"
  OPTIONAL_SUBMODULE_NAME="${3:-}"
  if [[ $OPTIONAL_SUBMODULE_NAME != "" ]]; then
    JSON='{"values":[], "title": "Changes for '${OPTIONAL_SUBMODULE_NAME}'"}'
  else
    JSON='{"values":[], "title": "Changes"}'
  fi

  commits="$(git log "${START_REF}...${END_REF}" --format="* %s - Author: %an - SHA: %H")"
  if [[ $commits != "" ]]; then
      while read -r c; do
        if [[ "$c" == *"Upgrade golang"* ]]; then
          JSON="$(jq --arg commit "$c" '.values += [$commit]' <<< "$JSON")"
        elif [[ "$c" != *"App Platform Runtime Working Group CI Bot"* ]]; then
          JSON="$(jq --arg commit "$c" '.values += [$commit]' <<< "$JSON")"
        fi
      done <<< "$(echo "${commits}")"
  fi
  echo "${JSON}" | jq -c .
}

function get_go_mod_diff_json() {
  START_REF="${1}"
  END_REF="${2}"
  GO_MOD_LOCATION="${3}"

  # make temp files for the go.mods
  START_GO_MOD=$(mktemp /tmp/start-go-mod.XXXXXX)
  END_GO_MOD=$(mktemp /tmp/end-go-mod.XXXXXX)

  # get the go.mods at provided refs
  git show "${START_REF}:${GO_MOD_LOCATION}" > "${START_GO_MOD}"
  git show "${END_REF}:${GO_MOD_LOCATION}" > "${END_GO_MOD}"

  # turn the go.mod's into json
  START_GO_MOD_JSON="$(go mod edit -json "${START_GO_MOD}")"
  END_GO_MOD_JSON="$(go mod edit -json "${END_GO_MOD}")"
  JSON='{"packages":[]}'
  
  # loop through all of the packages at start ref
  # get their version at start and at end ref and store in JSON
  while read -r p; do
    name="$(echo "${p}" | jq -r .Path )"
    previous_version="$(echo "${p}" | jq -r .Version)"
    new_version=$(echo "${END_GO_MOD_JSON}" | jq -r --arg name "$name" '.Require[] | select(.Path == $name) | .Version')
    JSON="$(jq --arg name "$name" --arg previous_version "$previous_version" --arg new_version "$new_version" '.packages += [{name: $name, previous_version: $previous_version, new_version: $new_version}]' <<< "$JSON")"
  done <<< "$(echo "${START_GO_MOD_JSON}" | jq .Require[] -c)"

  # loop through all of the packages at end ref
  # if they are not already in the JSON, add them
  # this accounts for packages who are newly added
  while read -r p; do
    name="$(echo "${p}" | jq -r .Path )"
    new_version="$(echo "${p}" | jq -r .Version)"
    is_package_already_listed=$(echo "${JSON}" | jq -r --arg name "$name" '.packages[] | select(.name == $name) | any')

    if [ "$is_package_already_listed" != "true" ]; then
      JSON="$(jq --arg name "$name" --arg previous_version "" --arg new_version "$new_version" '.packages += [{name: $name, previous_version: $previous_version, new_version: $new_version}]' <<< "$JSON")"
    fi
  done <<< "$(echo "${END_GO_MOD_JSON}" | jq .Require[] -c)"

  # loop through all of the packge data gathered so far
  # delete the item if the previous version and new version are the same
  while read -r p; do
    name="$(echo "${p}" | jq -r .name )"
    previous_version="$(echo "${p}" | jq -r .previous_version)"
    new_version="$(echo "${p}" | jq -r .new_version)"

    if [ "$previous_version" == "$new_version" ]; then
      JSON="$(jq --arg name "$name" 'del(.packages[] | select(.name == $name))' <<< "$JSON")"
    fi
  done <<< "$(echo "${JSON}" | jq .packages[] -c)"
  rm "${START_GO_MOD}" "${END_GO_MOD}"

  echo "${JSON}"
  # example result:
  # {"packages":[{"name":"code.cloudfoundry.org/cf-networking-helpers","previous_version":"v0.37.0","new_version":"v0.45.0"}]}
}

function display_go_mod_diff() {
  START_REF="${1}" # example: "v0.0.7"
  END_REF="${2}" # ex: "v0.0.8"
  GO_MOD_LOCATION="${3}"
  OPTIONAL_SUBMODULE_NAME="${4:-}"
  count=1

  go_mod_changes_json=$(get_go_mod_diff_json "${START_REF}" "${END_REF}" "${GO_MOD_LOCATION}")
  while read -r b; do
    if [[ $b == "" ]]; then # when there are no changes
      continue
    fi
    if [[ $count == 1 ]]; then
      count="not-1"
      if [[ $OPTIONAL_SUBMODULE_NAME != "" ]]; then
        echo "## Go Package Updates for '${OPTIONAL_SUBMODULE_NAME}'"
      else
        echo "## Go Package Updates"
      fi
    fi
    name="$(echo "${b}" | jq -r .name)"
    new_version="$(echo "${b}" | jq -r .new_version)"
    previous_version="$(echo "${b}" | jq -r .previous_version)"

    if [ "$previous_version" == "" ]; then
      echo "* Added go.mod package '${name}' version '${new_version}'"
    elif [ "$new_version" == "" ]; then
      echo "* Removed go.mod package '${name}' version '${previous_version}'"
    else
      echo "* Bumped go.mod package '${name}' from '${previous_version}' to '${new_version}'"
    fi
  done <<< "$(echo "${go_mod_changes_json}" | jq -cr '.packages | sort_by(.name) | .[]')"
}

function get_bosh_job_spec_diff(){
  START_REF="${1}" # ex: "v0.0.7"
  END_REF="${2}" # ex: "v0.0.8"

  job_spec_diff="$(git --no-pager diff "${START_REF}...${END_REF}" jobs/*/spec)"
  if [[ -n "${job_spec_diff}" ]]; then
    echo "## Bosh Job Spec changes"
    echo "${job_spec_diff}"
  fi
}

function display_full_changelog() {
  START_REF="${1}" # ex: "v0.0.7"
  END_REF="${2}" # ex: "v0.0.8"
  REPO_NAME="${3}"
  GITHUB_ORG_URL="${4}"
  echo "## **Full Changelog**: ${GITHUB_ORG_URL}/${REPO_NAME}/compare/$START_REF}...${END_REF}"
}

function display_built_with_go_linux() {
  REPO_LOCATION="${1}"
  END_REF="${2}" # ex: "v0.0.8"
  echo "## ✨  Built with go $(get_linux_go_version_for_release_from_ref "${REPO_LOCATION}" "${END_REF}")"
}

# ex. input="v0.343.0...v0.344.0"
# ex. output="v0.343.0"
function get_start_ref_from_range {
  echo "${1%%...*}"
}

# ex. input="v0.343.0...v0.344.0"
# ex. output="v0.344.0"
function get_end_ref_from_range {
  echo "${1#*...}"
}

