#!/bin/bash

cd web-config-buildpack
git checkout ${BRANCH}

./build.sh Test --stack Linux
