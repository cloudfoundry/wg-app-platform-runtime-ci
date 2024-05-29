## Healthchecker release

This repository is a [BOSH](https://github.com/cloudfoundry/bosh) release for `healthchecker` that is a go executable designed to perform TCP/HTTP based health checks of
processes managed by `monit` in BOSH releases. Since the version of `monit` included in
BOSH does not support specific tcp/http health checks, we designed this utility to perform
health checking and restart processes if they become unreachable.
