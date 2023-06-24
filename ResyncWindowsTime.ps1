function Resync-Windows-Time {
    Write-Host "Re-Synchronizing Windows Time..."
    net stop w32time
    w32tm /unregister
    w32tm /register
    net start w32time
    w32tm /resync /nowait
    Write-Host "Re-Sync done!"
}

Resync-Windows-Time
