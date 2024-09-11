# file name: Canvas create WSL Enviroment

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

$config = Load-ConfigFile -ConfigPath ".\config.json"


if (Test-Path $($config.distribution.rootfs_file)) {
    Write-Host "The rootfs file exists, used existing."
} else {
    Write-Host "Downloading the rootfs file... " -NoNewline
    # Download Ubuntu 22.04
    Invoke-WebRequest -Uri $($config.distribution.url_download_rootfs) -OutFile $($config.distribution.rootfs_file) -UseBasicPars
    Write-Host "OK" -ForegroundColor Green
}
#The disk already exists. To Destroy the disk and reinstall, type "Destroy", to continue press

$isExistFolderDisk = $false 
if (Test-Path $($config.distribution.disk_folder)) {
    $isExistFolderDisk = $true
    Write-Host "The folder for the disk exists. To reinstall, delete it and run the script again."
    # TODO: Destroy distro via script

    Write-Host "To reinstall the distro type '" -NoNewline 
    Write-Host "Destroy" -NoNewline -ForegroundColor DarkYellow -BackgroundColor Red 
    Write-Host "'."
    Write-Host "To continue using the distro, " -NoNewline 
    Write-Host "skip" -ForegroundColor White -BackgroundColor Green -NoNewline
    Write-Host " this message."
    Write-Host "Then press enter" -NoNewline 
    $userDestoyInput = Read-Host :

    if ($userDestoyInput -eq "Destroy") {
        wsl --unregister $($config.distribution.custom_name)
        Remove-Item -Path $($config.distribution.disk_folder) -Recurse
        Write-Host "OK" -ForegroundColor Green
        $isExistFolderDisk = $false 
    }
    
}

if ($isExistFolderDisk -eq $false) {
    Write-Host "Creating folder for disk in $($config.distribution.disk_folder)... " -NoNewline
    mkdir $($config.distribution.disk_folder)
    Write-Host "Creating folder for disk in $($config.distribution.disk_folder)... OK" -ForegroundColor Green

    # Create WSL Distro: Ubuntu 22.04
    Write-Host "Creating Wsl Distro..." -NoNewline
    .\utils\CreateLinuxDistro.ps1 -INPUT_FILENAME $($config.distribution.rootfs_file) -OUTPUT_DIRNAME $($config.distribution.disk_folder) -OUTPUT_DISTRONAME $($config.distribution.custom_name) -CREATE_USER 1 -CREATE_USER_USERNAME $($config.distribution.user_name) -CREATE_USER_PASSWORD $($config.distribution.user_password) -ADD_USER_TO_GROUP 1 -ADD_USER_TO_GROUP_NAME sudo -SET_USER_AS_DEFAULT $($config.distribution.user_name) -ROOT_PASSWORD $($config.distribution.root_password)
    Write-Host "Creating Wsl Distro...OK" -ForegroundColor Green

    # Copy bash script
    Copy-Item ".\install-canvas.sh" "\\wsl$\$($config.distribution.custom_name)\home\$($config.distribution.user_name)\"

    # Copy configs
    Copy-Item -Path ".\configs" -Destination "\\wsl$\$($config.distribution.custom_name)\home\$($config.distribution.user_name)\" -Recurse

    wsl -d $($config.distribution.custom_name) /bin/bash -c "sudo chmod +x /home/canvas/install-canvas.sh && sudo /home/$($config.distribution.user_name)/install-canvas.sh $($config.distribution.user_name) $($config.distribution.user_password)"

    .\run.ps1
}