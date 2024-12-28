# Define the function
function Install-WingetPackage {
    param (
        [string]$PackageName,
        [switch]$NoCheck
    )

    # Validate input
    if (-not $PackageName) {
        Write-Host "Usage: Install-WingetPackage -PackageName <winget-package-name> [-NoCheck | --no-check]"
        return
    }

    # Function to check if a package is installed using winget
    function IsPackageInstalled($packageName) {
        $packageList = winget list $packageName
        return $packageList -match "$packageName"
    }

    if (-not $NoCheck) {
        Write-Host "Checking if package is already installed: $PackageName"
        if (IsPackageInstalled $PackageName) {
            Write-Host "Package '$PackageName' is already installed."
            return
        }
    } else {
        Write-Host "Skipping package existence check (--no-check enabled)."
    }

    # Install specified package
    Write-Host "Installing winget package: $PackageName"
    Write-Host "> winget install -e --id $PackageName --silent --accept-package-agreements --accept-source-agreements"
    winget install -e --id $PackageName --silent --accept-package-agreements --accept-source-agreements
}

# Process script arguments
if ($args.Count -ge 1) {
    # Positional arguments passed
    $PackageName = $args[0]
    $NoCheck = ($args -contains "--no-check") -or ($args -contains "-NoCheck")
    Install-WingetPackage -PackageName $PackageName -NoCheck:$NoCheck
} else {
    # No arguments, show usage
    Write-Host "Usage: .\InstallWingetPkg.ps1 <winget-package-name> [-NoCheck | --no-check]"
}
