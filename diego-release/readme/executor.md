# Executor

Let me run that for you.

Executor is a logical process running inside the
[Rep](https://github.com/cloudfoundry/rep) that:
* manages container allocations against resource constraints on the Cell, such
  as memory and disk space
* implements the actions detailed in the API documentation
* streams stdout and stderr from container processes to the metron-agent
  running on the Cell, which in turn forwards to the Loggregator system
* periodically collects container metrics and emits them to Loggregator


> [!NOTE]
>
> This repository should be imported as `code.cloudfoundry.org/executor`.
