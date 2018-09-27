#Parameters
Param (
    [string] $ServerListPath
)

#Сonfig
$ServiceName = "Mlg.RcoKernel_Rabbit_01"
$ProcessName = "Mlg.RcoKernel"

$SourceDir = "F:\Medialogia\Other\RCOKernelUpgradeSource\"
$TargetDirLocal = "\Utils\Shadowing\Mlg.RcoKernel_Rabbit_01\"
$TargetDir = "MLG$TargetDirLocal"

$LogPath = "F:\Medialogia\Logs\RCOKernelUpgrade\RCOKernelUpgrade.log"

function WriteLog
{
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $False, Position = 2)][string]$Path = $LogPath,
		[Parameter(Mandatory = $True, Position = 1)][object[]]$Value,
		[switch]$NoTimestamp
	)
		
	$Encoding = [Microsoft.PowerShell.Commands.FileSystemCmdletProviderEncoding]::UTF8
	if ($NoTimestamp -eq $False) {
        Out-File -FilePath $Path -InputObject ([DateTime]::Now.ToString("dd.MM.yyyy HH:mm:ss") + " - " + $Value) -Append -Encoding default
	}
	else {
		Out-File -FilePath $Path -InputObject $Value -Append -Encoding default
	}
}

$functions = {
    function WriteLog
    {
	    [CmdletBinding()]
	    param
	    (
		    [Parameter(Mandatory = $False, Position = 2)][string]$Path = $LogPath,
		    [Parameter(Mandatory = $True, Position = 1)][object[]]$Value,
		    [switch]$NoTimestamp
	    )
		
	    $Encoding = [Microsoft.PowerShell.Commands.FileSystemCmdletProviderEncoding]::UTF8
	    if ($NoTimestamp -eq $False) {
            Out-File -FilePath $Path -InputObject ([DateTime]::Now.ToString("dd.MM.yyyy HH:mm:ss") + " - " + $Value) -Append -Encoding default
	    }
	    else {
		    Out-File -FilePath $Path -InputObject $Value -Append -Encoding default
	    }
    }
}

WriteLog ("*" * 50)

WriteLog "Upgrading Mlg.RcoKernel services"

WriteLog ("*" * 50)

if (!(Test-Path $SourceDir))
{
    Write "Source dir $SourceDir doesn't exist. Stop!"
    exit
}

if ($ServerListPath.Trim() -eq "")
{
    Write "Script parameter ServerListPath is not presented. Stop!"
    exit
}

#Read server list file
if (Test-Path $ServerListPath)
{
    $ServerList = Get-Content $ServerListPath

    if ($ServerList -ne $Null)
    {
        $Servers = @()

        foreach ($Server in $ServerList)
        {
            if ($Server.Trim() -ne "")
            {
                $Servers += $Server
            }
        }
    }
    else
    {
        Write "Server list file is empty. Stop!"
        exit
    }
}
else
{
    Write "Cannot find file $ServerListPath with list of servers. Stop!"
    exit
}

$cmd = {

    param ($Server, $ServiceName, $ProcessName, $SourceDir, $TargetDir, $TargetDirLocal, $LogPath)

    try {
        $PSSession = New-PSSession -cn $Server
    }

    catch {
        Write "Cannot start PSSession"
        $_.exception.message
    }


    #Invoke into remote server to stop service and kill process
    WriteLog "$Server : Start: Disable service and kill process"

    Invoke-Command -Session $PSSession -ThrottleLimit 10 -ArgumentList @($ServiceName, $ProcessName, $Server) -ScriptBlock `
    {

        $ServiceName = $args[0]
        $ProcessName = $args[1]
        $Server = $args[2]

        Set-Service -Name $ServiceName -StartupType Disabled
        Get-Process -Name $ProcessName | Stop-Process -Force
    }

    WriteLog "$Server : Finish : Disable service and kill process"

    #Clean folder on remote server
    WriteLog "$Server : Start: Clean service's folder"
    
    Invoke-Command -Session $PSSession -ThrottleLimit 10 -ArgumentList @($TargetDirLocal) -ScriptBlock `
    {
        $TargetDirLocal = $args[0]

        Remove-Item ((Resolve-Path "$env:MLG_ROOT${TargetDirLocal}").Path + "*") -Recurse -Force
    }

    WriteLog "$Server : Finish : Clean service's folder"

    #Check target dir
    if (!(Test-Path "\\$Server\$TargetDir"))
    {
        WriteLog "Target dir \\$Server\$TargetDir on $Server doesn't exist. Stop!"
        Remove-PSSession $PSSession
        exit
    }

    #Copy files
    $TargetDirFull = $("\\" + $Server + "\" + $TargetDir)
        
    WriteLog "$Server : Start : Copy files" 

    Start-Process robocopy -args "$SourceDir $TargetDirFull /Z /E /R:10" -Wait -WindowStyle Minimized

    WriteLog "$Server : Finish : Copy files" 

    #Invoke into remote server to enable and start service again
    WriteLog "$Server : Start : Enable and start service" 

    Invoke-Command -Session $PSSession -ThrottleLimit 10 -ArgumentList @($ServiceName, $ProcessName, $Server) -ScriptBlock `
    {
        $ServiceName = $args[0]
        $ProcessName = $args[1]
        $Server = $args[2]

        Get-Service -Name $ServiceName | Set-Service -StartupType Automatic
        Get-Service -Name $ServiceName | Start-Service | out-null
    }

    WriteLog "$Server : Finish : Enable and start service"

    Remove-PSSession $PSSession

    #Нужно для проверки работы Job-ов и вывода, ну удалять закомментированный блок
    <#$i = 0

    while ($i -lt 15)
    {
        write $i
        $i++
        sleep 1
    }#>
}

#Remove all old jobs
Get-Job | Remove-Job

#Start jobs
foreach ($Server in $Servers)
{
    Start-Job -ScriptBlock $cmd -InitializationScript $functions -ArgumentList $Server, $ServiceName, $ProcessName, $SourceDir, $TargetDir, $TargetDirLocal, $LogPath | out-null
}

#Look for jobs status
while ((Get-Job).State -ne "Completed" -and (Get-Job).State -ne $null)
{
    Write $([DateTime]::Now.ToString("dd.MM.yyyy HH:mm:ss") + " - Jobs status")
    Write "Running: $((Get-Job -State 'Running').Count), Failed: $((Get-Job -State 'Failed').Count), Completed: $((Get-Job -State 'Completed').Count), NotStarted: $((Get-Job -State 'NotStarted').Count), Total: $((Get-Job).Count)"
    Write ("*"*50)
    sleep (3*60)
}

#Receive all output of jobs
Get-Job | Receive-Job