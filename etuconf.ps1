$intfs = Get-NetAdapter -Physical | ? {$_.Status -eq "Up"} 
foreach ($int in $intfs) {
Set-DNSClientServerAddress -InterfaceIndex $int.InterfaceIndex -ServerAddresses ("10.136.2.2","10.128.0.254")	
Clear-DnsClientCache
Disable-NetAdapterBinding -Name $int.Name -ComponentID ms_tcpip6 -Confirm:$false
}
$DisableLMHosts_Class=Get-WmiObject -list Win32_NetworkAdapterConfiguration
$DisableLMHosts_Class.EnableWINS($false,$false)
$regkey = "HKLM:SYSTEM\CurrentControlSet\services\NetBT\Parameters\Interfaces"
Get-ChildItem $regkey |foreach { Set-ItemProperty -Path "$regkey\$($_.pschildname)" -Name NetbiosOptions -Value 1 -Verbose}
netsh advfirewall firewall set rule group="Обнаружение сети" new enable=Yes
powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
powercfg -h off
slmgr.vbs -ipk W269N-WFGWX-YVC9B-4J6C9-T83GX 
slmgr.vbs -skms 10.136.2.180 
if (-not (Get-WindowsOptionalFeature -Online -FeatureName "SMB1Protocol" -ErrorAction SilentlyContinue).State) {
    Enable-WindowsOptionalFeature -Online -FeatureName "SMB1Protocol" -NoRestart
} else {
}
# Получаем объект тома диска C
$volume = Get-Partition | Where-Object { $_.DriveLetter -eq "C" }

if ($volume) {
    # Вычисляем новый размер тома (150 ГБ) в байтах
    $newSize = 200GB

    # Уменьшаем размер тома
    Resize-Partition -DriveLetter "C" -Size $newSize
}
else {
    Write-Host "Том диска C не найден"
}
# Создаем новый раздел и назначаем букву диска, сохраняя информацию о разделе
$partition = New-Partition -DiskNumber 0 -AssignDriveLetter -UseMaximumSize

# Получаем информацию о разделе с назначенной буквой диска
$partitionInfo = Get-Partition -DiskNumber 0 -PartitionNumber $partition.PartitionNumber

# Получаем букву назначенного диска из информации о разделе
$driveLetter = $partitionInfo.DriveLetter

Format-Volume -DriveLetter $driveLetter -FileSystem NTFS -AllocationUnitSize 8192
slmgr.vbs /ato
