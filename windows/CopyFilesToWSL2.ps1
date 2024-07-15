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

# Copy each item from the source to the tmp destination
foreach ($item in $itemsToCopy) {
    $srcItemPath = Join-Path -Path $ubuntuSetupGeniePath -ChildPath $item
    $dstItemPath = Join-Path -Path $wslDestinationPathTmp -ChildPath $item

    # Check if item already exists
    if (Test-Path -Path $dstItemPath) {
        $confirmation = Read-Host "Item '$dstItemPath' already exists. Do you want to overwrite it? (y/n)"
        if ($confirmation -ne 'Y' -and $confirmation -ne 'y') {
            continue # skip copying
        } else {
            Remove-Item -Path $dstItemPath -Force -Recurse
        }
    }

    Copy-Item -Path $srcItemPath -Destination $dstItemPath -Recurse -Force
}
Write-Host "Files copied to WSL environment ($wslDistro) at '$wslDestinationPathTmp'"
