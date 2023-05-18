function Configure-Gdn
{
    $env:PATH = "C:/var/vcap/bosh/bin;" + $env:PATH
    $tarBin = (get-command tar.exe).source

        $args='server --skip-setup --runtime-plugin={0} --image-plugin="{1}" --image-plugin-extra-arg=--driver-store={2} --image-plugin-extra-arg=--config={3} --network-plugin={4} --network-plugin-extra-arg=--configFile={5} --network-plugin-extra-arg=--log={6} --network-plugin-extra-arg=--debug --bind-ip={7} --bind-port={8} --default-rootfs={9} --nstar-bin={10} --tar-bin={11} --init-bin={12} --depot={13} --log-level=debug' -f $env:WINC_BINARY,$env:GROOT_BINARY,$env:GROOT_IMAGE_STORE,$env:GROOT_CONFIG,$env:WINC_NETWORK_BINARY, $env:WINC_NETWORK_CONFIG,$env:WINC_NETWORK_LOG_FILE, $env:GDN_BIND_IP,$env:GDN_BIND_PORT,$env:WINC_TEST_ROOTFS,$env:NSTAR_BINARY,$tarBin, $env:WINIT_BINARY,$env:GDN_DEPOT_PATH

        Debug "Start-Process $env:GDN_BINARY with Args: $args"

        Start-Process -NoNewWindow -RedirectStandardOutput $env:GDN_OUT_LOG_FILE -RedirectStandardError $env:GDN_ERR_LOG_FILE "$env:GDN_BINARY" -ArgumentList $args

# wait for server to start up
# and then curl to confirm that it is
        Start-Sleep -s 5
        $pingResult = (curl -UseBasicParsing "http://${env:GDN_BIND_IP}:${env:GDN_BIND_PORT}/ping").StatusCode
        if ($pingResult -ne 200) {
            throw "Pinging garden server failed with code: $pingResult"
        }

        Remove-Item -Recurse -Force -ErrorAction Ignore $env:GDN_DEPOT_PATH
        New-Item -ItemType Directory -Path $env:GDN_DEPOT_PATH -Force
}

function Kill-Gdn
{
  Get-Process | foreach { if ($_.name -eq "gdn") { Stop-Process -Force $_.Id } }
  Start-Sleep -s 5

  if ($(Get-Process -Name "gdn" -ErrorAction SilentlyContinue ) -ne $null) {
      throw "Unable to stop gdn"
  }
}

