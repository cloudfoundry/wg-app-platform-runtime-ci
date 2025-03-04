#!/bin/bash

set -eEu
set -o pipefail

function create_pr() {
    local title="${1:?Provide title}"
    local description="${1:?Provide title}"
    gh pr create --title "${title}" --body "${description}" --label "${LABEL}" --base "${BASE_BRANCH}" --head "${BRANCH}"
}

function configure_github_enterprise() {
    # docs: https://cli.github.com/manual/
    if [[ "${GH_HOST:-empty}" != "empty" ]]; then
        export GH_ENTERPRISE_TOKEN="${GITHUB_TOKEN}"
    fi
}

function run(){
    configure_github_enterprise
    pushd repo > /dev/null

    git fetch --all
    local title=$(git show "origin/$BRANCH" --pretty=format:"%s" --no-patch)
    local description=$(git show "origin/$BRANCH" --pretty=format:"%b" --no-patch)

    set +e
    create_pr "${title}" "${description}"
    PR_EXIT_CODE=$?
    set -e

    if [ "$PR_EXIT_CODE" -eq 1 ]; then
        echo "PR could not be created."

        gh pr list --head "${BRANCH}" --jq .[0].title --json title | grep "${title}"
        if [ "$?" -eq 1 ]; then
            echo "The existing PR is stale. Deleting old PR in favor of the new one."

    #  close old PR
    gh pr close "${BRANCH}"

    #  resubmit new PR
    create_pr "${title}" "${description}"
else
    echo "The existing PR is identical. No need to create a new PR."
        fi
    fi
    popd > /dev/null
}

run "$@"
