<#
.SYNOPSIS
    Check registry and find EVGA Precision X1 profile storage
#>

Write-Host "Checking Registry for EVGA settings..." -ForegroundColor Cyan

$regPaths = @(
    'HKCU:\Software\EVGA',
    'HKLM:\Software\EVGA',
    'HKCU:\Software\WOW6432Node\EVGA',
    'HKLM:\Software\WOW6432Node\EVGA'
)

foreach ($rp in $regPaths) {
    if (Test-Path $rp) {
        Write-Host "`nFound: $rp" -ForegroundColor Green
        Get-ChildItem $rp -Recurse -ErrorAction SilentlyContinue | ForEach-Object {
            Write-Host "  $($_.PSChildName)"
            $_ | Get-ItemProperty -ErrorAction SilentlyContinue | ForEach-Object {
                $_.PSObject.Properties | Where-Object { $_.Name -notlike 'PS*' } | ForEach-Object {
                    Write-Host "    $($_.Name) = $($_.Value)" -ForegroundColor Gray
                }
            }
        }
    }
}

# Check ProgramData
Write-Host "`nChecking ProgramData..." -ForegroundColor Cyan
$pdPath = "$env:ProgramData\EVGA"
if (Test-Path $pdPath) {
    Get-ChildItem $pdPath -Recurse | Select-Object FullName, Length
}

# Check LocalAppData
Write-Host "`nChecking LocalAppData..." -ForegroundColor Cyan
$laPath = "$env:LOCALAPPDATA\EVGA"
if (Test-Path $laPath) {
    Get-ChildItem $laPath -Recurse | Select-Object FullName, Length
}
