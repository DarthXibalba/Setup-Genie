# Get the absolute path of the parent directory of the script
$scriptPath = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
$topLevelPath = Split-Path -Parent -Path $scriptPath
$ubuntuSetupGeniePath = Join-Path -Path $topLevelPath -ChildPath "ubuntu"

# Define the array of accepted OS flags
$acceptedWSLDistros = @(
    'Ubuntu',
    'Ubuntu-20.04',
    'Ubuntu-22.04',
    'phoenix'
)

# Define the array of items to copy
$itemsToCopy = @(
    "config\",
    "profile\",
    "scripts\",
    "setup-files\",
    "setup.sh"
)

# Verify input args
if ($args.Count -ne 1) {
    Write-Host "Invalid number of WSL Distros specified. Please use exactly one of the following: { $($acceptedWSLDistros -join ' | ') }"
    Write-Host "Example: .\CopyFilesToWSL2.ps1 <WSL Distro>"
    return
}
# Retrieve the OS flag from command-line argument
$wslDistro = $args[0]
if ($wslDistro -notin $acceptedWSLDistros) {
    Write-Host "Invalid WSL Distro specified. Please use exactly one of the follwoing: { $($acceptedWSLDistros -join ' | ') }"
    Write-Host "Example: .\CopyFilesToWSL2.ps1 <WSL Distro>"
    return
}

# Set the destination paths (for both WSL & Native Linux)
$linuxDestinationPathTmp = "/tmp/Setup-Genie-tmp/"
$linuxDestinationPathFinal = "/tmp/Setup-Genie/"
$wslDistroPath = "\\wsl$\$wslDistro"
$wslDestinationPathTmp = Join-Path -Path $wslDistroPath -ChildPath ($linuxDestinationPathTmp -replace "/", "\")
$wslDestinationPathFinal = Join-Path -Path $wslDistroPath -ChildPath ($linuxDestinationPathFinal -replace "/", "\")

# Create destination directories if they do not exist
if (!(Test-Path -Path $wslDestinationPathTmp -PathType Container)) {
    New-Item -ItemType Directory -Path $wslDestinationPathTmp -Force | Out-Null
}
if (!(Test-Path -Path $wslDestinationPathFinal -PathType Container)) {
    New-Item -ItemType Directory -Path $wslDestinationPathFinal -Force | Out-Null
}

## Copy each item from the source to the tmp destination
#foreach ($item in $itemsToCopy) {
#    $srcItemPath = Join-Path -Path $ubuntuSetupGeniePath -ChildPath $item
#    $tmpItemPath = Join-Path -Path $wslDestinationPathTmp -ChildPath $item
#
#    # Check if item already exists
#    if (Test-Path -Path $tmpItemPath) {
#        $confirmation = Read-Host "Item '$tmpItemPath' already exists. Do you want to overwrite it? (y/n)"
#        if ($confirmation -ne 'Y' -and $confirmation -ne 'y') {
#            continue # skip copying
#        } else {
#            Remove-Item -Path $tmpItemPath -Force -Recurse
#        }
#    }
#
#    Copy-Item -Path $srcItemPath -Destination $tmpItemPath -Recurse -Force
#    Write-Host "Copied $srcItemPath -> $tmpItemPath"
#}

# Copy each individual item from the source to the tmp destination, then chmod if needed (scripts only)
# and finally, remove carriage returns and move to final destination
foreach ($item in $itemsToCopy) {
    $wslSrcItemPath = Join-Path -Path $ubuntuSetupGeniePath -ChildPath $item
    $wslTmpItemPath = Join-Path -Path $wslDestinationPathTmp -ChildPath $item
    $wslDstItemPath = Join-Path -Path $wslDestinationPathFinal -ChildPath $item

    # Check if item already exists (default mode: Override files by force removing them)
    if (Test-Path -Path $wslTmpItemPath) {
        Remove-Item -Path $wslTmpItemPath -Force -Recurse
    }
    if (Test-Path -Path $wslDstItemPath) {
        Remove-Item -Path $wslDstItemPath -Force -Recurse
    }

    # If src item is a directory
    if (Test-Path -Path $wslSrcItemPath -PathType Container) {
        # Create destination directories if they do not exist
        if (!(Test-Path -Path $wslTmpItemPath -PathType Container)) {
            New-Item -ItemType Directory -Path $wslTmpItemPath -Force | Out-Null
        }
        if (!(Test-Path -Path $wslDstItemPath -PathType Container)) {
            New-Item -ItemType Directory -Path $wslDstItemPath -Force | Out-Null
        }

        # Get the contents of the directory
        $dirItems = Get-ChildItem -Path $wslSrcItemPath
        foreach ($subItem in $dirItems) {
            $wslSrcSubItemPath = $subItem.FullName
            $wslTmpSubItemPath = Join-Path -Path $wslTmpItemPath -ChildPath $subItem.Name

            # If subitem is also a directory
            if ($subItem.PSIsContainer) {
                # Recursively copy subdirectories
                $subItemsToProcess = @($subItem)
                while ($subItemsToProcess.Count -gt 0) {
                    $currentItem = $subItemsToProcess[0]
                    $subItemsToProcess = $subItemsToProcess[1..$subItemsToProcess.Count]

                    $wslSrcCurItemPath = $currentItem.FullName
                    $wslTmpCurItemPath = Join-Path -Path $wslTmpItemPath -ChildPath $currentItem.FullName.Substring($wslSrcItemPath.Length)

                    # If currentItem is a directory
                    if (Test-Path -Path $wslSrcCurItemPath -PathType Container) {
                        # Create directory if tmpCurrentItem does not exist
                        if (!(Test-Path -Path $wslTmpCurItemPath -PathType Container)) {
                            New-Item -ItemType Directory -Path $wslTmpCurItemPath -Force | Out-Null
                        }
                        $subItemsToProcess += Get-ChildItem -Path $wslSrcCurItemPath
                    } else {
                        # Else: currentItem is a file
                        Copy-Item -Path $wslSrcCurItemPath -Destination $wslTmpCurItemPath -Force
                        Write-Host "Copied $wslSrcCurItemPath -> $wslTmpCurItemPath"
                    }
                }
            } else {
                # Else: subItem is a file
                Copy-Item -Path $wslSrcSubItemPath -Destination $wslTmpSubItemPath
                Write-Host "Copied $wslSrcSubItemPath -> $wslTmpSubItemPath"
            }
        }
    } else {
        # Else: item is a file
        Copy-Item -Path $wslSrcItemPath -Destination $wslTmpItemPath
        Write-Host "Copied $wslSrcItemPath -> $wslTmpItemPath"
    }
}