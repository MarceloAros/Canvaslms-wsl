<#
.SYNOPSIS
    Change a line in hosts file
.EXAMPLE
    ChangeHosts.ps1 -FILE_PATH "C:\windows\system32\drivers\etc\hosts" -IP "172.0.0.1" -DOMAIN "domain.local"
.INPUTS
    Help needed here!
.OUTPUTS
    Help needed here!
.NOTES
    Help needed here!
.COMPONENT
    Help needed here!
.ROLE
    Help needed here!
.FUNCTIONALITY
    Help needed here!
#>

[CmdletBinding(DefaultParameterSetName = 'Parameter Set 1',
    SupportsShouldProcess = $true,
    PositionalBinding = $false,
    ConfirmImpact = 'Medium')]
[Alias()]
[OutputType([String])]
Param (
    # File Path
    [Parameter(
        Mandatory = $true,
        Position = 0,
        ValueFromPipeline = $true,
        ValueFromPipelineByPropertyName = $true,
        ValueFromRemainingArguments = $false)]
    [ValidateNotNull()]
    [System.IO.FileInfo]
    $FILE_PATH,

    # IP to set
    [Parameter(
        Mandatory = $true,
        ValueFromPipeline = $true,
        ValueFromRemainingArguments = $false)]
    [ValidateNotNull()]
    [ValidateNotNullOrEmpty()]
    $IP,

    # Domain to set
    [Parameter(
        Mandatory = $true,
        ValueFromPipeline = $true,
        ValueFromRemainingArguments = $false)]
    [ValidateNotNull()]
    [ValidateNotNullOrEmpty()]
    $DOMAIN
)

begin {
}

process {

    if (-not (Test-Path $FILE_PATH)) {
        Write-Host "El archivo hosts no se encontró o no se tiene permisos de acceso." -ForegroundColor Red
        exit 1
    }

    $hostsContent = Get-Content $FILE_PATH

    # Check if there is any line that contains the customDomain
    $domainLineIndex = $hostsContent | Select-String -Pattern "\s+$DOMAIN" | ForEach-Object { $_.LineNumber - 1 }

    if ($domainLineIndex -ne $null) {
        # If a line exists with the domain, it replaces it with the correct IP
        Write-Host "The domain $DOMAIN already exists, updating the IP..."
        $hostsContent[$domainLineIndex] = "$IP $DOMAIN"
    } else {
        # If it does not exist, add a new line to the end of the file
        Write-Host "The domain $DOMAIN does not exist, adding new entry..."
        $hostsContent += "$IP $DOMAIN"
    }

    # Write the updated content to the hosts file 
    Set-Content -Path $FILE_PATH -Value $hostsContent -Force

    Write-Host "Domain $DOMAIN added or updated in the hosts file." -ForegroundColor Green

    # Confirmar el cambio
    Write-Host "Current hosts file content:"
    Get-Content $FILE_PATH | Out-String
}

end {
}
