# Params
[String]$backupDir = "c:\certificates_old"
[String]$newCertDir = "c:\certificates_new"

$CertPath = @(
    "Cert:\LocalMachine\My", # 0
    "Cert:\LocalMachine\CA", # 1
    "Cert:\LocalMachine\Root", # 2
    "Cert:\CurrentUser\My", # 3
    "Cert:\CurrentUser\CA", # 4
    "Cert:\CurrentUser\Root" # 5
)

$webRoot = "C:\inetpub\wwwroot"
$sitecoreWebRoot = "$webRoot\sxa.storefront.com"
$xconnectWebRoot = "$webRoot\sxa_xconnect.storefront.com"
$identityServerWebRoot = "$webRoot\SitecoreIdentityServer"

[String]$certSubjectNameSitecoreFundamentalsRoot = "DO_NOT_TRUST_SitecoreFundamentalsRoot"
[String]$certSubjectNameSitecoreRootCert = "DO_NOT_TRUST_SitecoreRootCert"
[String]$certSubjectNameSitecore = "sxa.storefront.com"
[String]$certSubjectNameXconnectClient = "sxa.storefront.com.xConnect.Client"
[String]$certSubjectNameXconnect = "sxa_xconnect.storefront.com"
[String]$certSubjectNameIdentityServer = "identity.server"
[String]$certSubjectNameCommerceEngine = "localhost"
[String]$certIssuerNameMatching = "Sitecore"

$UserName = "Administrator"
$UserNamePass = "asdZXC123"

$certPfxPass = "sitecore"
$certPass = ConvertTo-SecureString -String $certPfxPass -Force -AsPlainText

$sitecoreCommerceAuthoring_Sc9ConfigPath = "$webRoot\CommerceAuthoring_Sc9\wwwroot\config.json"
$sitecoreCommerceCommerceMinions_Sc9ConfigPath = "$webRoot\CommerceMinions_Sc9\wwwroot\config.json"
$sitecoreCommerceCommerceOps_Sc9ConfigPath = "$webRoot\CommerceOps_Sc9\wwwroot\config.json"
$sitecoreCommerceCommerceShops_Sc9ConfigPath = "$webRoot\CommerceShops_Sc9\wwwroot\config.json"
$sitecoreCommerceEngineConfigPath = "$webRoot\$certSubjectNameSitecore\App_Config\Include\Y.Commerce.Engine\Sitecore.Commerce.Engine.Connect.config"

$sitecoreConnectionStringsPath = "$webRoot\$certSubjectNameSitecore\App_Config\ConnectionStrings.config"
$xconnectAppSettingsConfigPath = "$webRoot\$certSubjectNameXconnect\App_Config\AppSettings.config"
$xconnectAutomationEngineConnectionStringsPath = "$webRoot\$certSubjectNameXconnect\App_data\jobs\continuous\AutomationEngine\App_Config\ConnectionStrings.config"