##Check for Primary Node and needed services
##Author: Sovichea Sok 2020

Import-Module SqlServer


$style = @"
<style type='text/css'>
td {border:1px solid gray;}
.offline{background-color: #E01B1B;}
</style>
"@


$servers = <servers>
$reportPath = <report location>

$username = <username>
$password = ConvertTo-SecureString -AsPlainText <password> -Force
$securecredentials = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $Username,$password


function Get-PrimaryNode(){
    foreach ($server in $servers){
        write-host $server
        $session = New-PSSession -ComputerName $server -Credential $securecredentials
        #check if connection is successful
        if($session.State -eq 'Opened')
        {
            $props = @{    
                        'Instance' = $server
                      }
        }
        #catch unable to connect isntances
        else
        {
            $props = @{    
                        'Instance' = $server
                        'Primary Server' = "Cannot Connect"  
                      }
                      New-Object -TypeName PSObject -Property $props
        }
        #if able to connect query primary and services
        Invoke-Command -Session $session -ArgumentList $server,$props {
            param($server,$props)
            $primary = Invoke-Sqlcmd -Query "SELECT SERVERPROPERTY('ComputerNamePhysicalNetBIOS')" -ServerInstance $server | select -expand Column1
            #$primary = $primaryquery -replace '--' -replace ' ' -replace '[()]' -replace '1rowsaffected'
            $controlmstatus = Get-Service -Displayname "Control-M/Agent $server" | %{$_.Status}
            $controlmfilewatcherstatus = Get-Service -Displayname "Control-M/Agent FileWatcher $server" | %{$_.Status}
            $controlmdatabasesstatus = Get-Service -Displayname "Control-M for Databases $server" | %{$_.Status}
            $emcavamarstatus = Get-Service -Displayname "EMC Avamar Backup Agent for SQL Server (MSSQLSERVER)" | %{$_.Status}
            $props += @{    
                            
                            'Primary Server' = $primary
                            'Control M Service' = $controlmstatus
                            'Control M FileWatcher Service' = $controlmfilewatcherstatus
                            'Control M Databases Service' = $controlmdatabasesstatus
                            'EMC Avamar Backup Service' = $emcavamarstatus
                      }
            New-Object -TypeName PSObject -Property $props
        }
    }
}

Get-PrimaryNode | ConvertTo-Html -Property "Instance", "Primary Server", "Control M Service", "Control M FileWatcher Service", "Control M Databases Service", "EMC Avamar Backup Service" -Title "Primary Server Report" -PreContent "<h1>Primary Server Report</h1>" -Head $style | Foreach {
  if ($_ -like "*<td>Cannot Connect</td>*")
  {
    $_ -replace "<tr>", "<tr class='offline'>"
  }
  else
  {
  $_
  }
} |
Out-File $reportPath -force
