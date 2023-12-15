#!/bin/bash

set -eEu
set -o pipefail

VERSION=$(cat ./version/number)
if [ -z "$VERSION" ]; then
  echo "missing version number"
  exit 1
fi

cd assets

find . -maxdepth 1 -name "$PREFIX*" -type f -exec cp {} "../versioned-assets/{}-$VERSION" \;
