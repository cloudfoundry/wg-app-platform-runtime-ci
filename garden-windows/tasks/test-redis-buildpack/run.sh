#!/bin/bash

cd redis-buildpack
git checkout ${BRANCH}

./build.sh Test --stack Linux
