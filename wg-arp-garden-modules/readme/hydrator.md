# hydrator
[![Go Report Card](https://goreportcard.com/badge/code.cloudfoundry.org/hydrator)](https://goreportcard.com/report/code.cloudfoundry.org/hydrator)
[![Go Reference](https://pkg.go.dev/badge/code.cloudfoundry.org/hydrator.svg)](https://pkg.go.dev/code.cloudfoundry.org/hydrator)

The `hydrator` downloads Docker images and lays them out on disk in [OCI image format](https://github.com/opencontainers/image-spec). It can also be used to add and remove layers to/from the OCI image. (see `add-layer`, `remove-layer` option)

> [!NOTE]
>
> This repository should be imported as `code.cloudfoundry.org/hydrator`.
