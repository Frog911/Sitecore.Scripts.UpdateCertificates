function Write-HostCenter {
    param (
        [String]$Message,
        [String]$Color
    )
    Write-Host ("{0}{1}" -f (' ' * (([Math]::Max(0, $Host.UI.RawUI.BufferSize.Width / 2) - [Math]::Floor($Message.Length / 2)))), $Message) -ForegroundColor "Green"
}

function Write-TitleScriptStep {
    param (
        [String]$Message
    )
    Write-HostCenter " "
    Write-HostCenter "********************************************************************************"
    Write-HostCenter $Message
    Write-HostCenter "********************************************************************************"
    Write-HostCenter " "
}

function Invoke-BackupCert {
    param (
        [Parameter(Mandatory = $true)] [String]$backupDir,
        [Parameter(Mandatory = $true)] [Object[]]$certPath,
        [Parameter(Mandatory = $true)] [String]$certSubjectName,
        [Parameter(Mandatory = $true)] [String]$certIssuerName,
        [Switch]$exportToPfx,
        [SecureString]$certPass,
        [Switch]$withoutThumbprint
    )

    foreach ($item in $certPath) {
        try {
            $certs = Get-ChildItem $item | Where-Object { ($_.Subject.Replace("CN=", "").split(",")[0] -eq $certSubjectName) -and ($_.Issuer -match $certIssuerName) }
            if ($certs) {
                foreach ($cert in $certs) {
                    $certSubjectNameFromCertProperty = ($cert.Subject.Replace("CN=", "")).split(",")[0]
                    if ($withoutThumbprint) {
                        $certName = $certSubjectNameFromCertProperty
                    }
                    else {
                        $certName = $certSubjectNameFromCertProperty + "_" + $cert.Thumbprint
                    }
                    if ($exportToPfx) {
                        if (!(Test-Path -Path "$backupDir\$certName.pfx")) {
                            Export-PfxCertificate -Cert $cert -FilePath "$backupDir\$certName.pfx" -ChainOption EndEntityCertOnly -Password $certPass -ErrorAction Stop
                        }
                    }
                    else {
                        if (!(Test-Path -Path "$backupDir\$certName.cer")) {
                            Export-Certificate -Cert $cert -FilePath "$backupDir\$certName.cer" -ErrorAction Stop
                        }
                    }
                }
            }
        }
        catch {
            Write-Error -Message $_
        }
        
    }
}

function Invoke-RemoveCert {
    param (
        [Parameter(Mandatory = $true)] [String]$backupDir,
        [Parameter(Mandatory = $true)] [Object[]]$certPath,
        [Parameter(Mandatory = $true)] [String]$certSubjectName,
        [Parameter(Mandatory = $true)] [String]$certIssuerName
    )

    foreach ($item in $certPath) {
        try {
            $certs = Get-ChildItem $item | Where-Object { ($_.Subject.Replace("CN=", "").split(",")[0] -eq $certSubjectName) -and ($_.Issuer -match $certIssuerName) }
            if ($certs) {
                foreach ($cert in $certs) {
                    $certSubjectNameFromCertProperty = ($cert.Subject.Replace("CN=", "")).split(",")[0]
                    $certName = $certSubjectNameFromCertProperty + "_" + $cert.Thumbprint
                    if ((Test-Path -Path "$backupDir\$certName.pfx") -or (Test-Path -Path "$backupDir\$certName.cer")) {
                        $cert | Remove-Item -ErrorAction Stop
                    }
                    else {
                        Write-Host "Cert $certSubjectNameFromCertProperty don't have backup in folder $backupDir. You must create backup cert before remove it" -ForegroundColor Red
                    }
                }
            }
        }
        catch {
            Write-Error -Message $_
        }
        
    }
}

# Function
function Invoke-Binding {
    param (
        [Parameter(Mandatory = $true)] [String]$siteName,
        [Parameter(Mandatory = $true)] [String]$hostHeader,
        [Parameter(Mandatory = $true)] [String]$certSubjectName,
        [String]$certFriendlyName
    )
    try {
        $binding = Get-WebBinding -Name $siteName -HostHeader $hostHeader -Protocol "https"
        if ($certFriendlyName) {
            $certIdentityServer = Get-ChildItem "Cert:\LocalMachine\My" | `
                    Where-Object { ($_.Subject.Replace("CN=", "").split(",")[0] -eq $certSubjectName) -and ($_.FriendlyName -eq $certFriendlyName) }
        }
        else {
            $certIdentityServer = Get-ChildItem "Cert:\LocalMachine\My" | Where-Object { $_.Subject.Replace("CN=", "").split(",")[0] -eq $certSubjectName }
        }
        $binding.AddSslCertificate($certIdentityServer.GetCertHashString(), "My")
    }
    catch {
        Write-Error -Message $_
    }

}

function Invoke-ReplaceThumbprintInConfig {
    param (
        [Parameter(Mandatory = $true)] [String]$configPath,
        [Parameter(Mandatory = $true)] [String]$oldThumbprint,
        [Parameter(Mandatory = $true)] [String]$newThumbprint
    )
    Write-Host "Try replace thumbprint in config $configPath thumbprint $oldThumbprint to thumbprint $newThumbprint" -ForegroundColor Yellow
    try {
        ((Get-Content -path $configPath -Raw) -replace $oldThumbprint, $newThumbprint) | `
                Set-Content -Path $configPath
    }
    catch {
        Write-Error -Message $_
    }
    Write-Host "OK!" -ForegroundColor Green
}

function Invoke-CopyCertFileToWebroot {
    param (
        [Parameter(Mandatory = $true)] [String]$newCertPath,
        [Parameter(Mandatory = $true)] [String]$DestinationPath,
        [Parameter(Mandatory = $true)] [String]$newName
    )
    try {
        Copy-Item -Path $newCertPath -Destination $DestinationPath -Force
        $fileForRename = Split-Path -Path $newCertPath -Leaf
        if (!($newName -eq $fileForRename)) {
            if (Test-Path -Path "$DestinationPath\$newName") {
                Remove-Item -Path "$DestinationPath\$newName" -Force
            }
            Rename-Item -Path "$DestinationPath\$fileForRename" -NewName $newName
        }
    }
    catch {
        Write-Error -Message $_
    }
}


