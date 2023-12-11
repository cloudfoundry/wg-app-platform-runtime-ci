#!/bin/bash

set -eEu
set -o pipefail

function run(){
    IFS=$'\n'
    for linter in ${LINTERS}; do
        local shared_linter="./ci/shared/linters/${linter}"
        if [[ -f "$shared_linter" ]]; then
            echo "Running $shared_linter with-exit-on-error=true"
            "$shared_linter" "$PWD/docker-image" true
        else
            echo "Unable to find linter ${linter}."
            exit 1
        fi
    done
}

run "$@"

