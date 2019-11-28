# Import module
Import-Module ".\Modules\CertsModule.psm1" -Force
Import-Module ".\SitecoreInstallFramework.2.1.0\SitecoreInstallFramework.psm1" -Force
Import-Module ".\SIF.Sitecore.Commerce.3.0.28\Modules\SitecoreUtilityTasks\SitecoreUtilityTasks.psm1" -Force
Import-Module ".\SIF.Sitecore.Commerce.1.4.7\Modules\ManageCommerceService\ManageCommerceService.psm1" -Force

. /Params.ps1

# Create backup dir
if (!(Test-Path -Path $backupDir)) {
    New-Item -Path $backupDir -ItemType Directory
}

if (!(Test-Path -Path $newCertDir)) {
    New-Item -Path $newCertDir -ItemType Directory
}

# Clean dir with new certs
if (Test-Path -Path $newCertDir) {
    try {
        Write-Host "Try remove certs from dir $newCertDir" -ForegroundColor Yellow
        Remove-Item -Path "$newCertDir\*" -Recurse -Force
    }
    catch {
        throw "Script cannot remove certs from dir"
    }
    Write-Host "OK!" -ForegroundColor Green
}

# Get thumbprint old certs
$thumbprintOldCertXconnectServer = (Get-ChildItem $CertPath[0] | `
            Where-Object { $_.Subject.Replace("CN=", "").split(",")[0] -eq $certSubjectNameXconnectClient }).Thumbprint

$thumbprintOldCertSitecoreServer = (Get-ChildItem $CertPath[0] | `
            Where-Object { $_.Subject.Replace("CN=", "").split(",")[0] -eq $certSubjectNameSitecore }).Thumbprint

# Do it!

# Backup old certs
Write-TitleScriptStep "Backup old certs"
try {
    Invoke-BackupCert -backupDir $backupDir `
        -certPath $CertPath[2] `
        -certSubjectName $certSubjectNameSitecoreFundamentalsRoot `
        -certIssuerName $certIssuerNameMatching

    Invoke-RemoveCert -backupDir $backupDir `
        -certPath $CertPath `
        -certSubjectName $certSubjectNameSitecoreFundamentalsRoot `
        -certIssuerName $certIssuerNameMatching

    Invoke-BackupCert -backupDir $backupDir `
        -certPath $CertPath[2] `
        -certSubjectName $certSubjectNameSitecoreRootCert `
        -certIssuerName $certIssuerNameMatching

    Invoke-RemoveCert -backupDir $backupDir `
        -certPath $CertPath `
        -certSubjectName $certSubjectNameSitecoreRootCert `
        -certIssuerName $certIssuerNameMatching

    Invoke-BackupCert -backupDir $backupDir `
        -certPath $CertPath[0] `
        -certSubjectName $certSubjectNameSitecore `
        -certIssuerName $certIssuerNameMatching `
        -exportToPfx `
        -certPass $certPass

    Invoke-RemoveCert -backupDir $backupDir `
        -certPath $CertPath `
        -certSubjectName $certSubjectNameSitecore `
        -certIssuerName $certIssuerNameMatching

    Invoke-BackupCert -backupDir $backupDir `
        -certPath $CertPath[0] `
        -certSubjectName $certSubjectNameXconnectClient `
        -certIssuerName $certIssuerNameMatching `
        -exportToPfx `
        -certPass $certPass

    Invoke-RemoveCert -backupDir $backupDir `
        -certPath $CertPath `
        -certSubjectName $certSubjectNameXconnectClient `
        -certIssuerName $certIssuerNameMatching

    Invoke-BackupCert -backupDir $backupDir `
        -certPath $CertPath[0] `
        -certSubjectName $certSubjectNameXconnect `
        -certIssuerName $certIssuerNameMatching `
        -exportToPfx `
        -certPass $certPass

    Invoke-RemoveCert -backupDir $backupDir `
        -certPath $CertPath `
        -certSubjectName $certSubjectNameXconnect `
        -certIssuerName $certIssuerNameMatching

    Invoke-BackupCert -backupDir $backupDir `
        -certPath $CertPath[0] `
        -certSubjectName $certSubjectNameIdentityServer `
        -certIssuerName $certSubjectNameIdentityServer `
        -exportToPfx `
        -certPass $certPass

    Invoke-RemoveCert -backupDir $backupDir `
        -certPath $CertPath `
        -certSubjectName $certSubjectNameIdentityServer `
        -certIssuerName $certSubjectNameIdentityServer

    Invoke-BackupCert -backupDir $backupDir `
        -certPath $CertPath[0] `
        -certSubjectName $certSubjectNameCommerceEngine `
        -certIssuerName $certIssuerNameMatching `
        -exportToPfx `
        -certPass $certPass

    Invoke-RemoveCert -backupDir $backupDir `
        -certPath $CertPath `
        -certSubjectName $certSubjectNameCommerceEngine `
        -certIssuerName $certIssuerNameMatching
}
catch {
    Write-Error -Message $_
}


