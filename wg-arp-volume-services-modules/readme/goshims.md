# Go Shims
[![Go Report Card](https://goreportcard.com/badge/code.cloudfoundry.org/goshims)](https://goreportcard.com/report/code.cloudfoundry.org/goshims)
[![Go Reference](https://pkg.go.dev/badge/code.cloudfoundry.org/goshims.svg)](https://pkg.go.dev/code.cloudfoundry.org/goshims)

Have you ever wanted to fake out go system libary calls? In most cases you create an interface and then provide a mock/fake implementation and a shim that calls the real calls. That's great if you only have to do it once. What happens when it becomes a pattern and these little utilities end up duplicated everywhere...that's a problem. This repo is the solution.

> [!NOTE]
>
> This repository should be imported as `code.cloudfoundry.org/goshims`.
