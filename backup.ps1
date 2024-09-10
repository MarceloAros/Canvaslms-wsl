# Function to load configuration from config.json
function Load-ConfigFile {
    param (
        [string]$ConfigPath
    )
    if (Test-Path $ConfigPath) {
        return Get-Content -Path $ConfigPath | ConvertFrom-Json
    } else {
        Write-Host "Configuration file not found." -ForegroundColor Red
        exit 1
    }
}

# Function to export a WSL distribution
function Export-Distribution {
    param (
        [string]$DistroName,
        [string]$ExportPath
    )
    
    $timestamp = Get-Date -Format "yyyyMMdd-HHmm"
    $exportFileName = "$timestamp.tar"
    $exportFilePath = Join-Path -Path $ExportPath -ChildPath $exportFileName
    
    Write-Host "Exporting distribution '$DistroName' to '$exportFilePath'..."
    wsl --export $DistroName $exportFilePath
    Write-Host "Export completed."
}

# Function to import a WSL distribution
function Import-Distribution {
    param (
        [string]$DistroName,
        [string]$ImportPath
    )
    
    # Confirmation before deleting the existing distribution
    $confirmation = Read-Host "Type 'Destroy' to confirm the deletion of the existing distribution"
    if ($confirmation -eq 'Destroy') {
        Write-Host "Deleting distribution '$DistroName'..."
        wsl --unregister $DistroName
        Write-Host "Distribution deleted."
        
        # Show list of .tar files for import
        $tarFiles = Get-ChildItem -Path $ImportPath -Filter "*.tar"
        if ($tarFiles.Count -eq 0) {
            Write-Host "No .tar files found in the import directory." -ForegroundColor Red
            exit 1
        }
        
        Write-Host "Available .tar files for import:"
        $tarFiles | ForEach-Object { Write-Host "$($_.Name)" }
        
        $selectedFile = Read-Host "Select the .tar file for import (type the filename)"
        $selectedFilePath = Join-Path -Path $ImportPath -ChildPath $selectedFile
        
        if (Test-Path $selectedFilePath) {
            Write-Host "Importing distribution from '$selectedFilePath'..."
            wsl --import $DistroName $selectedFilePath
            Write-Host "Import completed."
        } else {
            Write-Host "Selected file does not exist." -ForegroundColor Red
            exit 1
        }
    } else {
        Write-Host "Confirmation not received. Import operation has been cancelled." -ForegroundColor Yellow
    }
}

# Path to the configuration file
$configPath = ".\config.json"
$config = Load-ConfigFile -ConfigPath $configPath
$distroName = $config.distribution.custom_name

# Menu options
function Show-Menu {
    Write-Host "Select an option:"
    Write-Host "1. Export WSL distribution"
    Write-Host "2. Import WSL distribution"
    Write-Host "3. Exit"
}

while ($true) {
    Show-Menu
    $choice = Read-Host "Enter the option number (default 3 to exit)"
    
    switch ($choice) {
        1 {
            Export-Distribution -DistroName $distroName -ExportPath ".\utils\distro-backup"
        }
        2 {
            Import-Distribution -DistroName $distroName -ImportPath ".\utils\distro-backup"
        }
        3 {
            Write-Host "Exiting..." -ForegroundColor Green
            break
        }
        default {
            Write-Host "Invalid option. Exiting by default." -ForegroundColor Yellow
            break
        }
    }
}