# Create new sitecore root cert
Write-TitleScriptStep "Create new sitecore root cert"
try {
    Invoke-NewRootCertificateTask -Path $newCertDir `
        -Name "SitecoreRootCert" `
        -DnsName $certSubjectNameSitecoreRootCert

    $certSitecoreRootCert = Get-ChildItem $CertPath[2] | Where-Object { $_.Subject.Replace("CN=", "").split(",")[0] -eq $certSubjectNameSitecoreRootCert }
}
catch {
    Write-Error -Message $_
} 


# sxa.storefront.com
Write-TitleScriptStep "Create new sitecore cert, binding and change configs"
try {
    Invoke-NewSignedCertificateTask -Signer $certSitecoreRootCert `
        -Path $newCertDir `
        -CertStoreLocation $CertPath[0] `
        -Name $certSubjectNameSitecore `
        -DnsName $certSubjectNameSitecore `
        -IncludePrivateKey `
        -Password $certPass

    Invoke-Binding -siteName $certSubjectNameSitecore `
        -hostHeader $certSubjectNameSitecore `
        -certSubjectName $certSubjectNameSitecore
            
    Invoke-BackupCert -backupDir $newCertDir `
        -certPath $CertPath[0] `
        -certSubjectName $certSubjectNameSitecore `
        -certIssuerName $certIssuerNameMatching `
        -withoutThumbprint

    Invoke-CopyCertFileToWebroot -newCertPath "$newCertDir\$certSubjectNameSitecore.cer" `
        -DestinationPath "$sitecoreWebRoot\App_data" `
        -newName "gateway.crt"

    $thumbprintNewCertSitecoreServer = (Get-ChildItem $CertPath[0] | Where-Object { $_.Subject.Replace("CN=", "").split(",")[0] -eq $certSubjectNameSitecore }).Thumbprint

    Invoke-ReplaceThumbprintInConfig -configPath $sitecoreCommerceAuthoring_Sc9ConfigPath `
        -oldThumbprint $thumbprintOldCertSitecoreServer `
        -newThumbprint $thumbprintNewCertSitecoreServer

    Invoke-ReplaceThumbprintInConfig -configPath $sitecoreCommerceCommerceMinions_Sc9ConfigPath `
        -oldThumbprint $thumbprintOldCertSitecoreServer `
        -newThumbprint $thumbprintNewCertSitecoreServer

    Invoke-ReplaceThumbprintInConfig -configPath $sitecoreCommerceCommerceOps_Sc9ConfigPath `
        -oldThumbprint $thumbprintOldCertSitecoreServer `
        -newThumbprint $thumbprintNewCertSitecoreServer

    Invoke-ReplaceThumbprintInConfig -configPath $sitecoreCommerceCommerceShops_Sc9ConfigPath `
        -oldThumbprint $thumbprintOldCertSitecoreServer `
        -newThumbprint $thumbprintNewCertSitecoreServer

    Invoke-ReplaceThumbprintInConfig -configPath $sitecoreCommerceEngineConfigPath `
        -oldThumbprint $thumbprintOldCertSitecoreServer `
        -newThumbprint $thumbprintNewCertSitecoreServer                                
}
catch {
    Write-Error -Message $_
}

