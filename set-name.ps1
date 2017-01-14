$PSScriptRoot = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition

function RN_CheckName {

    Write-Host "[Log Step] Checking for updated name"

    $SecurePasswordKey = "report secure password" # K1000 password for MySQL report user
    $key = (3,4,17,28,56,34,254,223,28,53,29,23,42,54,33,233,7,2,2,28,6,7,54,43)
    $SecurePassword = ConvertTo-SecureString -String $SecurePasswordKey -Key $key
    $un = "report" 
    $pw = ConvertTo-SecureString -String $SecurePasswordKey -Key $key
    $network_creds = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $un, $pw
  
    $MySQLAdminUserName = $network_creds.GetNetworkCredential().UserName
    $MySQLAdminPassword = $network_creds.GetNetworkCredential().Password
    $MySQLDatabase = ''
    $MySQLHost = 'k1000.domain.com'
    $ConnectionString = "server=" + $MySQLHost + ";port=3306;uid=" + $MySQLAdminUserName + ";pwd=" + $MySQLAdminPassword + ";"

    #You will need to change what I have mapped as "ASSD.FIELD_10010" which was the asset data for our computer assets
    #I created a field for the computer asset called "Desired Name" which was assigned the collumn name FIELD_10010.    
    $Query = "SELECT MACH.NAME AS CURRENT_NAME, ASSD.FIELD_10010 AS DESIRED_NAME FROM ORG1.MACHINE AS MACH INNER JOIN ORG1.ASSET AS ASS ON MACH.ID=ASS.MAPPED_ID INNER JOIN ORG1.ASSET_DATA_5 AS ASSD ON ASS.ASSET_DATA_ID=ASSD.ID WHERE MACH.NAME = '$($ENV:COMPUTERNAME)';"
    Try {
      [void][System.Reflection.Assembly]::LoadWithPartialName("MySql.Data")
      $Connection = New-Object MySql.Data.MySqlClient.MySqlConnection
      $Connection.ConnectionString = $ConnectionString
      $Connection.Open()

      $Command = New-Object MySql.Data.MySqlClient.MySqlCommand($Query, $Connection)
      $DataAdapter = New-Object MySql.Data.MySqlClient.MySqlDataAdapter($Command)
      $DataSet = New-Object System.Data.DataSet
      $RecordCount = $dataAdapter.Fill($dataSet, "data")
      }

    Catch {
      Write-Host "[ERROR !!!!!!!!] Unable to run query : $query `n$Error[0]"
     }

     #If the field 'Desired Name' is set for the machine and the machine's current doesn't match, it will be renamed
    if($DataSet.Tables[0].CURRENT_NAME -ne $DataSet.Tables[0].DESIRED_NAME) { 
        write-host "[Log Step] Updating computer name to $($DataSet.Tables[0].DESIRED_NAME)"; 
        $DESIRED_NAME = $DataSet.Tables[0].DESIRED_NAME
        if($DESIRED_NAME.length -lt 15){
            $ComputerName = $DESIRED_NAME.Replace("[","").Replace("]","").Replace(":","").Replace(";","").Replace("|","").Replace("=","").Replace("+","").Replace("*","").Replace("?","").Replace("<","").Replace(">","").Replace("/","").Replace("\","").Replace(",","")
            RN_SetName -ComputerName $ComputerName
        }else{ Write-Host "[Log Step] Computer name is too long, please change the name"; }
    }else{
        Write-Host "[Log Step] No change needed."

    }    
}

function RN_SetName{
    [CmdletBinding()]
    param([Parameter(Position=0,mandatory=$true)][string]$ComputerName )

    $SecurePasswordKey = "Domain account password with rename rights"
    $key = (3,4,17,28,56,34,254,223,28,53,29,23,42,54,33,233,7,2,2,28,6,7,54,43)
    $un = "domain\kace" 
    $pw = ConvertTo-SecureString -String $SecurePasswordKey -Key $key
	$network_creds = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $un, $pw 

    Rename-Computer -NewName "$ComputerName" -DomainCredential $network_creds

    schtasks /delete /tn "RN-restart-computername" /F #Just in case these didn't go off
    schtasks /delete /tn "RN-set-newname" /F #Just in case these didn't go off
    schtasks /create /sc ONCE /ru "SYSTEM" /tn RN-restart-computername /tr "shutdown -r -f -t 0" /st 23:59
}


function RN_Init{
    $PowershellVersion = $PSVersionTable.PSVersion.Major

    #Check if MySQL Data Connector is installed
    if ([System.IntPtr]::Size -eq 4) { Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | Where-Object {$_.DisplayName -like "MySQL Connector Net*"} | Format-Table –AutoSize } 
    else{ $MySqlInstallCheck = Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | Where-Object {$_.DisplayName -like "MySQL Connector Net*"} | Format-Table –AutoSize }

    #installs MySQL Data Connector, no restart needed for this
    if($MySqlInstallCheck.Length -eq 0 -or $MySqlInstallCheck -eq $null){ write-host "[Log Step] Installing MySQL Data Connector"; Start-Process -FilePath "C:\Windows\System32\msiexec.exe" -ArgumentList "/i $($PSScriptRoot)\mysql-install.msi /quiet /qn" -Wait; }
    
    #Windows 7 doesn't support 'rename-computer' until you install the Windows Management Framework 4.0
    if($PowershellVersion -ge "4"){ RN_CheckName; }else{ Write-Host "[ERROR !!!!!!!!] Script requires Powershell 4 to run"; }
}

RN_Init;