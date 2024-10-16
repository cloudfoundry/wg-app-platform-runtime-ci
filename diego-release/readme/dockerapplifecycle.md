# Dockerapplifecycle

The docker app lifecycle implements a Docker deployment strategy for Cloud
Foundry on Diego.

The **Builder** extracts the start command and execution metadata from the
docker image.

The **Launcher** executes the start command with the correct Cloud Foundry and
docker environment.

Read about the app lifecycle spec here:
https://github.com/cloudfoundry/diego-design-notes#app-lifecycles

> [!NOTE]
>
> This repository should be imported as `code.cloudfoundry.org/dockerapplifecycle`.
