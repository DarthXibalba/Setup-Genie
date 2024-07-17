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
$WslDistro = $args[0]
if ($WslDistro -notin $acceptedWSLDistros) {
    Write-Host "Invalid WSL Distro specified. Please use exactly one of the follwoing: { $($acceptedWSLDistros -join ' | ') }"
    Write-Host "Example: .\CopyFilesToWSL2.ps1 <WSL Distro>"
    return
}

# ----- ----- ----- Setup Global Variables ----- ----- ----- #

# Get the absolute path of the parent directory of the script
$ScriptPath = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
$TopLevelPath = Split-Path -Parent -Path $ScriptPath
$UbuntuSetupGeniePath = Join-Path -Path $TopLevelPath -ChildPath "ubuntu"

# Set the destination paths for both WSL & Native Linux
$LinuxDestinationPathTmp = "/tmp/Setup-Genie-tmp"
$LinuxDestinationPathFinal = "/tmp/Setup-Genie"
$WslDistroPath = "\\wsl$\$WslDistro"
$WslDestinationPathTmp = Join-Path -Path $WslDistroPath -ChildPath ($LinuxDestinationPathTmp -replace "/", "\")
$WslDestinationPathFinal = Join-Path -Path $WslDistroPath -ChildPath ($LinuxDestinationPathFinal -replace "/", "\")

$LinuxCarriageReturnScript = "/tmp/remove-carriage-returns.sh"
$LinuxCarriageReturnScriptTmp = "/tmp/remove-carriage-returns-tmp.sh"
$WslCarriageReturnScriptTmp = Join-Path -Path $WslDistroPath -ChildPath ($LinuxCarriageReturnScriptTmp -replace "/", "\")
$WindowsCarriageReturnScript = Join-Path -Path $UbuntuSetupGeniePath -ChildPath "scripts/helper-scripts/remove-carriage-returns.sh"

# ----- ----- ----- Define Functions ----- ----- ----- #
function Cleanup-Environment {
    Remove-ItemIfExists $WslDestinationPathTmp
    Exec-InWslDistro -Cmd "rm -rf $LinuxCarriageReturnScript"
    Exec-InWslDistro -Cmd "rm -rf $LinuxCarriageReturnScriptTmp"
}

function Copy-ModifyItem {
    param (
        [string]$WinSrcPath,
        [string]$WinTmpPath,
        [string]$LnxTmpPath,
        [string]$LnxDstPath
    )
    # Copy item
    Copy-Item -Path $WinSrcPath -Destination $WinTmpPath -Force
    Write-Host "Copied $WinSrcPath -> $WinTmpPath"
    # Remove-Carriages
    if ($WinSrcPath -notlike "*.deb") {
        Exec-InWslDistro -Cmd "$LinuxCarriageReturnScript $LnxTmpPath $LnxDstPath"
    } else {
        Exec-InWslDistro -Cmd "cp $LnxTmpPath $LnxDstPath"
    }
    # Chmod (if applicable)
    if ($WinSrcPath -like "*.sh") {
        Exec-InWslDistro -Cmd "chmod +x $LnxDstPath"
    }
}

function Create-DirectoryIfDoesNotExist {
    param (
        [string]$DirPath
    )
    if (!(Test-Path -Path $DirPath -PathType Container)) {
        New-Item -ItemType Directory -Path $DirPath -Force | Out-Null
        Write-Host "Created directory $DirPath"
    }
}

function Exec-InWslDistro {
    param (
        [string]$Cmd,
        [string]$Distro = $WslDistro
    )
    Write-Host "Executing cmd: $Cmd"
    wsl -d $Distro --cd / --user root --exec sh -c "$Cmd"
}

function Prepare-Environment {
    Cleanup-Environment

    Copy-Item -Path $WindowsCarriageReturnScript -Destination $WslCarriageReturnScriptTmp -Force
    Exec-InWslDistro -Cmd "tr -d '\r' < `"$LinuxCarriageReturnScriptTmp`" > `"$LinuxCarriageReturnScript`""
    Exec-InWslDistro -Cmd "chmod +x $LinuxCarriageReturnScript"

    Create-DirectoryIfDoesNotExist -DirPath $WslDestinationPathTmp
    Create-DirectoryIfDoesNotExist -DirPath $WslDestinationPathFinal
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

# ----- ----- ----- Main ----- ----- ----- #
Prepare-Environment

# Copy each individual item from the source to the tmp destination, then chmod if needed (scripts only)
# and finally, remove carriage returns and move to final destination
foreach ($item in $itemsToCopy) {
    $wslSrcItemPath = Join-Path -Path $UbuntuSetupGeniePath -ChildPath $item
    $wslTmpItemPath = Join-Path -Path $WslDestinationPathTmp -ChildPath $item
    $wslDstItemPath = Join-Path -Path $WslDestinationPathFinal -ChildPath $item
    $itemName = $item.TrimEnd('\')
    $lnxTmpItemPath = "$LinuxDestinationPathTmp/$itemName"
    $lnxDstItemPath = "$LinuxDestinationPathFinal/$itemName"

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
            $subItemName = $subItem.Name
            $subItemName = $subItemName.TrimEnd('\')
            $lnxTmpSubItemPath = "$lnxTmpItemPath/$subItemName"
            $lnxDstSubItemPath = "$lnxDstItemPath/$subItemName"

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
                    $curItemName = $currentItem.Name
                    $curItemName = $curItemName.TrimEnd('\')
                    $lnxTmpCurItemPath = "$lnxTmpItemPath/$curItemName"
                    $lnxDstCurItemPath = "$lnxDstItemPath/$curItemName"

                    # If currentItem is a directory
                    if (Test-Path -Path $wslSrcCurItemPath -PathType Container) {
                        Create-DirectoryIfDoesNotExist -DirPath $wslTmpCurItemPath
                        Create-DirectoryIfDoesNotExist -DirPath $wslDstCurItemPath
                        $subItemsToProcess += Get-ChildItem -Path $wslSrcCurItemPath
                    } else {
                        # Else: currentItem is a file
                        Copy-ModifyItem -WinSrcPath $wslSrcCurItemPath -WinTmpPath $wslTmpCurItemPath -LnxTmpPath $lnxTmpCurItemPath -LnxDstPath $lnxDstCurItemPath
                    }
                }
            } else {
                # Else: subItem is a file
                Copy-ModifyItem -WinSrcPath $wslSrcSubItemPath -WinTmpPath $wslTmpSubItemPath -LnxTmpPath $lnxTmpSubItemPath -LnxDstPath $lnxDstSubItemPath
            }
        }
    } else {
        # Else: item is a file
        Copy-ModifyItem -WinSrcPath $wslSrcItemPath -WinTmpPath $wslTmpItemPath -LnxTmpPath $lnxTmpItemPath -LnxDstPath $lnxDstItemPath
    }
}

# Cleanup before exiting
Cleanup-Environment
