<#
.SYNOPSIS
    Switch MSI Afterburner GPU profiles via command line.
.DESCRIPTION
    Switches between pre-configured Afterburner profiles for different use cases.
    Profiles must be configured in Afterburner first.
.PARAMETER Profile
    Profile to activate: 'performance', 'efficient', 'stock'
.EXAMPLE
    .\Switch-GpuProfile.ps1 -Profile performance
    .\Switch-GpuProfile.ps1 -Profile efficient
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('performance', 'efficient', 'stock', '1', '2', '3', '4', '5')]
    [string]$Profile
)

$afterburnerPath = "${env:ProgramFiles(x86)}\MSI Afterburner\MSIAfterburner.exe"

if (-not (Test-Path $afterburnerPath)) {
    Write-Host "ERROR: MSI Afterburner not found at $afterburnerPath" -ForegroundColor Red
    exit 1
}

# Map profile names to Afterburner profile slots
$profileMap = @{
    'performance' = '-Profile1'
    'efficient'   = '-Profile2'
    'stock'       = '-Profile3'
    '1'           = '-Profile1'
    '2'           = '-Profile2'
    '3'           = '-Profile3'
    '4'           = '-Profile4'
    '5'           = '-Profile5'
}

$profileArg = $profileMap[$Profile]

Write-Host "Switching to GPU profile: $Profile" -ForegroundColor Cyan

# Check if Afterburner is running
$abProcess = Get-Process -Name "MSIAfterburner" -ErrorAction SilentlyContinue

if ($abProcess) {
    # Afterburner is running - just apply profile
    Start-Process -FilePath $afterburnerPath -ArgumentList $profileArg -WindowStyle Hidden
    Write-Host "Profile applied!" -ForegroundColor Green
} else {
    # Start Afterburner minimized with the profile
    Start-Process -FilePath $afterburnerPath -ArgumentList "$profileArg -m" -WindowStyle Hidden
    Write-Host "Afterburner started with profile applied!" -ForegroundColor Green
}

# Show current GPU state after a brief delay
Start-Sleep -Seconds 2
Write-Host "`nCurrent GPU state:" -ForegroundColor Yellow
nvidia-smi --query-gpu=clocks.gr,clocks.mem,power.draw,temperature.gpu --format=csv
