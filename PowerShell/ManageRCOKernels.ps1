#RCO servers list
$ServerList = @(
    "SMI-V-NERRCO01"
    "SMI-V-NERRCO02"
    "SMI-V-NERRCO03"
    "SMI-V-NERRCO04"
    "SMI-V-NERRCO05"
    "SMI-V-NERRCO06"
    "SMI-V-NERRCO07"
    "SMI-V-NERRCO08"
    "SMI-V-NERRCO09"
    "SMI-V-NERRCO10"
    "SMI-V-NERRCO11"
    "SMI-V-NERRCO12"
    "SMI-V-NERRCO13"
    "SMI-V-NERRCO14"
    "SMI-V-NERRCO15"
    "SMI-V-NERRCO16"
    "SMI-V-NERRCO17"
    "SMI-V-NERRCO18"
    "SMI-V-NERRCO19"
    "SMI-V-NERRCO20"
    "SMI-V-NERRCO21"
    "SMI-V-NERRCO22"
    "SMI-V-NERRCO23"
    "SMI-V-NERRCO24"
    "SMI-V-NERRCO25"
)

#Logs path
$LogPath = "F:\Medialogia\Logs\ManageRCOKernels\ManageRCOKernels.log"

#MSSQL connection info
$MssqlInstance = 'SMI-V-SUPPLY01.MLG.RU,1433'
$MssqlDatabase = "ADMIN"

#---------------- Functions block ------------ Begin ----

function FormatInt ($IntVal)
{
    $str = [convert]::ToString($IntVal)

    $output = ""

    $stop = $False

    while ($stop -ne $True)
    {
        if ($str.Length -gt 3)
        {
            $end = $str.substring($str.Length-3, 3)
            $str = $str.substring(0, $str.Length-3)
            $output = "$end $output"
        }
        else
        {
            $stop = $True
            $output = "$str $output"
        }
    }

    return $output
}

function FormatTimeStr($TimeVar)
{
    $ResVar = ""

    if ($TimeVar.Days -gt 0)
    {
        $ResVar = "$ResVar $($TimeVar.Days) d"
    }

    if ($TimeVar.Hours -gt 0)
    {
        $ResVar = "$ResVar $($TimeVar.Hours) h"
    }

    return "$ResVar $($TimeVar.Minutes) min"
}

function WriteLog
{
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $False, Position = 2)][string]$Path = $LogPath,
		[Parameter(Mandatory = $True, Position = 1)][object[]]$Value
	)
		
	$Encoding = [Microsoft.PowerShell.Commands.FileSystemCmdletProviderEncoding]::UTF8

    Out-File -FilePath $Path -InputObject $Value -Append -Encoding default
}
#---------------- Functions block ------------ End ----

$Step = 1

$Stat = @{} #Service start/stop statistics

Write "Service started $(([DateTime]::Now.ToString("dd.MM.yyyy HH:mm:ss")))"

#Timeout for one iteration
$timeout_min = 3


#Infinite loop
while ($Step -ge 1)
{
    #Write step's time and number
    WriteLog ([DateTime]::Now.ToString("dd.MM.yyyy HH:mm:ss") + " (Step $Step)")
    WriteLog ""

    #Prepare array for storing statistics
    $Stat[$Step] = @{}

    #Loop over servers list
    foreach ($Server in $ServerList) {
        #Get service status
        $Status = (Get-Service -ComputerName $Server -Name "Mlg.RcoKernel_Rabbit_01").Status

        #Get process object
        $Process = gwmi win32_process -cn $Server | where {$_.ProcessName -like "Mlg.RCOKernel*"} 

        #Get creation date of process
        if($Process.creationdate) {
            $EndDate = Get-Date
            $StartDate = [System.Management.ManagementDateTimeconverter]::ToDateTime($Process.creationdate)
            $WorkTime = NEW-TIMESPAN –Start $StartDate –End $EndDate
        }

        #Get process memory size
        $Size = [math]::Round($Process.WS/1024, 2)

        #Time total seconds
        $TimeMinutes = [int]$WorkTime.TotalMinutes

        #Let's kill process if some conditions are truthful
        if ($Status -eq "StartPending" -and $Size -lt 60000 -and $WorkTime.TotalMinutes -gt $timeout_min)
        {
            $Process.terminate() | Out-Null
            $KillFlag = " ... Killed"
        }
        else
        {
            $KillFlag = ""
        }

        #Convert process working time to string
        $TimeFormatted = FormatTimeStr($WorkTime)

        #Prepare process size string for output
        $SizeFormatted = FormatInt($Size)

        #Log startpending status
        if ($Status -eq "StartPending")
        {
            WriteLog "${Server}: $Status : ${SizeFormatted}kb :$TimeFormatted $KillFlag"
            Invoke-SQLcmd -ServerInstance $MssqlInstance -Database $MssqlDatabase -Query ("insert into HealthyRcoStatus (date, code, server, process_size, start_duration, step) values(getdate(), '$Status', '$Server', $Size, $TimeMinutes, $Step)")
        }
        #Log other statuses
        elseif($Status -eq "Stopped")
        {
            Invoke-SQLcmd -ServerInstance $MssqlInstance -Database $MssqlDatabase -Query ("insert into HealthyRcoStatus (date, code, server, step) values(getdate(), '$Status', '$Server', $Step)")
        }
        #---------------- Save status to array for statistics ------------ Begin ----
        if ($KillFlag -ne "")
        {
            $Stat[$Step][$Server] = "Kill"
        }
        else
        {
            $Stat[$Step][$Server] = $Status
        }
        #---------------- Save status to array for statistics ------------ End ----


        #---------------- Collect statistics ------------ Begin ----
        if ($Step -ge 2)
        {
            $Code = ""

            #Died status
            if (($Stat[$Step-1][$Server] -eq "Running") -and ($Stat[$Step][$Server] -eq "StartPending"))
            {
                $Code = "ProcessDied"
            }

            #Finish starting status
            if (($Stat[$Step-1][$Server] -eq "StartPending") -and ($Stat[$Step][$Server] -eq "Running"))
            {
                $Code = "ProcessIsFinishStarting"
            }

            #Process was killed
            if ($Stat[$Step][$Server] -eq "Kill")
            {
                $Code = "ProcessIsHanged_KillIt"
            }

            if (($Stat[$Step-1][$Server] -eq "Stopped") -and ($Stat[$Step][$Server] -eq "Stopped"))
            {
                $Code = "ServiceIsStopped_StartIt"

                #Let's start service, use ScriptBlock for not waiting service starting
                Start-Job -ScriptBlock {Get-Service -ComputerName $Using:Server -Name "Mlg.RcoKernel_Rabbit_01" | Start-Service}
            }

            #Write to db status codes table
            if ($Code -ne "") 
            {
                Invoke-SQLcmd -ServerInstance $MssqlInstance -Database $MssqlDatabase -Query ("insert into HealthyRcoStatus (date, code, server, step) values(getdate(), '$Code', '$Server', $Step)")
            }
        }
        #---------------- Collect statistics ------------ End ----
    }

    WriteLog ""
    WriteLog ("*"*50)
    WriteLog ""

    sleep ($timeout_min *60)

    $Step = $Step + 1

    if (24*60 -le $timeout_min * $Step ) { $Step = 1; Remove-Item -Path $LogPath -Force }
}
