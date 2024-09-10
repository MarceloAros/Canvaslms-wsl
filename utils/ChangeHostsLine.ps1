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

    # Define la nueva línea que quieres agregar o modificar
    $newEntry = "$IP $DOMAIN"

    # Lee el contenido del archivo como un array de líneas
    $hostsContent = Get-Content -Path $FILE_PATH -Raw -Encoding UTF8 -ErrorAction Stop
    $hostsContentLines = $hostsContent -split "`r`n" # Dividimos el contenido en líneas usando CRLF

    # Verifica si ya existe una entrada con el dominio dado
    $lineExists = $false
    $updatedContent = @()

    foreach ($line in $hostsContentLines) {
        if ($line -match "$DOMAIN") {
            # Si encuentra la línea, la reemplaza
            $updatedContent += $newEntry
            $lineExists = $true
        } else {
            # Si no es la línea que buscas, mantenla intacta
            $updatedContent += $line
        }
    }

    if (-not $lineExists) {
        # Si no encontró ninguna entrada con el dominio, la añade al final
        $updatedContent += $newEntry
    }

    # Unimos las líneas en una sola cadena sin saltos de línea extra
    $updatedContentString = $updatedContent -join "`r`n"

    # Intentamos escribir el contenido actualizado en el archivo
    try {
        Start-Sleep -Seconds 2 # Pausa para evitar que el archivo esté en uso
        [System.IO.File]::WriteAllText($FILE_PATH, $updatedContentString, [System.Text.Encoding]::UTF8)
        Write-Host "El archivo hosts ha sido actualizado exitosamente." -ForegroundColor Green
    } catch {
        Write-Host "Error escribiendo el archivo: $_" -ForegroundColor Red
        exit 1
    }
}

end {
}