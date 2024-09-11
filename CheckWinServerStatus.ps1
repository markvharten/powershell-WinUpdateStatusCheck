$DCserver = (Get-CimInstance Win32_ComputerSystem).Domain ; $computers = $null ; $counter = 0 ; $AantalServers = $null
$computers = Get-ADComputer -Server $DCserver -Filter {OperatingSystem -like '*Windows Server*' -and Enabled -eq $True} | Sort Name
$AantalServers = ($computers).count

$output = @()

	foreach ($comp in $computers) {
Try{
		$counter++
	    $computerName = $comp.Name
	    $UPTIME = "-" ; $hotfix = "-" ; $getIPFull = "-" ; $getIPName = "-" ; $getIPAddress = "-" ; $wmiMAC = "-" ; $wmiMACout = "-" ; $Mo = "-" ; $OS = "-"
	    $HotfixDescription = "-" ; $HotfixInstalledOn = "-" ; $SystemUptimeDays = "-" ; $PlatformModel = "-" ; $PlatformManufacturer = "-" ; $SystemIPinfo = "-"
		$UPTIME = (Get-Date)-(Get-WmiObject Win32_OperatingSystem  -ComputerName $computerName -ErrorAction SilentlyContinue | ForEach-Object { $_.ConvertToDateTime($_.LastBootUpTime) }) | select Days | foreach {$_.Days} 
	    $hotfix = (Get-HotFix -ComputerName $computerName | Sort-Object -Property InstalledOn)[-1]
		$getIPFull = Resolve-DNSName $computerName ; $getIPName = $getIPFull.Name ; $getIPAddress = $getIPFull.IPAddress
		$wmiMAC = gwmi -Class Win32_NetworkAdapterConfiguration -ComputerName $getIPName ; $wmiMACout = ($wmiMAC | where { $_.IpAddress -eq $getIPAddress }).MACAddress
		$Mo = Get-WmiObject -Class CIM_ComputerSystem -ComputerName $computerName
		$OS = (Get-WmiObject -class Win32_OperatingSystem -ComputerName $computerName -ErrorAction SilentlyContinue).Caption
}
Catch {
	Write-Warning "not all info available for: $computerName"
}
	    $output += [PSCustomObject]@{
	        ComputerName = $computerName
	        HotfixDescription = $hotfix.Description
	        HotfixInstalledOn = $hotfix.InstalledOn
			SystemUptimeDays = $UPTIME
			SystemIPinfo = $getIPAddress
			SystemMacinfo = $wmiMACout
			PlatformModel = ($Mo).Model
			PlatformManufacturer = ($Mo).Manufacturer
			Os = $OS
	    }
	    Write-Host "$computerName - Ready [ $counter / $AantalServers ]"
	}
#$output | Out-GridView -Title "Server List - Aantal: $AantalServers"
$output | Export-Csv -Append -Path C:\TEMP\Server-Update-stat.csv -NoTypeInformation
