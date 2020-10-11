#Connect to IotHub
$IoTHub = Get-AzureRmIotHub -Name $IoTHubName -ResourceGroupName $RGName
$IoTHubKey = Get-AzureRmIotHubKey -ResourceGroupName $RGName -Name $IoTHubName -KeyName $IoTKeyName
$IoTConnectionString = “HostName=$($IoTHubName).azure-devices.net;SharedAccessKeyName=$($IoTKeyName);SharedAccessKey=$($IoTHubKey.PrimaryKey)”

# New DeviceID
$deviceParams = @{
iotConnString = $IoTConnectionString
deviceId = $newDeviceID
}
$device = Register-IoTDevice @deviceParams

$IoTConnectionString

$device
