# Get the absolute path of the parent directory of the script
$scriptPath = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
$topLevelPath = Split-Path -Parent -Path $scriptPath
$ubuntuPath = Join-Path -Path $topLevelPath -ChildPath "ubuntu"

# Define the array of accepted OS flags
$acceptedFlags = @(
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

# Check if the correct number of arguments is provided
if ($args.Count -ne 1) {
    Write-Host "Usage: .\CopyFilesToWSL.ps1 <OS flag>"
    Write-Host "Valid OS flags: $($acceptedFlags -join ', ')"
    return
}

# Retrieve the OS flag from command-line argument
$osFlag = $args[0]

# Check that a valid OS flag is specified
if ($osFlag -notin $acceptedFlags) {
    Write-Host "Invalid OS flag specified. Please use $($acceptedFlags -join ' or ')."
    return
}

# If osFlag is in acceptedFlags, then set wslDistribution to accepted flag
$wslDistribution = $osFlag

# Set the destination path based on the WSL distribution
$destinationLinuxPath = "/tmp/MyBuntu/"
$destinationPath = "\\wsl$\$wslDistribution\tmp\MyBuntu"

# Create the destination directory if it doesn't exist
if (!(Test-Path -Path $destinationPath -PathType Container)) {
    New-Item -ItemType Directory -Path $destinationPath | Out-Null
}

# Copy each item from the source to the destination
foreach ($item in $itemsToCopy) {
    $itemPath = Join-Path -Path $ubuntuPath -ChildPath $item
    $destinationItemPath = Join-Path -Path $destinationPath -ChildPath $item

    # Check if the item already exists in the destination and prompt for confirmation
    if (Test-Path -Path $destinationItemPath) {
        $confirmation = Read-Host "Item '$item' already exists in the destination. Do you want to remove it and overwrite? (y/n)"
        if ($confirmation -ne 'Y' -and $confirmation -ne 'y') {
            continue  # Skip copying the item if not confirmed
        } else {
            Remove-Item -Path $destinationItemPath -Force -Recurse
        }
    }

    # Copy the item to the destination
    Copy-Item -Path $itemPath -Destination $destinationItemPath -Recurse
}
Write-Host "Files copied to WSL environment '$wslDistribution' at '$destinationPath'."

# Set executable permissions for the setup.sh file
$setupShPath = $destinationLinuxPath + "setup.sh"
wsl -d $wslDistribution --cd / --user root --exec sh -c "chmod +x $setupShPath"

# Set executable permissions for all *.sh files in the /scripts/ directory
$scripts = $destinationLinuxPath + "scripts/*.sh"
$cmd = "chmod +x $scripts"
wsl -d $wslDistribution --cd / --user root --exec sh -c "$cmd"

$scripts = $destinationLinuxPath + "scripts/helper_scripts/*.sh"
$cmd = "chmod +x $scripts"
wsl -d $wslDistribution --cd / --user root --exec sh -c "$cmd"

# Output a message indicating the successful copy operation
Write-Host "Set correct file permissions."
