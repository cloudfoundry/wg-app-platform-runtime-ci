# silk-release

Silk Release is the Cloud Foundry pluggable container networking solution that
is used in conjunction with [CF Networking
Release](https://code.cloudfoundry.org/cf-networking-release). It provides
networking via the Silk CNI plugin and enforces policy that is stored in the
Policy Server.

The components in this release used to be a part of CF Networking Release.
However, it is the default container networking plugin for CF Deployment. To use
it, simply deploy [CF
Deployment](https://github.com/cloudfoundry/cf-deployment).
