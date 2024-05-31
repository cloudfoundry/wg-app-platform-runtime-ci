# routing-api

[![Go Report Card](https://goreportcard.com/badge/code.cloudfoundry.org/routing-api)](https://goreportcard.com/report/code.cloudfoundry.org/routing-api)
[![Go Reference](https://pkg.go.dev/badge/code.cloudfoundry.org/routing-api.svg)](https://pkg.go.dev/code.cloudfoundry.org/routing-api)

The purpose of the Routing API is to present a RESTful interface for registering
and deregistering routes for both internal and external clients. This allows
easier consumption by different clients as well as the ability to register
routes from outside of the CF deployment.

> [!NOTE]
>
> This repository should be imported as `code.cloudfoundry.org/routing-api`.
