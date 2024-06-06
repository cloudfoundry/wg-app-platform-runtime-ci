#!/bin/bash
set -eux

pushd release
    if [[ ! -z "${RELEASE_DIR}" ]]; then
        export GOPATH=$PWD
        export PATH=$PWD/bin:$PATH
    fi

    IFS=':' read -r -a array <<< "$PATHS"

    for path in "${array[@]}"; do
      pushd $path
        go run github.com/securego/gosec/v2/cmd/gosec@latest ./...
      popd
    done

popd
