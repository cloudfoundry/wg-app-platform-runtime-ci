function verify_go(){
    local dir="${1:-$PWD}"
    pushd "${dir}" >/dev/null
    go version
    popd > /dev/null
}
function verify_go_version_match_bosh_release(){
    local dir="${1:-$PWD}"
    pushd "${dir}" >/dev/null
    if [[ "$(is_repo_bosh_release)" == "no" ]]; then
        echo "Skipping this verification, since it's not a bosh release"
        popd > /dev/null
        return
    fi
    popd > /dev/null
    local container_go_version bosh_release_go_version
    container_go_version="$(go version | cut -d " " -f 3 | sed 's/go//' | cut -d '.' -f1,2 )"
    bosh_release_go_version="$(get_go_version_for_release "${dir}" "golang-*linux" | cut -d '.' -f1,2)"
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
function verify_staticcheck(){
    local dir="${1:-$PWD}"
    pushd "${dir}" >/dev/null
    staticcheck ./...
    popd >/dev/null
}

function verify_gosec(){
    local dir="${1:-$PWD}"
    pushd "${dir}" >/dev/null
    gosec_config_file=$(mktemp)
    trap "rm ${gosec_config_file}" EXIT

# - We don't care about the alerts relating to TLSInsecureSkipVerify, or TLSMinVersion because we control that
#   intentionally, or use the default values from golang (which are secure). gosec freaks out nonetheless.
# - Also ignore alerts related to the usage of md5 + sha1 being insecure because we're only using them for hashes,
#   not encryption. 
# - Also Ignore alerts related to the use of `unsafe` since we need to use it
# - Also ignore alerts related to variables used in URLs, opening files, executing commands
# - also ignore alerts about cryptographically insecure random number generators since we don't do encryption with them
# - also ignore memory aliasing as go 1.22 made it obsolete.
# - and reconfigure all filepermission checks to have a max permission of 0755 instead of 0600/0700.
    cat <<EOF >"${gosec_config_file}"
{
  "global": {
    "exclude": "G304,G204,G103,G404,G402,G401,G101,G501,G107,G505,G601,G305,G303,G106"
  },
 "G302": "0755",
 "G306": "0755",
 "G301": "0755"
}
EOF
    gosec -quiet -conf "${gosec_config_file}" ./...
    popd >/dev/null

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
        local value=$(echo $entry | cut -d '=' -f2-)
        echo "Setting env: $key"
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
    debug "running get_go_version_for_package with args $*"
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
    debug "running get_go_version_for_release with args $*"
    local dir="${1:?Provide release directory path}"
    local package="${2:?Provide a package glob}"

    pushd "${dir}" > /dev/null
    debug "Finding the go version for $package"
    local package_path package_name spec_lock_value
    package_name=""
    spec_lock_value=""
    package_path=$(find ./packages/ -name "$package" -type d | sort -r | head -n1)
    if [ -n "$package_path" ]; then
        package_name=$(basename "${package_path}")
        spec_lock_value=$(yq .fingerprint "${package_path}/spec.lock")
        get_go_version_for_package "${spec_lock_value}" "${package_name}"
    fi
    popd > /dev/null

}

function err_reporter() {
    if [[ -f "/tmp/$TASK_NAME.log" ]]; then
        echo "---Debug Report Starting--" >&2
        cat "/tmp/$TASK_NAME.log"         >&2
        echo "---Debug Report Ending--"   >&2
    fi
}

function is_repo_bosh_release() {
    if [[ -f "./config/final.yml" ]] && [[ -d "./packages" ]] && [[ -d "./jobs" ]]; then
        echo "yes"
    else
        echo "no"
    fi
}

function get_go_version_for_binaries() {
    local dir=${1:?Provide dir for finding binaries}
    local go_version=""
    for file in $(find $dir -type f -name "*.tgz")
    do
        unpack ${file}
    done
    for file in $(find $dir -type f -executable)
    do
        local next_go_version
        next_go_version=$(go version ${file} 2>&1 | grep -v "unrecognized file format" |  cut -d ':' -f2 | sed 's/^[[:space:]]go//g')
        if [[ "${go_version}" == "" ]]; then
            go_version=${next_go_version}
        elif [[ ${next_go_version} != "" ]] && [[ "${go_version}" != "${next_go_version}" ]]; then
            echo "Binaries included are built with different versions of Go. Found ${go_version} and ${next_go_version}"
            exit 1
        fi
    done
    echo ${go_version}
}

function configure_db() {
  db="$1"

  local db_user=${DB_USER:-root}
  local db_password=${DB_PASSWORD:-password}

  if [ "${db}" = "postgres" ]; then
    db_user=${DB_USER:-postgres}
    launchDB="(POSTGRES_USER=$db_user POSTGRES_PASSWORD=$db_password /postgres-entrypoint.sh postgres -c max_connections=300 &> /var/log/postgres-boot.log) &"
    testConnection="PGPASSWORD=$db_password psql -h localhost -U $db_user -c '\conninfo'"
  elif [ "${db}" = "mysql" ]  || [ "${db}" = "mysql-5.7" ] || [ "${db}" = "mysql8" ]; then
    launchDB="(MYSQL_USER='' MYSQL_ROOT_PASSWORD=$db_password /mysql-entrypoint.sh mysqld --max_allowed_packet=256M &> /var/log/mysql-boot.log) &"
    testConnection="mysql -h localhost -u $db_user -D mysql -e '\s;' --password='$db_password'"
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

function retry_command() {
    local cmd="${1:?Provide a command to retry}"
    local max_iteration=5

    for i in $(seq 1 $max_iteration)
    do
        $cmd >& /dev/null
        result=$?
        if [[ $result -eq 0 ]]
        then
            echo "Runing: $cmd with success."
            break
        else
            echo "Runing: $cmd without success."
            sleep 1
        fi
    done
}
export -f retry_command

function env_metadata() {
    if [[ -n "${BBL_STATE_DIR}" ]]; then
        echo "env/${BBL_STATE_DIR}/bbl-state.json"
    else
        echo "env/metadata"
    fi
}

function is_env_cf_deployment() {
    local has_opsman=$(jq 'any(.;.ops_manager)' "$(env_metadata)")
    if [[ "$has_opsman" == "true" ]]; then
        echo  "no"
    else 
        echo "yes"
    fi
}
export -f is_env_cf_deployment
