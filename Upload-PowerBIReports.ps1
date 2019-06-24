param(
    [Parameter(Mandatory=$true)]
    $PowerBIServiceApplicationID,
    
    [Parameter(Mandatory=$true)]
    $PowerBIServiceApplicationKey,

    [Parameter(Mandatory=$true)]
    $SourceFolderPath,

    [Parameter(Mandatory=$true)]
    $DestinationWorkspaceName,

    [Parameter(Mandatory=$true)]
    $PromoteConflictAction,

    [Parameter(Mandatory=$true)]
    $ReportFileName,


    $TenantID # YOUR DEFAULT AZURE TENANT ID
)



foreach ($moduleName in @("MicrosoftPowerBIMgmt.Reports", "MicrosoftPowerBIMgmt.Workspaces", "MicrosoftPowerBIMgmt.Profile"))
{
  if  ((Get-Module $moduleName) -eq $null)
  {
      Write-Host "Installing $moduleName"
      Install-Module -Name $moduleName -Force
  }
}

$securedPassword = $PowerBIServiceApplicationKey  | ConvertTo-SecureString -asPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential($PowerBIServiceApplicationID,$securedPassword)

$ErrorActionPreference = 'Stop'
try
{
    Connect-PowerBIServiceAccount -ServicePrincipal -Credential $credential -Tenant $TenantID
    $destinationWorkspace = Get-PowerBIWorkspace -Name $DestinationWorkspaceName

    if ($ReportFileName -eq 'All')
    {
       $reportFiles = Get-ChildItem -Path $SourceFolderPath
    }
    else
    {
       $reportFiles = Get-ChildItem -Path (Join-Path $SourceFolderPath "$ReportFileName")
    }

    foreach ($reportFile in $reportFiles)
    {
       Write-Host "Uploading $($reportFile.Fullname) to $DestinationWorkspaceName"
       New-PowerBIReport -Path "$($reportFile.Fullname)" -Name "$($reportFile.Basename)" -Workspace $destinationWorkspace -ConflictAction $PromoteConflictAction -Timeout 2000    
    }

}
catch
{
    Resolve-PowerBIError -Last
    exit 1
}
finally
{
    Disconnect-PowerBIServiceAccount
}