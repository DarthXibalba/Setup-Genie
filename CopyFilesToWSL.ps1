# Get the absolute path of the parent directory of the script
$scriptPath = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
$sourceDirectory = Join-Path -Path $scriptPath -ChildPath "..\"

# Define the array of accepted OS flags
$acceptedFlags = @(
    '--ubuntu-20.04',
    '--ubuntu-22.04'
)

# Define the array of items to copy
$itemsToCopy = @(
    "config\",
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

# Determine the distribution name based on the OS flag
$wslDistribution = ''
switch ($osFlag) {
    { $_ -eq $acceptedFlags[0] } {
        $wslDistribution = 'Ubuntu-20.04'
        break
    }
    { $_ -eq $acceptedFlags[1] } {
        $wslDistribution = 'Ubuntu-22.04'
        break
    }
}

# Set the destination path based on the WSL distribution
$destinationPath = "\\wsl$\$wslDistribution\tmp\MyBuntu"

# Create the destination directory if it doesn't exist
if (!(Test-Path -Path $destinationPath -PathType Container)) {
    New-Item -ItemType Directory -Path $destinationPath | Out-Null
}

# Copy each item from the source to the destination
foreach ($item in $itemsToCopy) {
    $itemPath = Join-Path -Path $sourceDirectory -ChildPath $item
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

# Output a message indicating the successful copy operation
Write-Host "Files copied to WSL environment '$wslDistribution' at '$destinationPath'."
