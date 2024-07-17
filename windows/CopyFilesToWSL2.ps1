# Define Functions
function Create-DirectoryIfDoesNotExist {
    param (
        [string]$DirPath
    )
    if (!(Test-Path -Path $DirPath -PathType Container)) {
        New-Item -ItemType Directory -Path $DirPath -Force | Out-Null
        Write-Host "Created directory $DirPath"
    }
}

# SrcPath & TmpPath must be Windows paths
# DstPath must be a Linux Path
function Copy-ModifyItem {
    param (
        [string]$SrcPath,
        [string]$TmpPath
    )
    Copy-Item -Path $SrcPath -Destination $TmpPath -Force
    Write-Host "Copied $SrcPath -> $TmpPath"
}

function Remove-ItemIfExists {
    param (
        [string]$ItemPath
    )
    if (Test-Path -Path $ItemPath) {
        Remove-Item -Path $ItemPath -Force -Recurse
        Write-Host "Removed $ItemPath"
    }
}

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

# Create destination directories
Create-DirectoryIfDoesNotExist -DirPath $wslDestinationPathTmp
Create-DirectoryIfDoesNotExist -DirPath $wslDestinationPathFinal

# Copy each individual item from the source to the tmp destination, then chmod if needed (scripts only)
# and finally, remove carriage returns and move to final destination
foreach ($item in $itemsToCopy) {
    $wslSrcItemPath = Join-Path -Path $ubuntuSetupGeniePath -ChildPath $item
    $wslTmpItemPath = Join-Path -Path $wslDestinationPathTmp -ChildPath $item
    $wslDstItemPath = Join-Path -Path $wslDestinationPathFinal -ChildPath $item

    # Force override by removing items that exist in destination
    Remove-ItemIfExists -ItemPath $wslTmpItemPath
    Remove-ItemIfExists -ItemPath $wslDstItemPath

    # If src item is a directory
    if (Test-Path -Path $wslSrcItemPath -PathType Container) {
        Create-DirectoryIfDoesNotExist -DirPath $wslTmpItemPath
        Create-DirectoryIfDoesNotExist -DirPath $wslDstItemPath

        # Get the contents of the directory
        $dirItems = Get-ChildItem -Path $wslSrcItemPath
        foreach ($subItem in $dirItems) {
            $wslSrcSubItemPath = $subItem.FullName
            $wslTmpSubItemPath = Join-Path -Path $wslTmpItemPath -ChildPath $subItem.Name

            # If subItem is also a directory
            if ($subItem.PSIsContainer) {
                # Recursively copy subdirectories
                $subItemsToProcess = @($subItem)
                while ($subItemsToProcess.Count -gt 0) {
                    $currentItem = $subItemsToProcess[0]
                    $subItemsToProcess = $subItemsToProcess[1..$subItemsToProcess.Count]

                    $wslSrcCurItemPath = $currentItem.FullName
                    $wslTmpCurItemPath = Join-Path -Path $wslTmpItemPath -ChildPath $currentItem.FullName.Substring($wslSrcItemPath.Length)
                    $wslDstCurItemPath = Join-Path -Path $wslDstItemPath -ChildPath $currentItem.FullName.Substring($wslSrcItemPath.Length)

                    # If currentItem is a directory
                    if (Test-Path -Path $wslSrcCurItemPath -PathType Container) {
                        Create-DirectoryIfDoesNotExist -DirPath $wslTmpCurItemPath
                        Create-DirectoryIfDoesNotExist -DirPath $wslDstCurItemPath
                        $subItemsToProcess += Get-ChildItem -Path $wslSrcCurItemPath
                    } else {
                        # Else: currentItem is a file
                        Copy-ModifyItem -SrcPath $wslSrcCurItemPath -TmpPath $wslTmpCurItemPath
                    }
                }
            } else {
                # Else: subItem is a file
                Copy-ModifyItem -SrcPath $wslSrcSubItemPath -TmpPath $wslTmpSubItemPath
            }
        }
    } else {
        # Else: item is a file
        Copy-ModifyItem -SrcPath $wslSrcItemPath -TmpPath $wslTmpItemPath
    }
}