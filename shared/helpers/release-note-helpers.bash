function get_updated_blob_info() {
  START_REF="${1}" # example: "v0.0.7"
  END_REF="${2}" # ex: "v0.0.8"
  BLOB_LOCATION="${3}" # ex: "config/blobs.yml"

  JSON='{"blobs":[]}'

  while read -r b; do
    if [[ $b == "" ]]; then # when there are no blobs
      echo "${JSON}"
      return
    fi
    # examples
    # --> b=libpcap/libpcap-1.10.5.tar.gz
    # --> b=openssl/fips/openssl-3.0.9.tar.gz
    # --> b=openssl/openssl-3.5.0.tar.gz

    display_name="$(echo "${b}" | grep -oP "(.*\/)" | sed 's/.$//' )"
    # examples
    # --> display_name=libpcap
    # --> display_name=openssl/fips
    # --> display_name=openssl

    uniq_name="$(echo "${b}" | grep -oP "(.*\/.*-)")"
    # examples
    # --> uniq_name=libpcap/libpcap-
    # --> uniq_name=openssl/fips/openssl-
    # --> uniq_name=openssl/openssl-

    previus_version="$(echo "${b}" | grep -oP "(\d*\.\d*\.*\d)")"
    # examples
    # --> previus_version=1.10.5
    # --> previus_version=3.0.9
    # --> previus_version=3.4.1

    new_version="$(git show "${END_REF}:${BLOB_LOCATION}" | grep "${uniq_name}" | grep -oP "(\d*\.\d*\.*\d)")"
    # examples
    # --> new_version=1.10.5
    # --> new_version=3.0.9
    # --> new_version=3.5.0

    if [ "$previus_version" != "$new_version" ]; then
      JSON="$(jq --arg name "$display_name" --arg previus_version "$previus_version" --arg new_version "$new_version" '.blobs += [{name: $name, previus_version: $previus_version, new_version: $new_version}]' <<< "$JSON")"
    fi

  done <<< "$(git show "${START_REF}:${BLOB_LOCATION}" | yq keys[])"
  echo "${JSON}"
  # exmaple result
  # JSON='{
  #   "blobs": [
  #     { "name": "openssl", "previus_version": "3.4.1", "new_version": "3.5.0" },
  #   ]
  # }'
}

function get_non_bot_commits() {
  START_REF="${1}"
  END_REF="${2}"
  git log "${START_REF}...${END_REF}" --invert-grep --author="App Platform Runtime Working Group CI Bot" --format="* %s - Author: %an - SHA: %H"
  # ex result: "* Add an acceptance-test that can be run from CI or locally - Author: Amelia Downs - SHA: 6b4c1e888fb4e6c2f60ffd860ca01a8fbdc32018"
}

function get_go_mod_diff() {
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
  
  while read -r p; do
    name="$(echo "${p}" | jq -r .Path )"
    previus_version="$(echo "${p}" | jq -r .Version)"
    new_version=$(echo "${END_GO_MOD_JSON}" | jq -r --arg name "$name" '.Require[] | select(.Path == $name) | .Version')

    if [ "$previus_version" != "$new_version" ]; then
      JSON="$(jq --arg name "$name" --arg previus_version "$previus_version" --arg new_version "$new_version" '.packages += [{name: $name, previus_version: $previus_version, new_version: $new_version}]' <<< "$JSON")"
    fi
  done <<< "$(echo "${START_GO_MOD_JSON}" | jq .Require[] -c)"
  rm "${START_GO_MOD}" "${END_GO_MOD}"

  echo "${JSON}"
  # example result:
  # {"packages":[{"name":"code.cloudfoundry.org/cf-networking-helpers","previus_version":"v0.37.0","new_version":"v0.45.0"}]}
}
