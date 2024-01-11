Write-Host "Attempting to curl $env:IWA_TEST_APP_ROUTE for IWA SQL"

$curlOutput = curl.exe -s $env:IWA_TEST_APP_ROUTE | Out-String

# Magic string pre-populated in the IWA database
$testString =  "AJ, 18"
if ($curlOutput -like "*$testString*") {
  Write-Host "success!"
  exit 0
}
else {
  Write-Host "failed with: $curlOutput"
  exit 1
}
