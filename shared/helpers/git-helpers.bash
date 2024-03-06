function git_configure_author(){
    git config --global user.name "${GIT_COMMIT_USERNAME:=App Platform Runtime Working Group CI Bot}"
    git config --global user.email "${GIT_COMMIT_EMAIL:=tas-runtime.pdl+tas-runtime-bot@broadcom.com}"
}

function git_get_remote_name() {
    basename "$(git remote get-url origin)" | sed 's/.git//g'
}

function git_configure_safe_directory() {
    #This is work around --buildvcs issues in Go 1.18+
    git config --global --add safe.directory '*'
}

function git_commit_with_submodule_log() {
    git_submodule_log "$@" | git commit --file -
}

function git_fetch_latest_submodules() {
    git submodule sync --recursive
    git submodule foreach --recursive git submodule sync
    git submodule update --remote --recursive
}

function git_submodule_log() {
    echo -n "bump "
    for submodule in $(git diff --cached --submodule | grep '^Submodule' | awk '{print $2}'); do
        echo -n "$(basename $submodule) "
    done

    echo
    echo

    if [ "$#" != "0" ]; then
        for id in "$@"; do
            echo "[finishes #${id}]"
        done

        echo
    fi

    git submodule status | awk '{print $2}' | xargs git diff --cached --submodule
}

function git_error_when_diff() {
    if ! git diff-files --exit-code --ignore-submodules; then
        echo >&2 "There are unstaged changes in the index!"
        exit 1
    fi

    if ! git diff-index --cached --exit-code HEAD --ignore-submodules; then
        echo >&2 "There are uncommitted changes in the index!"
        exit 1
    fi
}

function git_get_latest_tag() {
    git describe --tags --abbrev=0
}
