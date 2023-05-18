#!/bin/bash

set -eux

for f in *-input
do
  ls $f
  cp -r $f/* ./combined-output/
done
