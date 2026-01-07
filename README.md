# Gaming Performance Toolkit

All-in-one Windows gaming optimization toolkit: performance tweaks, benchmarking, and configuration management.

## Features

- **Optimization Scripts** - PowerShell scripts to tune Windows for gaming
- **Benchmarking** - Measure FPS, frame times, and system utilization
- **Config Profiles** - Game and driver settings optimized for performance

## Project Structure

```
gaming-performance/
├── scripts/           # Optimization and utility scripts
│   ├── optimize/      # Windows optimization tweaks
│   ├── benchmark/     # Benchmarking tools
│   └── utils/         # Helper utilities
├── configs/           # Configuration profiles
│   ├── games/         # Per-game settings
│   ├── drivers/       # GPU driver profiles
│   └── windows/       # Windows settings exports
├── docs/              # Documentation
└── tests/             # Test scripts
```

## Quick Start

```powershell
# Run optimization suite
.\scripts\optimize\run-all.ps1

# Benchmark current system
.\scripts\benchmark\quick-bench.ps1

# Apply a game profile
.\scripts\utils\apply-profile.ps1 -Game "GameName"
```

## Requirements

- Windows 10/11
- PowerShell 5.1+
- Administrator privileges (for some optimizations)

## License

MIT
