# file name: Canvas create WSL Enviroment

# Check if the script is running as administrator
function Test-IsElevated {
    $identity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object System.Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Get the path of the current script
$scriptPath = $MyInvocation.MyCommand.Path
$scriptDirectory = Split-Path -Path $scriptPath -Parent

# Run the script with administrator privileges if it is not running as administrator
if (-not (Test-IsElevated)) {
    # Create an object to restart the script with elevated privilegess
    $arguments = "& '$scriptPath' " + [string]::Join(' ', $args)
    Start-Process powershell -ArgumentList $arguments -Verb runAs
    exit
}
# The rest of the script will run with elevated permissions here
Write-Host "Administrator privileges successfully granted." -ForegroundColor Green

Set-Location $scriptDirectory

$config = Get-Content -Raw -Path ".\config.json" | ConvertFrom-Json

$windowsIpv4 = (Get-NetIPAddress -InterfaceAlias "*WSL*" -AddressFamily IPv4).IPAddress
$wslIpv4 = (wsl -d $config.distribution.custom_name hostname -I)

# canvas_lms set custom domain
## WSL
Copy-Item -Path "\\wsl$\$($config.distribution.custom_name)\etc\hosts" -Destination ".\hosts" -Force
$wslPath = ((Resolve-Path ".\hosts") -replace '\\', '/' -replace '^C:', '/mnt/c')
.\utils\ChangeHostsLine.ps1 -FILE_PATH .\hosts -IP "127.0.0.1" -DOMAIN "$($config.canvas_lms.custom_domain)"
## Windows
.\utils\ChangeHostsLine.ps1 -FILE_PATH "C:\Windows\System32\drivers\etc\hosts" -IP "$wslIpv4" -DOMAIN "$($config.canvas_lms.custom_domain)"

Start-Sleep -Seconds 2

# lti_tool set custom domain
.\utils\ChangeHostsLine.ps1 -FILE_PATH .\hosts -IP "$windowsIpv4" -DOMAIN "$($config.lti_tool.custom_domain)"
Start-Sleep -Seconds 1
wsl -d $config.distribution.custom_name /bin/bash -c "sudo cp $wslPath /etc/hosts"
## Windows
.\utils\ChangeHostsLine.ps1 -FILE_PATH "C:\Windows\System32\drivers\etc\hosts" -IP "127.0.0.1" -DOMAIN "$($config.lti_tool.custom_domain)"

Remove-Item -Path ".\hosts" -Force

# start canvas related services
wsl -d $config.distribution.custom_name /bin/bash -c "sudo mkdir -p /var/run/passenger-instreg && sudo chown -R www-data:www-data /var/run/passenger-instreg && sudo service postgresql start && sudo service redis-server start && sudo service apache2 start && sudo service canvas_init start"

# Login into distro
wsl -d $($config.distribution.custom_name)
