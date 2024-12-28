function Configure-Git {
    param (
        [string]$Mode,
        [PSCustomObject]$ConfigContent
    )

    # Access the selected configuration
    $config = $ConfigContent.$Mode
    if (-not $config) {
        Write-Host "Unknown mode specified: $Mode"
        exit 1
    }

    # Extract configuration values
    $USERNAME = $config.USERNAME
    $EMAIL = $config.EMAIL
    $PAT = $config.PAT

    # Ensure required keys are present
    if (-not $USERNAME -or -not $EMAIL -or -not $PAT) {
        Write-Host "Incomplete configuration for mode: $Mode. Please check the config file."
        exit 1
    }

    # Configure Git
    Write-Host "Configuring Git for mode: $Mode"

    git config --global user.name "$USERNAME"
    git config --global user.email "$EMAIL"
    git config --global credential.helper store

    if ($Mode -eq 'work') {
        git config --global --add url."https://$PAT@github.azc.ext.hp.com".insteadOf "https://github.azc.ext.hp.com"
    } else {
        git config --global --add url."https://$PAT@github.com".insteadOf "https://github.com"
    }

    Write-Host "Git configuration updated successfully for mode: $Mode."
}

# Main Script Logic
# Get the absolute path of the parent directory of the script
$scriptPath = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
$configPath = Join-Path -Path $scriptPath -ChildPath "../ubuntu/config/gitconfig.json"

# Check if config file exists
if (-not (Test-Path -Path $configPath)) {
    Write-Host "Config file not found at: $configPath"
    exit 1
}

# Read the contents of the config file
$configContent = Get-Content -Path $configPath -Raw | ConvertFrom-Json

# Validate mode argument
if ($Args.Count -ne 1) {
    Write-Host "Invalid usage. Please provide exactly one argument."
    Write-Host "Usage: .\ConfigureGitUser.ps1 [ personal | work ]"
    exit 1
}

$Mode = $Args[0]
if ($Mode -notin @('personal', 'work')) {
    Write-Host "Invalid argument: $Mode"
    Write-Host "Usage: .\ConfigureGitUser.ps1 [ personal | work ]"
    exit 1
}

# Call the Configure-Git function
Configure-Git -Mode $Mode -ConfigContent $configContent
