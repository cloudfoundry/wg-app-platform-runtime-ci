# fly-cmds

This directory contains a collection of helpful scripts to run individual CI tasks on concourse to
decrease development/testing time when working on CI. They use `fly execute` and can be given
arbitrary local copies of repos and inputs to avoid causing permanent change to the release pipeline
resources.

Inputs are largely things that can be adjusted to other releases/paths as tests need it. We started with this
set of inputs as these were the initial pipelines we developed against.
