<#
.SYNOPSIS
    Collects system hardware information for benchmarking baseline.
.DESCRIPTION
    Gathers CPU, RAM, GPU, and storage specs using WMI/CIM and nvidia-smi.
.OUTPUTS
    PSCustomObject with system specifications
#>

function Get-SystemInfo {
    [CmdletBinding()]
    param()

    Write-Host "Collecting system information..." -ForegroundColor Cyan

    # CPU Info
    $cpu = Get-CimInstance -ClassName Win32_Processor | Select-Object -First 1
    $cpuInfo = [PSCustomObject]@{
        Name = $cpu.Name.Trim()
        Cores = $cpu.NumberOfCores
        LogicalProcessors = $cpu.NumberOfLogicalProcessors
        MaxClockSpeedMHz = $cpu.MaxClockSpeed
        L2CacheKB = $cpu.L2CacheSize
        L3CacheKB = $cpu.L3CacheSize
    }

    # RAM Info
    $ram = Get-CimInstance -ClassName Win32_PhysicalMemory
    $totalRamGB = [math]::Round(($ram | Measure-Object -Property Capacity -Sum).Sum / 1GB, 2)
    $ramSpeed = ($ram | Select-Object -First 1).Speed
    $ramInfo = [PSCustomObject]@{
        TotalGB = $totalRamGB
        SpeedMHz = $ramSpeed
        Modules = $ram.Count
    }

    # GPU Info (NVIDIA via nvidia-smi)
    $gpuInfo = $null
    $nvidiaSmi = "$env:ProgramFiles\NVIDIA Corporation\NVSMI\nvidia-smi.exe"
    if (-not (Test-Path $nvidiaSmi)) {
        $nvidiaSmi = "nvidia-smi"  # Try PATH
    }

    try {
        $gpuQuery = & $nvidiaSmi --query-gpu=name,memory.total,driver_version,power.limit --format=csv,noheader,nounits 2>$null
        if ($gpuQuery) {
            $gpuParts = $gpuQuery.Split(',').Trim()
            $gpuInfo = [PSCustomObject]@{
                Name = $gpuParts[0]
                VramMB = [int]$gpuParts[1]
                DriverVersion = $gpuParts[2]
                PowerLimitW = [decimal]$gpuParts[3]
            }
        }
    } catch {
        # Fallback to WMI
        $wmiGpu = Get-CimInstance -ClassName Win32_VideoController | Where-Object { $_.Name -like "*NVIDIA*" } | Select-Object -First 1
        if ($wmiGpu) {
            $gpuInfo = [PSCustomObject]@{
                Name = $wmiGpu.Name
                VramMB = [math]::Round($wmiGpu.AdapterRAM / 1MB, 0)
                DriverVersion = $wmiGpu.DriverVersion
                PowerLimitW = "N/A"
            }
        }
    }

    # Storage Info
    $disks = Get-CimInstance -ClassName Win32_DiskDrive | ForEach-Object {
        [PSCustomObject]@{
            Model = $_.Model
            SizeGB = [math]::Round($_.Size / 1GB, 2)
            MediaType = if ($_.MediaType -like "*SSD*" -or $_.Model -like "*SSD*" -or $_.Model -like "*NVMe*") { "SSD" } else { "HDD" }
        }
    }

    # OS Info
    $os = Get-CimInstance -ClassName Win32_OperatingSystem
    $osInfo = [PSCustomObject]@{
        Name = $os.Caption
        Version = $os.Version
        Build = $os.BuildNumber
    }

    return [PSCustomObject]@{
        Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        CPU = $cpuInfo
        RAM = $ramInfo
        GPU = $gpuInfo
        Storage = $disks
        OS = $osInfo
    }
}

# Export for module use
