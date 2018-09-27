$ServerList = @(
    <#"SMI-V-NERHL01"
    "SMI-V-NERHL02"
    "SMI-V-NERHL03"
    "SMI-V-NERHL04"
    "SMI-V-NERHL05"
    "SMI-V-NERHL06"
    "SMI-V-NERHL07"
    "SMI-V-NERHL08"
    "SMI-V-NERHL09"
    "SMI-V-NERHL10"
    "divider"#>
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

$LogPath = "F:\Medialogia\Logs\RCOFoldersUpdateStatus\RCOFoldersUpdateStatus.log"

$NerHLDataPath = "\\Smi-v-nerq01\mlg\Other\NerHLData"

$MailMessage = @{
	From = "$($Env:COMPUTERNAME)@mlg.ru"
	To = "support@mlg.ru"
	SmtpServer = "mail.mlg.ru"
	BodyAsHtml = $False
	Encoding = "UTF8"
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
    #Write $Value
}

function GetFolderSize($FullName) {
    $subFolderItems = Get-ChildItem $FullName -recurse -force | Where-Object {$_.PSIsContainer -eq $false} | Measure-Object -property Length -sum | Select-Object Sum
    return $subFolderItems.sum
}

Write "Service started $(([DateTime]::Now.ToString("dd.MM.yyyy HH:mm:ss")))"

WriteLog ([DateTime]::Now.ToString("dd.MM.yyyy HH:mm:ss"))
WriteLog ""

#Get NERQ (sample) size and folder name
$item = Get-ChildItem "\\SMI-V-NERQ01\MLG\Other\RCO" <#recurse#> | Where-Object {$_.PSIsContainer -eq $true -and $_.Name -like "Objects_*"}
$NerqFolderSize = GetFolderSize ($item.FullName)
$NerqFolderName = $item.Name

WriteLog "SMI-V-NERQ01 : $NerqFolderName : $NerqFolderSize bytes"
WriteLog ("+"*40)

$FailedServers = ""

$failed_servers_num = 0;

#Get folder name and folder size on RCO/NERHL servers
foreach ($Server in $ServerList) {
    if ($Server -eq "divider")
    {
        WriteLog ("-"*40)
    }
    else
    {
        $item = Get-ChildItem "\\$Server\MLG\Other\RCO" <#recurse#> | Where-Object {$_.PSIsContainer -eq $true -and $_.Name -like "Objects_*"}

        $FolderName = $item.name

        $FolderSize = GetFolderSize ($item.FullName)
        #$FolderSize = 12341234;

        if (($NerqFolderSize -ne $FolderSize) -or ($NerqFolderName -ne $FolderName))
        {
            $FailedServers = $FailedServers + $Server + " "
            $failed_servers_num++;
        }
        
        WriteLog "$Server : $FolderName : $FolderSize bytes"
    }

}

#Check date of NerHLData folder
$NerHLDate = (Get-Item $NerHLDataPath).LastWriteTime
$Yesterday = (Get-Date).AddDays(-1)

$NerHLErrMessage = ""

if ("$($NerHLDate.year).$($NerHLDate.month).$($NerHLDate.day)" -ne "$($Yesterday.year).$($Yesterday.month).$($Yesterday.day)")
{
    $NerHLErrMessage = "BuildSnapshot Error`nДата изменения папки $NerHLDataPath не равняется вчера.`n" + "Проверьте работу скрипта F:\Medialogia\Utils\ObjectConverter\RUN.cmd в части исполнения Mlg.NerHighlighter.exe buildsnapshot"
    WriteLog ""
}

WriteLog ""
WriteLog ("*"*50)
WriteLog ""

$ResultError = ""

if ($FailedServers -ne "")
{
    $ResultError = "RCO/NERHL Folder Update Error`nПроизошла ошибка обновления папки с объектами RCO на следующих серверах:`n" + $FailedServers + "`n" + "Подробности в логе $LogPath на SMI-V-NERQ01"
}

if($ResultError -ne "")
{
    if ($failed_servers_num -gt 5) {
        $ResultError = "Не обновлена лингвистика! Дежурному: Нужно связаться с администратором ПАК для исправления!`n`n" + $ResultError;
    } else {
        $ResultError = "Лингвистика не обновлена на 5 серверах или менее. Действия от дежурного не требуются!`n`n" + $ResultError;
    }

     $ResultError += "`n`n";
}


if ($NerHLErrMessage -ne "")
{

    $ResultError = $ResultError + $NerHLErrMessage
}

if($ResultError -ne "")
{
    WriteLog $ResultError
     
    if ($failed_servers_num -gt 5) {
        $MailMessage.Subject = "(Critical) Ошибка обновления папки RCO. Дежурный - свяжись с администратором ПАК!"
    } else {
        $MailMessage.Subject = "(Warning) Ошибка обновления папки RCO."
    }

    $MailMessage.Body = $ResultError
    $MailMessage.From = "$($Env:COMPUTERNAME)@mlg.ru"

    Send-MailMessage @MailMessage
}
