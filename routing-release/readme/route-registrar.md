# route-registrar

[![Go Report Card](https://goreportcard.com/badge/code.cloudfoundry.org/route-registrar)](https://goreportcard.com/report/code.cloudfoundry.org/route-registrar)
[![Go Reference](https://pkg.go.dev/badge/code.cloudfoundry.org/route-registrar.svg)](https://pkg.go.dev/code.cloudfoundry.org/route-registrar)

A standalone executable written in golang that continuously broadcasts a routes
to the [gorouter](https://github.com/cloudfoundry/gorouter).  This is designed
to be a general purpose solution, packaged as a BOSH job to be colocated with
components that need to broadcast their routes to the gorouter, so that those
components don't need to maintain logic for route registration.

> [!NOTE]
>
> This repository should be imported as `code.cloudfoundry.org/route-registrar`.
