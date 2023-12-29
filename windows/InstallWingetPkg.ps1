# Suggested Use
# .\InstallWingetPkg.ps1 <winget-package-name>

# Get the absolute path of the parent directory of the script
$scriptPath = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
$topLevelPath = Split-Path -Parent -Path $scriptPath

# Check if the correct number of arguments is provided
if ($args.Count -ne 1) {
    Write-Host "Usage: .\InstallWingetPkg.ps1 <winget-package-name>"
    return
}

# Retrieve the winget package name from command-line argument
$packageName = $args[0]

# Function to check if a package is installed using winget
function IsPackageInstalled($packageName) {
    $packageList = winget list $packageName
    return $packageList -match "$packageName"
}

# Install specified package
Write-Host "Installing winget package: $packageName"
Write-Host "> winget install -e --id $packageName --silent --accept-package-agreements --accept-source-agreements"
winget install -e --id $packageName --silent --accept-package-agreements --accept-source-agreements
