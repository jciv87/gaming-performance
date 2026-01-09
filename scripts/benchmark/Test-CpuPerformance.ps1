<#
.SYNOPSIS
    CPU performance benchmark for gaming systems.
.DESCRIPTION
    Runs single-threaded and multi-threaded computational tests.
    Measures prime calculation, matrix operations, and compression.
#>

function Test-CpuPerformance {
    [CmdletBinding()]
    param(
        [int]$Duration = 10  # Seconds per test
    )

    Write-Host "`nCPU Benchmark" -ForegroundColor Cyan
    Write-Host "=============" -ForegroundColor Cyan

    $results = @{}

    # Single-threaded: Prime number calculation
    Write-Host "  [1/3] Single-thread prime calculation..." -NoNewline
    $primeCount = 0
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $endTime = [DateTime]::Now.AddSeconds($Duration)

    while ([DateTime]::Now -lt $endTime) {
        $num = Get-Random -Minimum 100000 -Maximum 999999
        $isPrime = $true
        for ($i = 2; $i -le [math]::Sqrt($num); $i++) {
            if ($num % $i -eq 0) { $isPrime = $false; break }
        }
        if ($isPrime) { $primeCount++ }
    }
    $sw.Stop()
    $singleScore = [math]::Round($primeCount / $sw.Elapsed.TotalSeconds, 0)
    Write-Host " $singleScore ops/sec" -ForegroundColor Green
    $results.SingleThreadScore = $singleScore

    # Multi-threaded: Parallel computation
    Write-Host "  [2/3] Multi-thread parallel test..." -NoNewline
    $cpuCount = [Environment]::ProcessorCount
    $sw = [System.Diagnostics.Stopwatch]::StartNew()

    $jobs = 1..$cpuCount | ForEach-Object {
        Start-Job -ScriptBlock {
            param($seconds)
            $count = 0
            $end = [DateTime]::Now.AddSeconds($seconds)
            while ([DateTime]::Now -lt $end) {
                $num = Get-Random -Minimum 100000 -Maximum 999999
                $isPrime = $true
                for ($i = 2; $i -le [math]::Sqrt($num); $i++) {
                    if ($num % $i -eq 0) { $isPrime = $false; break }
                }
                if ($isPrime) { $count++ }
            }
            return $count
        } -ArgumentList $Duration
    }

    $jobResults = $jobs | Wait-Job | Receive-Job
    $jobs | Remove-Job
    $sw.Stop()

    $totalOps = ($jobResults | Measure-Object -Sum).Sum
    $multiScore = [math]::Round($totalOps / $sw.Elapsed.TotalSeconds, 0)
    Write-Host " $multiScore ops/sec" -ForegroundColor Green
    $results.MultiThreadScore = $multiScore

    # Scaling efficiency
    $scalingEfficiency = [math]::Round(($multiScore / ($singleScore * $cpuCount)) * 100, 1)
    Write-Host "  [3/3] Scaling efficiency: $scalingEfficiency%" -ForegroundColor $(if ($scalingEfficiency -gt 70) { "Green" } else { "Yellow" })
    $results.ScalingEfficiency = $scalingEfficiency
    $results.ThreadCount = $cpuCount

    # Memory bandwidth test (simple)
    Write-Host "  [+] Memory bandwidth test..." -NoNewline
    $arraySize = 100MB
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $array = [byte[]]::new($arraySize)
    [System.Array]::Clear($array, 0, $array.Length)
    $null = $array.Clone()
    $sw.Stop()
    $bandwidthGBs = [math]::Round(($arraySize * 2) / $sw.Elapsed.TotalSeconds / 1GB, 2)
    Write-Host " $bandwidthGBs GB/s" -ForegroundColor Green
    $results.MemoryBandwidthGBs = $bandwidthGBs

    return [PSCustomObject]$results
}

