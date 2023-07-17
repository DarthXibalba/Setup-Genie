Param (
    [switch]$InstallWSL2,
    [switch]$SetDefaults,
    [switch]$Unregister,
    [switch]$UpdateWSL,
    [string]$distro = "Ubuntu-20.04"
)

# Setup Transcript Logging
$VerbosePreference = "Continue"
#$LogPath = Split-Path $MyInvocation.MyCommand.Path
#Get-ChildItem "$LogPath\*.log" | Where LastWriteTime -LT (Get-Date).AddDays(-15) | Remove-Item -Confirm:$false
#$LogPathName = Join-Path -Path $LogPath -ChildPath "$($MyInvocation.MyCommand.Name)-$(Get-Date -Format 'MM-dd-yyyy').log"
#Start-Transcript $LogPathName -Append

$scriptName = $MyInvocation.MyCommand.Name
Write-Verbose "Launching script: $scriptName"
Write-Verbose "Starting location: $LogPath"

function Install-WSL2 {
    Write-Verbose "$(Get-Date): Installing WSL2..."
    wsl --install -d $distro
    Write-Verbose "$(Get-Date): Installed WSL2!"
}

function Resync-Windows-Time {
    Write-Verbose "$(Get-Date): Re-Synchronizing Windows Time..."
    net stop w32time
    w32tm /unregister
    w32tm /register
    net start w32time
    w32tm /resync /nowait
    Write-Verbose "$(Get-Date): Re-Sync done!"
}

function Set-WSL2-Defaults {
    Write-Verbose "$(Get-Date): Setting Defaults for WSL2..."
    wsl --set-default-version 2
    wsl --setdefault $distro
    wsl --set-version $distro 2
    Write-Verbose "$(Get-Date): Set Defaults for WSL2!"
}

function Unregister-Distro {
    Write-Verbose "$(Get-Date): Unregistering distro: $distro"
    wsl --unregister $distro
    Write-Verbose "$(Get-Date): Unregistered distro!"
}

function Update-WSL {
    Write-Verbose "$(Get-Date): Updating WSL!"
    wsl --update
    Write-Verbose "$(Get-Date): Updated WSL!"
}

# Main
if ($InstallWSL2) {
    Resync-Windows-Time
    Install-WSL2
}
if ($SetDefaults) {
    Set-WSL2-Defaults
}
if ($Unregister) {
    Unregister-Distro
}
if ($UpdateWSL) {
    Update-WSL
}