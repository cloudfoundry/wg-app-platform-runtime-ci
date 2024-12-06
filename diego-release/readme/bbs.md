# BBS

[![Go Report Card](https://goreportcard.com/badge/code.cloudfoundry.org/bbs)](https://goreportcard.com/report/code.cloudfoundry.org/bbs)
[![Go Reference](https://pkg.go.dev/badge/code.cloudfoundry.org/bbs.svg)](https://pkg.go.dev/code.cloudfoundry.org/bbs)

Bulletin Board System (BBS) is the API to access the database for Diego. It
communicates via protocol-buffer-encoded RPC-style calls over HTTP.

Diego clients communicate with the BBS via an
[ExternalClient](https://godoc.org/github.com/cloudfoundry/bbs#ExternalClient)
interface. This interface allows clients to create, read, update, delete, and
subscribe to events about Tasks and LRPs.

> [!NOTE]
>
> This repository should be imported as `code.cloudfoundry.org/bbs`.
