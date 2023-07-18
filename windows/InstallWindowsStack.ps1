# Get the absolute path of the parent directory of the script
$scriptPath = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
$configPath = Join-Path -Path $scriptPath -ChildPath "config/windows_stack.json"

# Read the contents of the config file
$configContent = Get-Content -Path $configPath -Raw | ConvertFrom-Json

# Access and use the configuration values
$required = $configContent.REQUIRED
$optional = $configContent.OPTIONAL

# Function to check if a package is installed using winget
function IsPackageInstalled($packageName) {
    $packageList = winget list $packageName
    return $packageList -match "$packageName"
}

# Iterate over required values and install the required items if not already installed
foreach ($requiredItem in $required) {
    if (!(IsPackageInstalled $requiredItem)) {
        Write-Host "Installing required item: $requiredItem"
        winget install -e --id $requiredItem --silent --accept-package-agreements --accept-source-agreements
    }
    else {
        Write-Host "Required item $requiredItem is already installed"
    }
}

# Iterate over optional values and prompt the user for confirmation
foreach ($optionalItem in $optional) {
    if (!(IsPackageInstalled $optionalItem)) {
        $installOptional = Read-Host "Do you want to install the optional item: $optionalItem ? (Y/N)"
        if ($installOptional -eq "Y" -or $installOptional -eq "y") {
            Write-Host "Installing optional item: $optionalItem"
            winget install -e --id $optionalItem --silent --accept-package-agreements --accept-source-agreements
        }
    }
    else {
        Write-Host "Optional item $optionalItem is already installed"
    }
}
