# Diego SSH

[![Go Report Card](https://goreportcard.com/badge/code.cloudfoundry.org/diego-ssh)](https://goreportcard.com/report/code.cloudfoundry.org/diego-ssh)
[![Go Reference](https://pkg.go.dev/badge/code.cloudfoundry.org/diego-ssh.svg)](https://pkg.go.dev/code.cloudfoundry.org/diego-ssh)

Diego-ssh is an implementation of an ssh proxy server and a lightweight ssh
daemon that supports command execution, secure file copies via `scp`, and
secure file transfer via `sftp`. When deployed and configured correctly, these
provide a simple and scalable way to access containers associated with Diego
long running processes.

> [!NOTE]
>
> This repository should be imported as `code.cloudfoundry.org/diego-ssh`.



