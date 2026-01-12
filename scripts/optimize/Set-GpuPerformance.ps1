<#
.SYNOPSIS
    GPU performance tuning script for NVIDIA cards
.DESCRIPTION
    Applies power limits and performance settings via nvidia-smi.
    For clock offsets and voltage curves, use Precision X1 manually.
.PARAMETER PowerLimit
    Power limit in watts (e.g., 260 for RTX 3060 Ti max)
.PARAMETER Profile
    Preset profile: 'performance', 'balanced', 'quiet', 'stock'
.EXAMPLE
    .\Set-GpuPerformance.ps1 -Profile performance
    .\Set-GpuPerformance.ps1 -PowerLimit 260
#>

[CmdletBinding()]
param(
    [ValidateRange(100, 300)]
    [int]$PowerLimit,

    [ValidateSet('performance', 'balanced', 'quiet', 'stock')]
    [string]$Profile
)

# Check admin status (needed for applying changes)
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

# Get current GPU info
$gpuName = nvidia-smi --query-gpu=name --format=csv,noheader
$currentPL = nvidia-smi --query-gpu=power.limit --format=csv,noheader,nounits
$maxPL = nvidia-smi --query-gpu=power.max_limit --format=csv,noheader,nounits
$minPL = nvidia-smi --query-gpu=power.min_limit --format=csv,noheader,nounits

Write-Host "`nGPU Performance Tuner" -ForegroundColor Cyan
Write-Host "=====================" -ForegroundColor Cyan
Write-Host "GPU: $gpuName"
Write-Host "Current Power Limit: $currentPL W (Range: $minPL - $maxPL W)"

# Profile presets (for RTX 3060 Ti - adjust for other cards)
$profiles = @{
    'performance' = @{ PowerLimit = [int]$maxPL; Desc = "Maximum power for peak performance" }
    'balanced'    = @{ PowerLimit = 220; Desc = "Good performance with reasonable power" }
    'quiet'       = @{ PowerLimit = 180; Desc = "Lower power, cooler and quieter" }
    'stock'       = @{ PowerLimit = 200; Desc = "Factory default" }
}

# Determine target power limit
$targetPL = $null
if ($Profile) {
    $targetPL = $profiles[$Profile].PowerLimit
    Write-Host "`nApplying '$Profile' profile: $($profiles[$Profile].Desc)" -ForegroundColor Yellow
} elseif ($PowerLimit) {
    $targetPL = $PowerLimit
} else {
    Write-Host "`nAvailable Profiles:" -ForegroundColor Yellow
    $profiles.GetEnumerator() | ForEach-Object {
        Write-Host "  $($_.Key.PadRight(12)) - $($_.Value.Desc) ($($_.Value.PowerLimit)W)"
    }
    Write-Host "`nUsage: .\Set-GpuPerformance.ps1 -Profile <name>"
    Write-Host "   or: .\Set-GpuPerformance.ps1 -PowerLimit <watts>"
    exit 0
}

# Apply power limit
if ($targetPL) {
    if (-not $isAdmin) {
        Write-Host "`nERROR: Run as Administrator to apply settings" -ForegroundColor Red
        Write-Host "  Right-click PowerShell -> Run as Administrator" -ForegroundColor Yellow
        exit 1
    }
    Write-Host "`nSetting power limit to $targetPL W..." -NoNewline
    $result = nvidia-smi -pl $targetPL 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host " Done!" -ForegroundColor Green
    } else {
        Write-Host " Failed!" -ForegroundColor Red
        Write-Host $result
    }
}

# Show current state
Write-Host "`nCurrent GPU State:" -ForegroundColor Cyan
nvidia-smi --query-gpu=power.limit,temperature.gpu,clocks.gr,clocks.mem,utilization.gpu --format=csv

# Reminder for manual settings
Write-Host "`n" + "="*50 -ForegroundColor DarkGray
Write-Host "For clock offsets and voltage curves:" -ForegroundColor Yellow
Write-Host "  1. Open EVGA Precision X1"
Write-Host "  2. Apply these recommended settings:"
Write-Host ""
Write-Host "     PERFORMANCE MODE:" -ForegroundColor Green
Write-Host "       Core Clock: +100 to +150 MHz"
Write-Host "       Memory Clock: +500 to +800 MHz"
Write-Host "       Voltage: Stock or +50mV"
Write-Host ""
Write-Host "     UNDERVOLT MODE (Efficient):" -ForegroundColor Cyan
Write-Host "       V/F Curve: 1950 MHz @ 0.900V"
Write-Host "       Memory Clock: +500 MHz"
Write-Host ""
Write-Host "  3. Save as Profile 1 for quick switching"
Write-Host "="*50 -ForegroundColor DarkGray
