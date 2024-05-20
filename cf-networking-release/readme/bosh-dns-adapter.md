# bosh-dns-adapter

This job enables `bosh-dns` to resolve requests for internal routes. `bosh-dns` sends DNS requests for internal routes to the `bosh-dns-adapter`. The `bosh-dns-adapter` sends those DNS requests for internal routes to the `service-discovery-controller` to be resolved. Internal domains must be configured on this jobs in addition to being created via CC API.

> [!NOTE]
>
> This repository should be imported as `code.cloudfoundry.org/bosh-dns-adapter`.
