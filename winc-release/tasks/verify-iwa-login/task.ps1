$usernameWithDomain = $env:IWA_DOMAIN + '\' + $env:IWA_USERNAME
Write-Host "Attempting to curl $env:IWA_TEST_APP_ROUTE with $usernameWithDomain"

$authString = $usernameWithDomain + ':' + $env:IWA_PASSWORD
$curlOutput = curl.exe -s $env:IWA_TEST_APP_ROUTE --negotiate -u $authString | Out-String

$testString =  "Logged in as $env:IWA_DOMAIN\\$env:IWA_USERNAME via method Negotiate."
if ($curlOutput -like "*$testString*") {
  Write-Host "success!"
  Write-Host "Curl output: $curlOutput"
  exit 0
}
else {
  Write-Host "failed with: $curlOutput"
  exit 1
}
