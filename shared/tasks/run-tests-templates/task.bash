#!/bin/bash

set -eux

pushd repo > /dev/null
    bundle install
    bundle exec rspec spec
popd > /dev/null
