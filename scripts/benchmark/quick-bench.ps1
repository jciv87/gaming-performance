<#
.SYNOPSIS
    Quick gaming performance benchmark suite.
.DESCRIPTION
    Runs CPU, GPU, and disk benchmarks and generates a baseline report.
    Use before/after system optimizations to measure impact.
.EXAMPLE
    .\quick-bench.ps1
    .\quick-bench.ps1 -SkipDisk
    .\quick-bench.ps1 -SaveReport
#>

[CmdletBinding()]
param(
    [switch]$SkipCpu,
    [switch]$SkipGpu,
    [switch]$SkipDisk,
    [switch]$SaveReport,
    [string]$ReportPath = ".\benchmark-reports"
)

$ErrorActionPreference = "Continue"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# Import modules
. "$scriptDir\Get-SystemInfo.ps1"
. "$scriptDir\Test-CpuPerformance.ps1"
. "$scriptDir\Test-GpuPerformance.ps1"
. "$scriptDir\Test-DiskPerformance.ps1"

# Banner
Write-Host ""
Write-Host "=================================" -ForegroundColor Magenta
Write-Host "  Gaming Performance Benchmark   " -ForegroundColor Magenta
Write-Host "=================================" -ForegroundColor Magenta
Write-Host ""

$report = @{
    Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Version = "1.0.0"
}

# System Info
$report.System = Get-SystemInfo

Write-Host "`nSystem: $($report.System.CPU.Name)" -ForegroundColor White
Write-Host "GPU:    $($report.System.GPU.Name)" -ForegroundColor White
Write-Host "RAM:    $($report.System.RAM.TotalGB) GB @ $($report.System.RAM.SpeedMHz) MHz" -ForegroundColor White

# CPU Benchmark
if (-not $SkipCpu) {
    $report.CPU = Test-CpuPerformance -Duration 5
} else {
    Write-Host "`nCPU Benchmark: Skipped" -ForegroundColor Yellow
}

# GPU Benchmark
if (-not $SkipGpu) {
    $report.GPU = Test-GpuPerformance -SampleCount 3 -SampleIntervalMs 500
} else {
    Write-Host "`nGPU Benchmark: Skipped" -ForegroundColor Yellow
}

# Disk Benchmark
if (-not $SkipDisk) {
    $report.Disk = Test-DiskPerformance -FileSizeMB 128
} else {
    Write-Host "`nDisk Benchmark: Skipped" -ForegroundColor Yellow
}

# Summary
Write-Host "`n=================================" -ForegroundColor Magenta
Write-Host "         BENCHMARK SUMMARY       " -ForegroundColor Magenta
Write-Host "=================================" -ForegroundColor Magenta

$summary = @()

if ($report.CPU) {
    $summary += "CPU Single-Thread:  $($report.CPU.SingleThreadScore) ops/sec"
    $summary += "CPU Multi-Thread:   $($report.CPU.MultiThreadScore) ops/sec ($($report.CPU.ThreadCount) threads)"
    $summary += "Memory Bandwidth:   $($report.CPU.MemoryBandwidthGBs) GB/s"
}

if ($report.GPU) {
    $summary += "GPU Idle Temp:      $($report.GPU.IdleTemp)C"
    $summary += "GPU Idle Power:     $($report.GPU.IdlePowerW)W"
    $summary += "GPU VRAM Free:      $($report.GPU.MemTotalMB - $report.GPU.IdleMemUsedMB) MB"
}

if ($report.Disk) {
    $summary += "Disk Seq Read:      $($report.Disk.SeqReadMBs) MB/s"
    $summary += "Disk Seq Write:     $($report.Disk.SeqWriteMBs) MB/s"
    $summary += "Disk Random Read:   $($report.Disk.RandomReadIOPS) IOPS"
}

$summary | ForEach-Object { Write-Host "  $_" -ForegroundColor Cyan }

# Save report
if ($SaveReport) {
    if (-not (Test-Path $ReportPath)) {
        New-Item -ItemType Directory -Path $ReportPath -Force | Out-Null
    }
    $reportFile = Join-Path $ReportPath "benchmark_$(Get-Date -Format 'yyyyMMdd_HHmmss').json"
    $report | ConvertTo-Json -Depth 10 | Set-Content $reportFile -Encoding UTF8
    Write-Host "`nReport saved: $reportFile" -ForegroundColor Green
}

Write-Host "`nBenchmark complete!" -ForegroundColor Green
Write-Host ""

# Return report object for programmatic use
return $report
