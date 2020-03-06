##Status of DBs on Servers and identify ones with connectivity issue
##Author: Sovichea Sok 2020
$reportPath = <report-location>

Import-Module SqlServer


$style = @"
<style type='text/css'>
td {border:1px solid gray;}
.offline{background-color: #E01B1B;}
.cannotconnect{background-color: #FFFF00;}
</style>
"@

function Get-DBStatus 
{
    #define servers
    $ServerList = <servers>

    
    Foreach ($ServerName in $ServerList){
    write-host $ServerName
    $UserName = <username>
    $Password = <password>
    $serverConnection = new-object Microsoft.SqlServer.Management.Common.ServerConnection($ServerName)
    $serverConnection.LoginSecure = $True
    $serverConnection.ConnectAsUser = $true
    $serverConnection.ConnectAsUsername = $UserName
    $serverConnection.ConnectAsUserPassword = $Password
    
    
    $SQLServer = New-Object ('Microsoft.SqlServer.Management.Smo.Server') $serverConnection

    $error.clear()
    try {
    $test = $SQLServer.ConnectionContext.Connect()
    }
    catch
    {
        $props = @{
                     'Instance' = $ServerName
                     'Connection' = "Cannot Connect"
                 }
        New-Object -TypeName PSObject -Property $props
    }
    if (!$error)
    {
        
        
        foreach ($db in $SQLServer.Databases) 
        {
            
            Switch ($db.IsAccessible) 
            {
                "True" {$dbstatus = "Online"}
                "False" {$dbstatus = "Unavailable"}
            }

            $props = @{ 
                        'Instance' = $ServerName
                        'Connection' = 'Successful'
                        'DbName' = $db.Name
                        'Status' = $dbstatus
                      }
            New-Object -TypeName PSObject -Property $props
        } 
    }
    }
 
}

Get-DBStatus | ConvertTo-Html -Property Instance, Connection, DbName, Status -Title "Database Status" -PreContent "<h1>Database Status</h1>" -Head $style |
 
Foreach {

if ($_ -like "*<td>Unavailable</td>*")
{
$_ -replace "<tr>", "<tr class='offline'>"
}
if ($_ -like "*<td>Cannot Connect</td>*")
{
$_ -replace "<tr>", "<tr class='cannotconnect'>"
}
else
{
$_
}
} |
Out-File $reportPath -force
