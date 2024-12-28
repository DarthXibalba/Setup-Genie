# Suggested Use
# .\InstallWindowsStack.ps1

# Get the absolute path of the parent directory of the script
$scriptPath = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
$configPath = Join-Path -Path $scriptPath -ChildPath "config/windows_stack.json"
$helperScriptPath = Join-Path -Path $scriptPath -ChildPath "./helper-scripts/InstallWingetPkg.ps1"

Write-Host "Installing Windows Stack!"
Write-Host "scriptPath = $scriptPath"
Write-Host "configPath = $configPath"

# Import the InstallWingetPkg.ps1 script to access Install-WingetPackage
. $helperScriptPath

# Read the contents of the config file
$configContent = Get-Content -Path $configPath -Raw | ConvertFrom-Json

# Access and use the configuration values
$required = $configContent.REQUIRED
$optional = $configContent.OPTIONAL
Write-Host "required pkgs = [$required]"
Write-Host "optional pkgs = [$optional]"

# Load the winget list output once into a variable
Write-Host "Loading installed packages using winget..."
$wingetList = winget list

# Function to check if a package is installed using the cached winget list
function IsPackageInstalled($packageName) {
    # Check if the package name exists in the cached winget list
    return $wingetList | Select-String -SimpleMatch $packageName
}

# Iterate over required values and install the required items if not already installed
Write-Host "Installing required packages"
foreach ($requiredItem in $required) {
    if (!(IsPackageInstalled $requiredItem)) {
        Install-WingetPackage -PackageName $requiredItem -NoCheck
    }
    else {
        Write-Host "Required item $requiredItem is already installed"
    }
}

# Iterate over optional values and prompt the user for confirmation
Write-Host "Installing optional packages"
foreach ($optionalItem in $optional) {
    if (!(IsPackageInstalled $optionalItem)) {
        $installOptional = Read-Host "Do you want to install the optional item: $optionalItem ? (Y/N)"
        if ($installOptional -eq "Y" -or $installOptional -eq "y") {
            Install-WingetPackage -PackageName $optionalItem -NoCheck
        }
    }
    else {
        Write-Host "Optional item $optionalItem is already installed"
    }
}
