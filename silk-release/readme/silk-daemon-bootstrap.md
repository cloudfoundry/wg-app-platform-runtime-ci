# silk-daemon-bootstrap

Daemon that polls the silk-controller API to acquire and renew the overlay subnet lease for the Diego cell. Polling frequency can be configured and is 5s by default. It also serves an API that the silk-cni calls to retrieve information about the overlay subnet lease.

> [!NOTE]
>
> This repository should be imported as `code.cloudfoundry.org/silk-daemon-bootstrap`.
