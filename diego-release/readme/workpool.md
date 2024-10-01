# Workpool

Use a `WorkPool` to perform units of work concurrently at a maximum rate. The
worker goroutines will increase to the maximum number of workers as work
requires it, and gradually decrease to 0 if unused.

A `Throttler` performs a specified batch of work at a given maximum rate,
internally creating a `WorkPool` and then stopping it when done.

> [!NOTE]
>
> This repository should be imported as `code.cloudfoundry.org/workpool`.