# sxa_xconnect.storefront.com
Write-TitleScriptStep "Create new xconnect cert and binding"
try {
    Invoke-NewSignedCertificateTask -Signer $certSitecoreRootCert `
        -Path $newCertDir `
        -CertStoreLocation $CertPath[0] `
        -Name $certSubjectNameXconnect `
        -DnsName $certSubjectNameXconnect `
        -IncludePrivateKey `
        -Password $certPass

    # Binding sxa_xconnect.storefront.com
    Invoke-Binding -siteName $certSubjectNameXconnect `
        -hostHeader $certSubjectNameXconnect `
        -certSubjectName $certSubjectNameXconnect

    Invoke-BackupCert -backupDir $newCertDir `
        -certPath $CertPath[0] `
        -certSubjectName $certSubjectNameXconnect `
        -certIssuerName $certIssuerNameMatching `
        -withoutThumbprint
}
catch {
    Write-Error -Message $_
}

# sxa.storefront.com.xConnect.Client
Write-TitleScriptStep "Create new xconnect client cert, binding, change configs and change permissions"
try {
    Invoke-NewSignedCertificateTask -Signer $certSitecoreRootCert `
        -Path $newCertDir `
        -CertStoreLocation $CertPath[0] `
        -Name $certSubjectNameXconnectClient `
        -DnsName $certSubjectNameXconnectClient `
        -IncludePrivateKey `
        -Password $certPass

    # Set permission 
    $thumbprintNewCertXconnectServer = (Get-ChildItem $CertPath[0] | Where-Object { $_.Subject.Replace("CN=", "").split(",")[0] -eq $certSubjectNameXconnectClient }).Thumbprint
    $certXconnectServerPath = Invoke-ResolveCertificatePathConfigFunction -CertificatePath "$($CertPath[0])\$thumbprintNewCertXconnectServer"

    $rightsAppPoolXconnectServer = @{
        User             = "IIS AppPool\$certSubjectNameXconnect"
        FileSystemRights = "Read"
        InheritanceFlags = "None"
    }
    Invoke-FilePermissionsTask -Path $certXconnectServerPath `
        -Rights $rightsAppPoolXconnectServer

    $rightsLocalServiceXconnectServer = @{
        User             = "NT AUTHORITY\LocalService"
        FileSystemRights = "Read"
        InheritanceFlags = "None"
    }

    Invoke-FilePermissionsTask -Path $certXconnectServerPath `
        -Rights $rightsLocalServiceXconnectServer

    # Change configs
    Invoke-ReplaceThumbprintInConfig -configPath $sitecoreConnectionStringsPath `
        -oldThumbprint $thumbprintOldCertXconnectServer `
        -newThumbprint $thumbprintNewCertXconnectServer

    Invoke-ReplaceThumbprintInConfig -configPath $xconnectAppSettingsConfigPath `
        -oldThumbprint $thumbprintOldCertXconnectServer `
        -newThumbprint $thumbprintNewCertXconnectServer

    Invoke-ReplaceThumbprintInConfig -configPath $xconnectAutomationEngineConnectionStringsPath `
        -oldThumbprint $thumbprintOldCertXconnectServer `
        -newThumbprint $thumbprintNewCertXconnectServer

    # copy crt certificate to App_data xConnect
    Invoke-CopyCertFileToWebroot -newCertPath "$newCertDir\$certSubjectNameXconnect.cer" `
        -DestinationPath "$xconnectWebRoot\App_data" `
        -newName "gateway.crt"

    Invoke-CopyCertFileToWebroot -newCertPath "$newCertDir\SitecoreRootCert.crt" `
        -DestinationPath "$xconnectWebRoot\App_data" `
        -newName "root-authority.crt"
}
catch {
    Write-Error -Message $_
}

