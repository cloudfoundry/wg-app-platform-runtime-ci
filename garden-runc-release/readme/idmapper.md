# idmapper

[![Go Report Card](https://goreportcard.com/badge/code.cloudfoundry.org/idmapper)](https://goreportcard.com/report/code.cloudfoundry.org/gorouter)
[![Go Reference](https://pkg.go.dev/badge/code.cloudfoundry.org/idmapper.svg)](https://pkg.go.dev/code.cloudfoundry.org/gorouter)

idmapper is a package which will map a process to the highest usera id available.

Unlike the `newuidmap` and `newgidmap` commands found in [Shadow](https://github.com/shadow-maint/shadow), idmapper does not require this user to exist and will not check `/etc/subuid` for valid subuid ranges.

> [!NOTE]
>
> This repository should be imported as `code.cloudfoundry.org/idmapper`.
