# vxlan-policy-agent

Polls the the [Policy Server Internal API](https://github.com/cloudfoundry/cf-networking-release/tree/develop/jobs) for desired network policies (container networking and dynamic application security groups) and writes IPTables rules on the Diego cell to enforce those policies for network traffic between applications. For container networking policies, the IPtables rules tag traffic from applications with network policies on egress, and separate rules at the destination allow traffic with tags whitelisted by policies to applications on ingress. This component Uses iptables mutex lock.

> [!NOTE]
>
> This repository should be imported as `code.cloudfoundry.org/vxlan-policy-agent`.
