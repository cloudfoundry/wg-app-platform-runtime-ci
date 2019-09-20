# Diego CI

Scripts and tools to run Diego's CI builds on [Concourse CI](https://concourse-ci.org).

## What's in here
This repo contains only Concourse scripts, build task definitions, and pipeline definitions.

For environment configuration, see the [deployments-diego](https://github.com/cloudfoundry/deployments-diego) repo. Descriptions of the differences between environments can also be found there.

## What do these tests do?
The tests for several sections of the pipeline, along with brief descriptions of what they test can be found in the following places. Some of these are submoduled into diego-release and others are not. 

- [cf-acceptance-tests](https://github.com/cloudfoundry/cf-acceptance-tests) (CATS)
- [diego-upgrade-stability-tests](https://github.com/cloudfoundry/diego-upgrade-stability-tests) (DUSTS) - submoduled into diego-release
- [smoke-tests](https://github.com/cloudfoundry/cf-smoke-tests)
- [inigo](https://github.com/cloudfoundry/inigo) - submoduled into diego-release
- [vizzini](https://github.com/cloudfoundry/vizzini) - submoduled into diego-release
