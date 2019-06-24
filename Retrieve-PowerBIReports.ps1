param(
    [Parameter(Mandatory=$true)]
    $PowerBIServiceApplicationID,

    [Parameter(Mandatory=$true)]
    $PowerBIServiceApplicationKey,

    [Parameter(Mandatory=$true)]
    $SourceWorkspaceName,

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

    $sourceWorkspace = Get-PowerBIWorkspace -Name $SourceWorkspaceName
    
    Write-Host "Reading reports from $sourceWorkspaceName workspace"
    $reports = Get-PowerBIReport -Workspace $sourceWorkspace

    $reportsFolder = Join-Path $env:BUILD_SOURCESDIRECTORY "reports"
    if (!(Test-Path $reportsFolder)){New-Item -Path $reportsFolder -ItemType Directory}

    foreach ($report in $reports)
    {
        $tmpBPIXFileFullname = "$reportsFolder\$($report.Name).pbix"
        if(Test-Path $tmpBPIXFileFullname) {Remove-Item $tmpBPIXFileFullname -Force}

        Write-Host "Downloading $ReportName report from $sourceWorkspaceName workspace to file $tmpBPIXFileFullname"
        Export-PowerBIReport -WorkspaceId $sourceWorkspace.Id -Id $report.id -OutFile "$tmpBPIXFileFullname"   
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