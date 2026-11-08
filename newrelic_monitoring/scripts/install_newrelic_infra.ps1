# Installs the New Relic infrastructure agent. Run through Azure Run Command.
# Keep this file ASCII only: Windows PowerShell 5.1 does not read BOM-less files as UTF-8.
param(
    [Parameter(Mandatory = $true)]
    [string]$LicenseKey
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

# Make any error produce a non-zero exit code, which Terraform checks.
trap {
    Write-Output "ERROR: $_"
    exit 1
}

$msiPath = Join-Path $env:TEMP 'newrelic-infra.msi'
Invoke-WebRequest -UseBasicParsing -OutFile $msiPath -Uri 'https://download.newrelic.com/infrastructure_agent/windows/newrelic-infra.msi'

$msiArguments = @(
    '/qn', '/norestart',
    '/i', $msiPath,
    'GENERATE_CONFIG=true',
    "LICENSE_KEY=$LicenseKey"
)
$msiProcess = Start-Process -FilePath 'msiexec.exe' -ArgumentList $msiArguments -Wait -PassThru
if ($msiProcess.ExitCode -notin 0, 3010) {
    throw "New Relic infrastructure agent installation failed with exit code $($msiProcess.ExitCode)"
}

Start-Service -Name 'newrelic-infra'
(Get-Service -Name 'newrelic-infra').WaitForStatus('Running', [TimeSpan]::FromMinutes(1))

Write-Output 'New Relic infrastructure agent is running'
exit 0
