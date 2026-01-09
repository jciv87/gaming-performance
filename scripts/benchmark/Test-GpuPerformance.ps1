<#
.SYNOPSIS
    NVIDIA GPU performance benchmark and monitoring.
.DESCRIPTION
    Uses nvidia-smi to monitor GPU stats and measure baseline performance.
    Includes temperature, clock speeds, memory usage, and power draw.
#>

function Test-GpuPerformance {
    [CmdletBinding()]
    param(
        [int]$SampleCount = 5,
        [int]$SampleIntervalMs = 1000
    )

    Write-Host "`nGPU Benchmark (NVIDIA)" -ForegroundColor Cyan
    Write-Host "======================" -ForegroundColor Cyan

    # Find nvidia-smi
    $nvidiaSmi = "$env:ProgramFiles\NVIDIA Corporation\NVSMI\nvidia-smi.exe"
    if (-not (Test-Path $nvidiaSmi)) {
        $nvidiaSmi = (Get-Command nvidia-smi -ErrorAction SilentlyContinue).Source
    }

    if (-not $nvidiaSmi -or -not (Test-Path $nvidiaSmi)) {
        Write-Host "  nvidia-smi not found. Skipping GPU benchmark." -ForegroundColor Yellow
        return $null
    }

    $results = @{
        Samples = @()
    }

    # Collect baseline samples
    Write-Host "  [1/3] Collecting idle baseline ($SampleCount samples)..." -NoNewline

    for ($i = 0; $i -lt $SampleCount; $i++) {
        $query = & $nvidiaSmi --query-gpu=temperature.gpu,clocks.gr,clocks.mem,memory.used,memory.total,power.draw,utilization.gpu,utilization.memory --format=csv,noheader,nounits 2>$null

        if ($query) {
            $parts = $query.Split(',').Trim()
            $results.Samples += [PSCustomObject]@{
                TempC = [int]$parts[0]
                CoreClockMHz = [int]$parts[1]
                MemClockMHz = [int]$parts[2]
                MemUsedMB = [int]$parts[3]
                MemTotalMB = [int]$parts[4]
                PowerW = [decimal]$parts[5]
                GpuUtilPct = [int]$parts[6]
                MemUtilPct = [int]$parts[7]
            }
        }
        Start-Sleep -Milliseconds $SampleIntervalMs
    }
    Write-Host " Done" -ForegroundColor Green

    # Calculate averages
    Write-Host "  [2/3] Calculating baseline metrics..." -NoNewline
    if ($results.Samples.Count -gt 0) {
        $results.IdleTemp = [math]::Round(($results.Samples.TempC | Measure-Object -Average).Average, 1)
        $results.IdlePowerW = [math]::Round(($results.Samples.PowerW | Measure-Object -Average).Average, 1)
        $results.IdleMemUsedMB = [math]::Round(($results.Samples.MemUsedMB | Measure-Object -Average).Average, 0)
        $results.MemTotalMB = $results.Samples[0].MemTotalMB
        $results.BaseClockMHz = ($results.Samples.CoreClockMHz | Measure-Object -Maximum).Maximum
        $results.MemClockMHz = ($results.Samples.MemClockMHz | Measure-Object -Maximum).Maximum
    }
    Write-Host " Done" -ForegroundColor Green

    # Get GPU limits
    Write-Host "  [3/3] Querying GPU capabilities..." -NoNewline
    $limits = & $nvidiaSmi --query-gpu=clocks.max.gr,clocks.max.mem,power.max_limit,pcie.link.gen.current,pcie.link.width.current --format=csv,noheader,nounits 2>$null
    if ($limits) {
        $limitParts = $limits.Split(',').Trim()
        $results.MaxCoreClockMHz = [int]$limitParts[0]
        $results.MaxMemClockMHz = [int]$limitParts[1]
        $results.MaxPowerW = [decimal]$limitParts[2]
        $results.PCIeGen = $limitParts[3]
        $results.PCIeWidth = "x$($limitParts[4])"
    }
    Write-Host " Done" -ForegroundColor Green

    # Display summary
    Write-Host "`n  Idle Temperature: $($results.IdleTemp)C" -ForegroundColor $(if ($results.IdleTemp -lt 50) { "Green" } elseif ($results.IdleTemp -lt 65) { "Yellow" } else { "Red" })
    Write-Host "  Idle Power Draw:  $($results.IdlePowerW)W"
    Write-Host "  VRAM:             $($results.IdleMemUsedMB)MB / $($results.MemTotalMB)MB used"
    Write-Host "  Base Clock:       $($results.BaseClockMHz) MHz (Max: $($results.MaxCoreClockMHz) MHz)"
    Write-Host "  PCIe:             Gen$($results.PCIeGen) $($results.PCIeWidth)"

    # Remove samples from output (too verbose)
    $results.Remove('Samples')

    return [PSCustomObject]$results
}

