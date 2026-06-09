[CmdletBinding()]
param(
    # help takes precedence when present
    [switch]$help,

    # Optional unit parameter to specify the output unit for sizes. If not provided, sizes will be auto-scaled.
    [ValidateSet('B','KB','MB','GB','TB','PB')]
    [string]$unit
)

# Define a hashtable to map size units to their corresponding byte values for easy conversion.
$sizeUnits = @{
    B = 1
    KB = 1KB
    MB = 1MB
    GB = 1GB
    TB = 1TB
    PB = 1PB
}

# Create an ordered list of size units for auto-scaling, sorted from largest to smallest.
$autoScaleOrder = $sizeUnits.Keys | Sort-Object { $sizeUnits[$_] } -Descending

# Function - Format size in bytes to corresponding unit.
Function Format-Size {
    param(
        [long]$bytes,
        [string]$targetUnit
    )

    # Checks if a parameter for $targetUnit was provided.
    if ($targetUnit) {
        # Checks if provided parameter $targetUnit is valid and exists in the $sizeUnits hashtable. Otherwise, throw an error.
        if (-not $sizeUnits.ContainsKey($targetUnit)) {
            throw "Invalid unit '$targetUnit'. Valid units: $($sizeUnits.Keys -join ', ')"
        }

        # Use the provided target unit and its corresponding divisor for scaling.
        $unit = $targetUnit
        $divisor = $sizeUnits[$targetUnit]
    } else {
        # Default to bytes if no auto-scaling candidate is found.
        $unit = 'B'
        $divisor = $sizeUnits[$unit]

        foreach ($candidate in $autoScaleOrder) {
            if ($bytes -ge $sizeUnits[$candidate]) {
                $unit = $candidate
                $divisor = $sizeUnits[$candidate]
                break
            }
        }
    }

    # Format the output string with two decimal places and the appropriate unit.
    return "{0:N2} $unit" -f ($bytes / $divisor)
}

# Function - Format a progress bar based on the percentage of disk used, with 10 segments representing 100% usage.
Function Format-DiskUsageBar {
    param(
        [Parameter(ValueFromPipeline)]
        [double]$usedPercent
    )

    # Calculate the number of filled segments (10 total) based on the percentage used.
    $filled = [Math]::Round($usedPercent / 10)
    # Calculate the number of empty segments (10 total - filled).
    $empty = 10 - $filled

    # Construct the progress bar string with filled and empty segments, and append the percentage used.
    return "[{0}{1}] {2}%" -f ('#' * $filled), ('-' * $empty), ($usedPercent)
}

# Function - Calculate the percentage of disk space used based on total size and free space, and round to two decimal places.
Function Get-UsedPercent {
    param(
        [long]$Size,
        [long]$FreeSpace
    )

    # Avoid division by zero if the total size is zero, and return 0% used in that case.
    if ($Size -eq 0) {
        return 0
    }
    
    return [Math]::Round(($Size - $FreeSpace) / $Size * 100, 2)
}

# If user asked for help, show a short usage and exit (help has precedence).
if ($help) {
    Write-Host "Disk Usage Information Script v1.1 _BrightDarkness_" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Usage:    .\disk.ps1 [-unit <B|KB|MB|GB|TB|PB>] [-help]"
    Write-Host ""
    Write-Host "Flags     -unit <B|KB|MB|GB|TB|PB> (Optional, defaults to auto-scaling."
    Write-Host "                                    Positional binding allowed.)"
    Write-Host "          -help    Show this help"
    return
}

# Retrieve logical disk information and format the output.
Get-CimInstance Win32_LogicalDisk |
    Select-Object DeviceID,
                  VolumeName,
                  Description,
                  FileSystem,
                  @{Name='Used'; Expression={ Format-Size -bytes ($_.Size-$_.FreeSpace) -targetUnit $unit }},
                  @{Name='Free'; Expression={ Format-Size -bytes $_.FreeSpace -targetUnit $unit }},
                  @{Name='Size'; Expression={ Format-Size -bytes $_.Size -targetUnit $unit }},
                  @{Name='DiskUsage'; Expression={
                    Get-UsedPercent -Size $_.Size -FreeSpace $_.FreeSpace |
                    Format-DiskUsageBar
                    }} |
    Format-Table -AutoSize
