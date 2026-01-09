<#
.SYNOPSIS
    Disk I/O performance benchmark.
.DESCRIPTION
    Measures sequential read/write and random I/O performance.
    Tests the drive where the script runs (or specified path).
#>

function Test-DiskPerformance {
    [CmdletBinding()]
    param(
        [string]$TestPath = $env:TEMP,
        [int]$FileSizeMB = 256,
        [int]$BlockSizeKB = 1024
    )

    Write-Host "`nDisk I/O Benchmark" -ForegroundColor Cyan
    Write-Host "==================" -ForegroundColor Cyan

    $testFile = Join-Path $TestPath "benchmark_test_$(Get-Random).dat"
    $results = @{}

    try {
        # Get drive info
        $driveLetter = (Split-Path $TestPath -Qualifier).TrimEnd(':')
        $drive = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DeviceID='$driveLetter`:'"
        $freeGB = [math]::Round($drive.FreeSpace / 1GB, 2)
        Write-Host "  Testing drive $driveLetter`: ($freeGB GB free)"

        if ($freeGB -lt ($FileSizeMB / 1024 * 2)) {
            Write-Host "  Insufficient space for benchmark" -ForegroundColor Yellow
            return $null
        }

        $blockSize = $BlockSizeKB * 1KB
        $totalBytes = $FileSizeMB * 1MB
        $buffer = [byte[]]::new($blockSize)
        [System.Random]::new().NextBytes($buffer)

        # Sequential Write
        Write-Host "  [1/4] Sequential write ($FileSizeMB MB)..." -NoNewline
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        $fs = [System.IO.File]::OpenWrite($testFile)
        $bytesWritten = 0
        while ($bytesWritten -lt $totalBytes) {
            $fs.Write($buffer, 0, $buffer.Length)
            $bytesWritten += $buffer.Length
        }
        $fs.Flush()
        $fs.Close()
        $sw.Stop()
        $writeSpeedMBs = [math]::Round($totalBytes / $sw.Elapsed.TotalSeconds / 1MB, 1)
        Write-Host " $writeSpeedMBs MB/s" -ForegroundColor Green
        $results.SeqWriteMBs = $writeSpeedMBs

        # Sequential Read
        Write-Host "  [2/4] Sequential read ($FileSizeMB MB)..." -NoNewline
        # Clear file system cache (best effort)
        [System.GC]::Collect()
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        $fs = [System.IO.File]::OpenRead($testFile)
        $bytesRead = 0
        while ($bytesRead -lt $totalBytes) {
            $read = $fs.Read($buffer, 0, $buffer.Length)
            if ($read -eq 0) { break }
            $bytesRead += $read
        }
        $fs.Close()
        $sw.Stop()
        $readSpeedMBs = [math]::Round($totalBytes / $sw.Elapsed.TotalSeconds / 1MB, 1)
        Write-Host " $readSpeedMBs MB/s" -ForegroundColor Green
        $results.SeqReadMBs = $readSpeedMBs

        # Random Read (4KB blocks, 1000 operations)
        Write-Host "  [3/4] Random read (4KB x 1000)..." -NoNewline
        $smallBuffer = [byte[]]::new(4KB)
        $fileSize = (Get-Item $testFile).Length
        $ops = 1000
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        $fs = [System.IO.File]::OpenRead($testFile)
        for ($i = 0; $i -lt $ops; $i++) {
            $pos = Get-Random -Minimum 0 -Maximum ($fileSize - 4KB)
            $fs.Seek($pos, [System.IO.SeekOrigin]::Begin) | Out-Null
            $fs.Read($smallBuffer, 0, $smallBuffer.Length) | Out-Null
        }
        $fs.Close()
        $sw.Stop()
        $randomReadIOPS = [math]::Round($ops / $sw.Elapsed.TotalSeconds, 0)
        Write-Host " $randomReadIOPS IOPS" -ForegroundColor Green
        $results.RandomReadIOPS = $randomReadIOPS

        # Random Write (4KB blocks, 1000 operations)
        Write-Host "  [4/4] Random write (4KB x 1000)..." -NoNewline
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        $fs = [System.IO.FileStream]::new($testFile, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Write)
        for ($i = 0; $i -lt $ops; $i++) {
            $pos = Get-Random -Minimum 0 -Maximum ($fileSize - 4KB)
            $fs.Seek($pos, [System.IO.SeekOrigin]::Begin) | Out-Null
            $fs.Write($smallBuffer, 0, $smallBuffer.Length)
        }
        $fs.Flush()
        $fs.Close()
        $sw.Stop()
        $randomWriteIOPS = [math]::Round($ops / $sw.Elapsed.TotalSeconds, 0)
        Write-Host " $randomWriteIOPS IOPS" -ForegroundColor Green
        $results.RandomWriteIOPS = $randomWriteIOPS

        $results.TestDrive = "$driveLetter`:"
        $results.TestSizeMB = $FileSizeMB

    } finally {
        # Cleanup
        if (Test-Path $testFile) {
            Remove-Item $testFile -Force -ErrorAction SilentlyContinue
        }
    }

    return [PSCustomObject]$results
}

