# dontpanic

[![Go Report Card](https://goreportcard.com/badge/code.cloudfoundry.org/dontpanic)](https://goreportcard.com/report/code.cloudfoundry.org/gorouter)
[![Go Reference](https://pkg.go.dev/badge/code.cloudfoundry.org/dontpanic.svg)](https://pkg.go.dev/code.cloudfoundry.org/gorouter)

dontpanic is a tool for debugging issues with Garden containers and their host environment. It collects and tars all necessary data to help Garden engineers investigate bugs. This data includes Garden logs and general system information. It should not contain any sensitive information, but you are free to review before sending to us. The Garden team is comprised of engineers from multiple companies and all bugs are investigated together. Your report will not be shared outside the team. A full list of what is collected can be found below.

- The current date
- The machine's uptime and current load
- The deployed `gdn` version
- The machine hostname
- Free memory
- Operating system and kernel information
- Monit summary
- Monit logs
- The number of running garden containers
- The number of open files
- The max number of open files permitted on the machine
- The current disk usage
- A list of all open files
- Process table
- Process tree
- Kernel logs
- System logs
- Garden logs
- Network interfaces
- IP tables
- The mount table
- A list of the contents of Garden's depot (container metadata store) dir
- XFS filesystem information
- Memory structure information
- General VM statistics (IO, Memory etc etc)
- General process information


> [!NOTE]
>
> This repository should be imported as `code.cloudfoundry.org/dontpanic`.
