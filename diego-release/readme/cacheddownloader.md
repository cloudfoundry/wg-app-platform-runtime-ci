# CachedDownloader

[![Go Report Card](https://goreportcard.com/badge/code.cloudfoundry.org/cacheddownloader)](https://goreportcard.com/report/code.cloudfoundry.org/cacheddownloader)
[![Go Reference](https://pkg.go.dev/badge/code.cloudfoundry.org/cacheddownloader.svg)](https://pkg.go.dev/code.cloudfoundry.org/cacheddownloader)

CachedDownloader is responsible for downloading and caching files and
maintaining reference counts for each cache entry. Entries in the cache with
no active references are ejected from the cache when new space is needed.

> [!NOTE]
>
> This repository should be imported as `code.cloudfoundry.org/cacheddownloader`.