# Commerce Engine SSL Localhost Certificate
Write-TitleScriptStep "Create new Commerce Engine SSL Localhost Certificate and binding"
try {
    Invoke-NewCommerceSignedCertificateTask -Signer $certSitecoreRootCert `
        -Path $newCertDir `
        -FriendlyName "Commerce Engine SSL Localhost Certificate" `
        -CertStoreLocation $CertPath[0] `
        -Name $certSubjectNameCommerceEngine `
        -DnsName $certSubjectNameCommerceEngine

    Invoke-Binding -siteName "CommerceAuthoring_Sc9" `
        -hostHeader $certSubjectNameCommerceEngine `
        -certSubjectName $certSubjectNameCommerceEngine `
        -certFriendlyName "Commerce Engine SSL Localhost Certificate"

    Invoke-Binding -siteName "CommerceMinions_Sc9" `
        -hostHeader $certSubjectNameCommerceEngine `
        -certSubjectName $certSubjectNameCommerceEngine `
        -certFriendlyName "Commerce Engine SSL Localhost Certificate"

    Invoke-Binding -siteName "CommerceOps_Sc9" `
        -hostHeader $certSubjectNameCommerceEngine `
        -certSubjectName $certSubjectNameCommerceEngine `
        -certFriendlyName "Commerce Engine SSL Localhost Certificate"
                                        
    Invoke-Binding -siteName "CommerceShops_Sc9" `
        -hostHeader $certSubjectNameCommerceEngine `
        -certSubjectName $certSubjectNameCommerceEngine `
        -certFriendlyName "Commerce Engine SSL Localhost Certificate"

    Invoke-Binding -siteName "SitecoreBizFx" `
        -hostHeader $certSubjectNameCommerceEngine `
        -certSubjectName $certSubjectNameCommerceEngine `
        -certFriendlyName "Commerce Engine SSL Localhost Certificate"
}
catch {
    Write-Error -Message $_
}                              
                                       
# Identity Server
Write-TitleScriptStep "Create new Identity Server Certificate, binding and change permissions"
try {
    Invoke-IssuingCertificateTask -CertificateDnsName $certSubjectNameIdentityServer `
        -CertificatePassword $certPfxPass `
        -CertificateStore $CertPath[0] `
        -CertificateFriendlyName "Sitecore Identity Server" `
        -IDServerPath $identityServerWebRoot

    # Set permission for identity server cert                             
    $certIdentityServer = (Get-ChildItem $CertPath[0] | Where-Object { $_.Subject.Replace("CN=", "").split(",")[0] -eq $certSubjectNameIdentityServer }).Thumbprint
    $certIdentityServerPath = Invoke-ResolveCertificatePathConfigFunction -CertificatePath "$($CertPath[0])\$certIdentityServer"

    $UserAccount = @{
        UserName = $UserName
        Domain   = "$env:COMPUTERNAME"
        Password = $UserNamePass
    }

    $rightsCertIdentityServer = @{
        User             = $UserAccount
        FileSystemRights = "Read"
        InheritanceFlags = "None"
    }

    Invoke-SetPermissionsTask -Path $certIdentityServerPath `
        -Rights $rightsCertIdentityServer

    Invoke-BackupCert -backupDir $newCertDir `
        -certPath $CertPath[0] `
        -certSubjectName $certSubjectNameIdentityServer `
        -certIssuerName $certSubjectNameIdentityServer `
        -withoutThumbprint

    Import-Certificate -FilePath "$newCertDir\$certSubjectNameIdentityServer.cer" `
        -CertStoreLocation $CertPath[2]

    Invoke-Binding -siteName "SitecoreIdentityServer" `
        -hostHeader $certSubjectNameCommerceEngine `
        -certSubjectName $certSubjectNameCommerceEngine `
        -certFriendlyName "Commerce Engine SSL Localhost Certificate"
}
catch {
    Write-Error -Message $_
}     