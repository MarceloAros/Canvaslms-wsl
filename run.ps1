# file name: Canvas create WSL Enviroment

$config = Get-Content ".\config.json" | ConvertFrom-Json

$windowsIpv4 = (Get-NetIPAddress -InterfaceAlias "*WSL*" -AddressFamily IPv4).IPAddress
$wslIpv4 = (wsl -d canvas-ubuntu hostname -I)

# set canvas_lms custom domain
.\utils\ChangeHostsLine.ps1 -FILE_PATH "\\wsl$\$config.distrubution.custom_name\etc\hosts" -IP "127.0.0.1" -DOMAIN "$config.canvas_lms.custom_domain"
.\utils\ChangeHostsLine.ps1 -FILE_PATH "C:\Windows\System32\drivers\etc\hosts" -IP "$wslIpv4" -DOMAIN "$config.canvas_lms.custom_domain"

# set lti_tool custom domain
.\utils\ChangeHostsLine.ps1 -FILE_PATH "\\wsl$\$config.distrubution.custom_name\etc\hosts" -IP "$windowsIpv4" -DOMAIN "$config.lti_tool.custom_domain"
.\utils\ChangeHostsLine.ps1 -FILE_PATH "C:\Windows\System32\drivers\etc\hosts" -IP "127.0.0.1" -DOMAIN "$config.canvas_lms.custom_domain"´

# start canvas related services
wsl -d $config.distribution.custom_name /bin/bash -c "sudo mkdir -p /var/run/passenger-instreg \
  && sudo chown -R www-data:www-data /var/run/passenger-instreg \
  && sudo service postgresql start \
  && sudo service redis-server start \
  && sudo service apache2 start \
  && sudo service canvas_init start"


wsl -d $config.distribution.custom_name 
