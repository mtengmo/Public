#Connect - AzureRmAccount  
$container_name = 'mailtemplates'  
$destination_path = 'c:\temp\azuremail'  
$connection_string = 'DefaultEndpointsProtocol=https;AccountName=ltemplates;AccountKey=zxxxxxxxBNo1kNrpYrGWANA==;EndpointSuffix=core.windows.net'  
$storage_account = New-AzureStorageContext -ConnectionString $connection_string  
$blobs = Get-AzureStorageBlob -Container $container_name -Context $storage_account 
foreach($blob in $blobs) {  
    New-Item -ItemType Directory -Force -Path $destination_path    
    Get-AzureStorageBlobContent -Container $container_name -Blob $blob.Name -Destination $destination_path -Context $storage_account
}  