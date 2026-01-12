<#
.SYNOPSIS
    Find overclocking tool configs and check nvidia-smi capabilities
#>

Write-Host "Searching for EVGA Precision X1..." -ForegroundColor Cyan

$searchPaths = @(
    "$env:LOCALAPPDATA\EVGA",
    "$env:APPDATA\EVGA",
    "$env:ProgramFiles\EVGA",
    "${env:ProgramFiles(x86)}\EVGA",
    "$env:LOCALAPPDATA\EVGA Company",
    "$env:ProgramData\EVGA"
)

$found = $false
foreach ($p in $searchPaths) {
    if (Test-Path $p) {
        Write-Host "`nFound EVGA folder: $p" -ForegroundColor Green
        Get-ChildItem $p -Recurse -ErrorAction SilentlyContinue |
            Where-Object { $_.Extension -match '\.(xml|cfg|ini|json|config|dat)$' } |
            ForEach-Object { Write-Host "  Config: $($_.FullName)" }
        $found = $true
    }
}

if (-not $found) {
    Write-Host "No EVGA config folders found in standard locations" -ForegroundColor Yellow

    # Try to find via registry or running process
    $proc = Get-Process -Name "*precision*" -ErrorAction SilentlyContinue
    if ($proc) {
        Write-Host "`nPrecision X1 is running: $($proc.Path)" -ForegroundColor Green
    }
}

# Check nvidia-smi power limit capability
Write-Host "`n`nNVIDIA-SMI Power Control:" -ForegroundColor Cyan
Write-Host "Current power limit: " -NoNewline
nvidia-smi --query-gpu=power.limit --format=csv,noheader,nounits
Write-Host "Power limit range: " -NoNewline
$min = nvidia-smi --query-gpu=power.min_limit --format=csv,noheader,nounits
$max = nvidia-smi --query-gpu=power.max_limit --format=csv,noheader,nounits
Write-Host "$min W - $max W"

Write-Host "`nWe CAN set power limit via: nvidia-smi -pl <watts>" -ForegroundColor Green
Write-Host "Example: nvidia-smi -pl 260" -ForegroundColor Gray
