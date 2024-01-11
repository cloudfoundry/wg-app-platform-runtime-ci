$ErrorActionPreference = "Stop";
trap { $host.SetShouldExit(1) }

Write-Host "Installing Windows Dependencies"
Install-WindowsFeature Web-WHC
Install-WindowsFeature Web-Webserver
Install-WindowsFeature Web-WebSockets
Install-WindowsFeature Web-WHC
Install-WindowsFeature Web-ASP
Install-WindowsFeature Web-ASP-Net45

cd hwc

Write-Host "Running Ginkgo Tests"
go.exe run github.com/onsi/ginkgo/v2/ginkgo -p -r -race -keep-going
if ($LastExitCode -ne 0) {
    throw "Testing hwc returned error code: $LastExitCode"
}
