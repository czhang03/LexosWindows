
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param (
    [Parameter(Mandatory = $true, Position = 0)]
    [string] $Version,
    [Parameter(Mandatory = $true, Position = 1)]
    [string] $AnacondaVersion
)

# stop when hit an error
$ErrorActionPreference = "stop"

# constants
$nsisMakeFile = "C:\Program Files (x86)\NSIS\makensis.exe"
$MSBuildFile = "C:\Program Files (x86)\MSBuild\14.0\Bin\amd64\MSBuild.exe"
$foldersToExclude = @("TestSuite", ".git", ".github", "0_InstallGuides", "1_DevDocs", "2_InTheMargins", "deprecated")
$anacondaDownloadLink64 = "https://repo.continuum.io/archive/Anaconda3-{0:version}-Windows-x86_64.exe" -f $AnacondaVersion
$anacondaDownloadLink32 = "https://repo.continuum.io/archive/Anaconda3-{0:version}-Windows-x86.exe" -f $AnacondaVersion
$anacondaName64 = "Anaconda3-{0:version}-Windows-x86.exe" -f $AnacondaVersion
$anacondaName32 = "Anaconda3-{0:version}-Windows-x64.exe" -f $AnacondaVersion

# start up
Write-Host "init git submodule" -ForegroundColor Yellow
git submodule init
Write-Host "update git submodule" -ForegroundColor Yellow
git submodule update

############### check the existence of the build environment 

# check the chocolatey
if (Get-Command choco.exe -ErrorAction SilentlyContinue) 
{
    Write-Host "chocolatey found" -ForegroundColor Green
    Write-Host "if any requirement is missing will be installed using choco" -ForegroundColor Yellow
    Write-Host ''
    $chocoExist = $true
}
else 
{
    Write-Host "chocolatey not found" -ForegroundColor Green
    $installChocoResponce = Read-Host "do you want to install it? enter ([Y]es/[N]o)"

    if ($installChocoResponce.ToLower().StartsWith("y")) 
    {
        Write-Host "Installing chocolatey" -ForegroundColor Green
        Invoke-WebRequest -Uri "https://chocolatey.org/install.ps1 " | Invoke-Expression  # this is the expression to install choco
        $chocoExist = $true
    }
    else 
    {
        Write-Host "skipping choco, if there is any requirement missing the script will stop" -ForegroundColor Yellow
        $chocoExist = $false
    }
}

# check for nsis make
if (Test-Path $nsisMakeFile) 
{
    Write-Host "nsis make file found" -ForegroundColor Green
}
else 
{
    Write-Warning "nsis make file not found"
    if ($chocoExist) 
    {   
        # let user confirm and install nsis
        if ($PSCmdlet.ShouldProcess($env:COMPUTERNAME, "install MSBuild")) 
        {
            Start-Process -FilePath "cint.exe" -ArgumentList "nsis -yf"
        }

        # if nsis is not installed
        if (Test-Path $nsisMakeFile) {Write-Error -Category ResourceUnavailable -Message "requirement nsismake does not match"}
    }
    else 
    {
        Write-Error -Category ResourceUnavailable -Message "requirement nsismake does not match"
    }
    
}

# check for MSBuild
if (Test-Path $MSBuildFile) 
{
    Write-Host "MSBuild file found" -ForegroundColor Green 
}
else 
{
    Write-Warning "nsis make file not found"
    if ($chocoExist) 
    {
        # let user confirm and install msbuild
        if ($PSCmdlet.ShouldProcess($env:COMPUTERNAME, "install MSBuild")) 
        {
            Start-Process -FilePath "cint.exe" -ArgumentList "microsoft-build-tools -yf"
        }

         # if msbuild is not installed
        if (Test-Path $nsisMakeFile) {Write-Error -Category ResourceUnavailable -Message "requirement nsismake does not match"}
    }
    else 
    {
        Write-Error -Category ResourceUnavailable -Message "requirement nsismake does not exit"
    }
    
}

################################## Set location to work better

