#!/bin/bash

set -eu
set -o pipefail

TASK_YML="${1?path to concourse task YML file}"

values=$(cat "$TASK_YML" | yq . -o json | jq '.params | to_entries[] | select (.value!=null) | .key, .value')
if [[ -n $values ]];then
    echo $values | xargs -n2 sh -c 'echo export $1=\"$2\"' sh
fi
