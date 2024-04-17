function Configure-Groot{
    Param
        (
         [Parameter(Mandatory=$true, Position=0)]
         [string] $Rootfs
        )

        Debug "Running $env:GROOT_BINARY --driver-store $env:GROOT_IMAGE_STORE pull $Rootfs"

        New-Item -ItemType Directory -Force -Path "$env:GROOT_IMAGE_STORE"
        Write-Host "Pulling Image:" $Rootfs
        & "$env:GROOT_BINARY" --driver-store "$env:GROOT_IMAGE_STORE" pull "$Rootfs"
        if ($LastExitCode -ne 0) {
            throw "Running $env:GROOT_BINARY pull failed"
        }
}

function Configure-Winc-Network {
    Param
        (
         [Parameter(Mandatory=$true, Position=0)]
         [string] $Action
        )

        if ($Action -eq "delete") {
            Debug "$env:WINC_NETWORK_BINARY --action delete --configFile $env:WINC_NETWORK_CONFIG"
            & "$env:WINC_NETWORK_BINARY" --action delete --configFile "$env:WINC_NETWORK_CONFIG"
            if ($LastExitCode -ne 0) {
                throw "Running $env:WINC_NETWORK_BINARY failed"
            }

        } elseif ($Action -eq "create") {
            Debug "$env:WINC_NETWORK_BINARY --action create --configFile $env:WINC_NETWORK_CONFIG"
            & "$env:WINC_NETWORK_BINARY" --action create --configFile "$env:WINC_NETWORK_CONFIG"
            if ($LastExitCode -ne 0) {
                throw "Running $env:WINC_NETWORK_BINARY failed"
            }
        } else {
            throw "Undefined action"
                exit 1
        }
}
