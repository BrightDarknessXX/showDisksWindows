param(
    # help takes precedence when present
    [switch]$help,

    # Optional unit parameter to specify the output unit for sizes. If not provided, sizes will be auto-scaled.
    [ValidateSet('B','KB','MB','GB','TB','PB')]
    [string]$unit
)

Function Format-Size {
    param(
        [long]$bytes,
        [string]$targetUnit
    )

    if ($PSBoundParameters.ContainsKey('targetUnit') -and $targetUnit) {
        switch ($targetUnit) {
            'B'  { $divisor = 1; $unit = 'B' }
            'KB' { $divisor = 1KB; $unit = 'KB' }
            'MB' { $divisor = 1MB; $unit = 'MB' }
            'GB' { $divisor = 1GB; $unit = 'GB' }
            'TB' { $divisor = 1TB; $unit = 'TB' }
            'PB' { $divisor = 1PB; $unit = 'PB' }
        }
    } elseif ($bytes -ge 1PB) {
        $unit = "PB"
        $divisor = 1PB
    } elseif ($bytes -ge 1TB) {
        $unit = "TB"
        $divisor = 1TB
    } elseif ($bytes -ge 1GB) {
        $unit = "GB"
        $divisor = 1GB
    } elseif ($bytes -ge 1MB) {
        $unit = "MB"
        $divisor = 1MB
    } elseif ($bytes -ge 1KB) {
        $unit = "KB"
        $divisor = 1KB
    } else {
        $unit = "B"
        $divisor = 1
    }

    return "{0:N2} $unit" -f ($bytes / $divisor)
}

# If user asked for help, show a short usage and exit (help has precedence)
if ($help) {
    Write-Output "Flags     -unit <B|KB|MB|GB|TB|PB> (Optional, defaults to auto-scaling. Positional binding allowed.)"
    Write-Output "          -help    Show this help"
    return
}

Get-CimInstance Win32_LogicalDisk |
    Select-Object DeviceID,
                  VolumeName,
                  Description,
                  FileSystem,
                  @{Name='Used'; Expression={ Format-Size -bytes ($_.Size-$_.FreeSpace) -targetUnit $unit }},
                  @{Name='Free'; Expression={ Format-Size -bytes $_.FreeSpace -targetUnit $unit }},
                  @{Name='Size'; Expression={ Format-Size -bytes $_.Size -targetUnit $unit }} |
    Format-Table -AutoSize
