# Fixes the "No package found matching input criteria" issue
# Needs to be run with admin privileges
winget uninstall Microsoft.Winget.Source_8wekyb3d8bbwe
winget source reset --force
