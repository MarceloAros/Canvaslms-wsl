# file name: Canvas create WSL Enviroment

$customDistroName = "canvas-ubuntu"
$urlFrom = "https://cloud-images.ubuntu.com/wsl/releases/jammy/current/ubuntu-jammy-wsl-amd64-wsl.rootfs.tar.gz"
$rootfsFile = ".\utils\ubuntu-jammy-wsl-amd64-wsl.rootfs.tar.gz"
$folderDisk = ".\diskfolder"
$customUserName = "canvas"
$customuserPassword = "hola"
$root_password = "hola"
$customDomain = "canvas.local"

if (Test-Path $rootfsFile) {
    Write-Host "The rootfs file exists, used existing."
} else {
    Write-Host "Downloading the rootfs file... " -NoNewline
    # Download Ubuntu 22.04
    Invoke-WebRequest -Uri $urlFrom -OutFile $rootfsFile -UseBasicPars
    Write-Host "OK" -ForegroundColor Green
}
#The disk already exists. To Destroy the disk and reinstall, type "Destroy", to continue press

$isExistFolderDisk = $false 
if (Test-Path $folderDisk) {
    $isExistFolderDisk = $true
    Write-Host "The folder for the disk exists. To reinstall, delete it and run the script again."
    # TODO: Destroy distro via script
    $userDestoyInput = Read-Host "Write 'Destroy' to delete distro $customDistroName" -

    if ($userDestoyInput -eq "Destroy") {
        wsl --unregister $customDistroName
        Remove-Item -Path $folderDisk -Recurse
        Write-Host "OK" -ForegroundColor Green
        $isExistFolderDisk = $false 
    }
    
}

if ($isExistFolderDisk -eq $false) {
    Write-Host "Creating folder for disk in $folderDisk... " -NoNewline
    mkdir $folderDisk
    Write-Host "Creating folder for disk in $folderDisk... OK" -ForegroundColor Green

    # Create WSL Distro: Ubuntu 22.04
    Write-Host "Creating Wsl Distro..." -NoNewline
    .\utils\CreateLinuxDistro.ps1 -INPUT_FILENAME $rootfsFile -OUTPUT_DIRNAME $folderDisk -OUTPUT_DISTRONAME $customDistroName -CREATE_USER 1 -CREATE_USER_USERNAME $customUserName -CREATE_USER_PASSWORD $customuserPassword -ADD_USER_TO_GROUP 1 -ADD_USER_TO_GROUP_NAME sudo -SET_USER_AS_DEFAULT $customUserName -ROOT_PASSWORD $root_password
    Write-Host "Creating Wsl Distro...OK" -ForegroundColor Green

    # Copy bash script
    Copy-Item ".\install-canvas.sh" "\\wsl$\$customDistroName\home\$customUserName\"

    # Copy configs
    Copy-Item -Path ".\configs" -Destination "\\wsl$\$customDistroName\home\$customUserName\" -Recurse

    wsl -d $customDistroName /bin/bash -c "sudo chmod +x /home/canvas/install-canvas.sh && sudo /home/$customUserName/install-canvas.sh $customUserName $customuserPassword"

    .\run.ps1
}