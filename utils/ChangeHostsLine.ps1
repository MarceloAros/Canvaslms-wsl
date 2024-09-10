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
        Write-Host "The hosts file was not found or you do not have access permissions." -ForegroundColor Red
        exit 1
    }

    # Define the new line you want to add or modify
    $newEntry = "$IP $DOMAIN"

    # Reads the contents of the file as an array of lines
    $hostsContent = Get-Content -Path $FILE_PATH -Raw -Encoding UTF8 -ErrorAction Stop
    $hostsContentLines = $hostsContent -split "`r`n" # Split the content into lines using CRLF

    # Checks if an entry with the given domain already exists
    $lineExists = $false
    $updatedContent = @()

    foreach ($line in $hostsContentLines) {
        if ($line -match "$DOMAIN") {
            # If it finds the line, it replaces it
            $updatedContent += $newEntry
            $lineExists = $true
        } else {
            # If it is not the wanted line, keep it intact
            $updatedContent += $line
        }
    }

    if (-not $lineExists) {
        # If it did not find any entry with the domain, it adds to the end
        $updatedContent += $newEntry
    }

    # Joins the lines into a single string without extra line breaks
    $updatedContentString = $updatedContent -join "`r`n"

    # Attempt to write the updated content to the file
    try {
        Start-Sleep -Seconds 2 #Pause to prevent the file from being in use
        [System.IO.File]::WriteAllText($FILE_PATH, $updatedContentString, [System.Text.Encoding]::UTF8)
        Write-Host "The hosts file has been updated successfully." -ForegroundColor Green
    } catch {
        Write-Host "Error writing file: $_" -ForegroundColor Red
        exit 1
    }
}

end {
}