$CurrentLocation = Get-Location
Set-Location $PSScriptRoot  
Write-Verbose "Location moves to $PWD"


################################# Processing Lexos folder

Set-Location "$PSScriptRoot\"
Write-Verbose "Location moves to $PWD"

New-Item -ItemType Directory -Path "Lexo.Bak" -Confirm:$false -Force | Out-Null

# moving the excluded folder to the backup folder
foreach ($folder in $foldersToExclude) {
    Write-Verbose "moving $PWD\Lexos\$folder to $PWD\Lexo.Bak\$folder"
    Move-Item -Path "Lexos\$folder" -Destination "Lexo.Bak\$folder" -Force
}


################################ Building the exe 

Set-Location "$PSScriptRoot\Executable"
Write-Verbose "Location Moves to $PWD"

# 32 bits
Write-Host "compiling Executable for x86 system"
Start-Process -FilePath $MSBuildFile -ArgumentList "/property:Configuration=Release /property:Platform=x86 /verbosity:minimal" -NoNewWindow | Out-Null

# 64 bits
Write-Host "compiling Executable for x64 system"
Start-Process -FilePath $MSBuildFile -ArgumentList "/property:Configuration=Release /property:Platform=x64 /verbosity:minimal" -NoNewWindow | Out-Null


################################ Building the installer

Set-Location "$PSScriptRoot/installer"
Write-Verbose "Location Moves to $PWD"

# prepare
New-Item -ItemType Directory -Path "build" -Confirm:$false -Force
$installerTemplate = Get-Content "InstallScriptTemplate.nsi"
$webClient = New-Object System.Net.WebClient
$webClient.Headers.Add("user-agent", [Microsoft.PowerShell.Commands.PSUserAgent]::FireFox) 


# write and build the installer script for x86
$installScriptOutputPathx86 = "./build/InstallScriptx86.nsi"

Write-Host "Downloading Anaconda 32 bits" -ForegroundColor Yellow
Write-Verbose "Downloading $anacondaDownloadLink32 to $PWD/build/$anacondaName32"
$webClient.DownloadFile($anacondaDownloadLink32, "./build/$anacondaName32")  # download anaconda for the installer to pack

$installScriptx86 = $installerTemplate.Replace("{{PlatformName}}", "x86").Replace("{{Version}}", $Version).Replace("{{anacondaVersion}}", $AnacondaVersion)
Out-File -FilePath $installScriptOutputPathx86 -InputObject $installScriptx86 -Encoding utf8  # write

Start-Process -FilePath $nsisMakeFile -ArgumentList $installScriptOutputPathx86 -NoNewWindow # build


# write and build the installer script for x64
$installScriptOutputPathx64 = "./build/InstallScriptx64.nsi"

Write-Host "Downloading Anaconda 64 bits" -ForegroundColor Yellow
Write-Verbose "Downloading $anacondaDownloadLink64 to $PWD/build/$anacondaName64"
$webClient.DownloadFile($anacondaDownloadLink32, "./build/$anacondaName64")  # download anaconda for the installer to pack

$installScriptx86 = $installerTemplate.Replace("{{PlatformName}}", "x64").Replace("{{Version}}", $Version).Replace("{{anacondaVersion}}", $AnacondaVersion)
Out-File -FilePath $installScriptOutputPathx64 -InputObject $installScriptx86 -Encoding utf8

Start-Process -FilePath $nsisMakeFile -ArgumentList $installScriptOutputPathx64 -NoNewWindow # build



################################ over!


Set-Location "$PSScriptRoot"
Write-Verbose "Location moves to $PWD"

# moving the excluded folder to the backup folder
foreach ($folder in $foldersToExclude) {
    Write-Verbose "tempting to move $PWD\Lexos.bak\$folder to $PWD\$folder"
    Move-Item -Path "Lexo.Bak\$folder" -Destination "Lexos\$folder" -Force
}

Remove-Item "Lexos.bak"


Set-Location $CurrentLocation
Write-Verbose "Location move back to $PWD"