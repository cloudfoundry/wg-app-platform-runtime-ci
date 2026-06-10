# diego-db-helpers
[![Go Report Card](https://goreportcard.com/badge/code.cloudfoundry.org/diego-db-helpers)](https://goreportcard.com/report/code.cloudfoundry.org/diego-db-helpers)
[![Go Reference](https://pkg.go.dev/badge/code.cloudfoundry.org/diego-db-helpers.svg)](https://pkg.go.dev/code.cloudfoundry.org/diego-db-helpers)

SQL helper utilities used by Diego components. Extracted from
`code.cloudfoundry.org/bbs` to break a circular submodule dependency and make
the helpers independently consumable.

Provides SQL query helpers, connection management with optional TLS, a
transaction wrapper with deadlock retry, and Ginkgo-compatible test runners
for MySQL and PostgreSQL.

> [!NOTE]
>
> This repository should be imported as `code.cloudfoundry.org/diego-db-helpers`.
