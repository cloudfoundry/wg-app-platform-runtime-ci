function verify_go(){
    local dir="${1:-$PWD}"
    pushd "${dir}" >/dev/null
    go version
    popd > /dev/null
}
function verify_go_version_match_bosh_release(){
    local dir="${1:-$PWD}"
    local container_go_version bosh_release_go_version
    container_go_version="$(go version | cut -d " " -f 3 | sed 's/go//' | cut -d '.' -f1,2 )"
    bosh_release_go_version="$(get_go_version_for_release "${dir}" | cut -d '.' -f1,2)"
    if [[ "$container_go_version" != "$bosh_release_go_version" ]]; then
        echo "Mismatch between container's go version (${container_go_version}.X) and bosh release's go version (${bosh_release_go_version}.X). Please make sure the two match on major and minor"
        exit 1
    fi
}
function verify_gofmt(){
    local dir="${1:-$PWD}"
    pushd "${dir}" >/dev/null

    files=$(gofmt -l . | grep -v vendor || true)
    if [[ -n "$files" ]]; then
        echo "failed gofmt for the following: $files"
        exit 1
    fi

    popd > /dev/null
}
function verify_govet(){
    local dir="${1:-$PWD}"
    pushd "${dir}" >/dev/null
    go vet ./...
    popd > /dev/null
}

function verify_binary() {
    local cmd=${1:?"Provide a command to verify"}
    if ! [ -x "$(command -v "$cmd")" ]; then
        echo "Error: $cmd is not installed." >&2
        exit 1
    fi
}

function expand_flags(){
    debug "expand_flags Starting"

    local list=""
    IFS=$'\n'
    for entry in ${FLAGS}
    do
        list="${list}${entry} "
    done

    debug "running with flags: ${list}"
    debug "expand_flags Ending"
    echo "${list}"
}

function expand_envs(){
    local env_file="${1?path to env file}"
    debug "expand_envs Starting"
    IFS=$'\n'
    for entry in ${ENVS:-}
    do
        local key=$(echo $entry | cut -d '=' -f1)
        local value=$(echo $entry | cut -d '=' -f2)
        echo "Setting env: $key=$value"
        echo "export $key=$value" >> "${env_file}"
    done
    debug "expand_envs Ending"
}

function expand_functions(){
    debug "expand_functions Starting"
    IFS=$'\n'
    for entry in ${FUNCTIONS:-}
    do
        debug "Source: $entry"
        source $entry
    done
    debug "expand_functions Ending"
}

function expand_verifications(){
    debug "expand_verifications Starting"
    for entry in ${VERIFICATIONS}
    do
        echo "Verifying: $entry"
        eval "$entry"
    done
    debug "expand_verifications Ending"
}

function debug(){
    echo "${@}" >> "/tmp/$TASK_NAME.log"
}

function get_go_version_for_package(){
    local spec_lock_value="${1:?Provide a spec lock value}"
    local package_name="${2:?Provide a package name}"

    local golang_release_dir go_version
    golang_release_dir="$(mktemp -d -t XXX-golang-release-dir)"
    git clone --quiet https://github.com/bosh-packages/golang-release "${golang_release_dir}" > /dev/null
    go_version=$("${golang_release_dir}/scripts/get-package-version.sh" "${spec_lock_value}" "${package_name}")
    rm -rf  "${golang_release_dir}"
    echo "$go_version"
}

function get_go_version_for_release(){
    local dir="${1:-$PWD}"
    pushd "${dir}" > /dev/null
    local package_path package_name spec_lock_value
    package_path=$(find ./packages/ -name "golang-*linux" -type d)
    package_name=$(basename "${package_path}")
    spec_lock_value=$(yq .fingerprint "${package_path}/spec.lock")
    popd > /dev/null
    get_go_version_for_package "${spec_lock_value}" "${package_name}"
}

function err_reporter() {
    if [[ -f "/tmp/$TASK_NAME.log" ]]; then
        echo "---Debug Report Starting--"
        cat "/tmp/$TASK_NAME.log"
        echo "---Debug Report Ending--"
    fi
}

function configure_db() {
  db="$1"

  if [ "${db}" = "postgres" ]; then
    launchDB="(/postgres-entrypoint.sh postgres &> /var/log/postgres-boot.log) &"
    testConnection="psql -h localhost -U postgres -c '\conninfo'"
  elif [ "${db}" = "mysql" ]  || [ "${db}" = "mysql-5.6" ] || [ "${db}" = "mysql8" ]; then
    launchDB="(MYSQL_ROOT_PASSWORD=password /mysql-entrypoint.sh mysqld &> /var/log/mysql-boot.log) &"
    testConnection="mysql -h localhost -u root -D mysql -e '\s;' --password='password'"
  else
    echo "DB variable not set. The script does not determine which database to use and would fail some tests with errors related to being unable to connect to the db. Bailing early."
    exit 1
  fi

  echo -n "booting ${db}"
  eval "$launchDB"
  for _ in $(seq 1 60); do
    if eval "${testConnection}" &> /dev/null; then
      echo "connection established to ${db}"
      return 0
    fi
    echo -n "."
    sleep 1
  done
  eval "${testConnection}" || true
  echo "unable to connect to ${db}"
  exit 1
}
export -f configure_db
