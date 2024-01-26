#!/bin/bash

set -eEu
set -o pipefail

function create_pr() {
    local title="${1:?Provide title}"
    local description="${1:?Provide title}"
    gh pr create --title "${title}" --body "${description}" --label "${LABEL}" --base develop --head "${BRANCH}"
}

function run(){
    pushd repo > /dev/null
    local title=$(git show "origin/$BRANCH" --pretty=format:"%s" --no-patch)
    local description=$(git show "origin/$BRANCH" --pretty=format:"%b" --no-patch)

    set +e
    create_pr "${title}" "${description}"
    PR_EXIT_CODE=$?
    set -e

    if [ "$PR_EXIT_CODE" -eq 1 ]; then
        echo "PR could not be created because one already exists."

        gh pr list --head "${BRANCH}" --jq .[0].title --json title | grep "${TITLE}"
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
