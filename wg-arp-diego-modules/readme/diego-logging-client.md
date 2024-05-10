# diego-logging-client
[![Go Report Card](https://goreportcard.com/badge/code.cloudfoundry.org/diego-logging-client)](https://goreportcard.com/report/code.cloudfoundry.org/diego-logging-client)
[![Go Reference](https://pkg.go.dev/badge/code.cloudfoundry.org/diego-logging-client.svg)](https://pkg.go.dev/code.cloudfoundry.org/diego-logging-client)

The Diego Logging Client provides a generic client for
[Diego](https://github.com/cloudfoundry/diego-release) to
Cloud Foundry's logging subsystem,
[Loggregator](https://github.com/cloudfoundry/loggregator).

The client wraps the [go-loggregator](https://github.com/cloudfoundry/go-loggregator) library
to provide a tailored interface for Diego components.

> [!NOTE]
>
> This repository should be imported as `code.cloudfoundry.org/diego-logging-client`.
