<#
    .SYNOPSIS

    When you run this on an Azure VM it returns the metadata associated with the virtual machine using the local VM Metadata service

    .DESCRIPTION

    Get-VMMetadata connects to the local metadata service which runs on the same physical host as the virtual machines are hosted on. The service returns some really useful information such as:

        location
        name
        resourceGroupName
        subscriptionId
        vmId
        vmSize
        tags
        version
    
        offer
        osType
        publisher
        sku
        apiVersion
        placementGroupID
        platformFaultDomain

#>
Function Get-VMMetadata {
    [CmdletBinding()]    
    param(
        $apiVersion = '2017-08-01',
        $hostName = '169.254.169.254',
        $uri = 'metadata/instance'
    )   

    $url = "http://$hostName/$uri?api-version=$apiVersion"

    
    class NetworkInterface {
        [string]$ip4PrivateAddress
        [String]$ip4PublicAddress
        [String]$ip4SubnetAddress        
        [String]$ip4SubnetPrefix

        [String]$macAddress

    }

    class InstanceMetadata {
    
        [String]$location
        [String]$name
        [String]$resourceGroupName
        [String]$subscriptionId
        [String]$vmId
        [String]$vmSize
        [String]$tags
        [String]$version
    
        [String]$offer
        [String]$osType
        [String]$publisher
        [String]$sku
        [String]$apiVersion


        [String]$placementGroupID
        [String]$platformFaultDomain
        [String]$platformUpdateDomain

        [NetworkInterface[]]$NetworkInterfaces

        $RawResponse
    }

    $json = Invoke-MetadataService -URL $url
    $notes = $json | ConvertFrom-Json
    
    [InstanceMetadata]$metadata = New-Object InstanceMetadata
    $metadata.location = $notes.compute.location
    $metadata.name = $notes.compute.name
    $metadata.offer = $notes.compute.offer
    $metadata.osType = $notes.compute.osType
    $metadata.placementGroupId = $notes.compute.placementGroupId
    $metadata.platformFaultDomain = $notes.compute.platformFaultDomain
    $metadata.platformUpdateDomain = $notes.compute.platformUpdateDomain
    $metadata.publisher = $notes.compute.publisher
    $metadata.resourceGroupName = $notes.compute.resourceGroupName
    $metadata.sku = $notes.compute.sku
    $metadata.subscriptionId = $notes.compute.subscriptionId
    $metadata.tags = $notes.compute.tags
    $metadata.version = $notes.compute.version
    $metadata.vmId = $notes.compute.vmId
    $metadata.vmSize = $notes.compute.vmSize

    $metadata.NetworkInterfaces += ($notes.network.interface | ForEach-Object {
            $interface = $_
        
            Write-Verbose ($interface.ipv4.subnet[0]).address
            Write-Verbose $interface.ipv4.subnet[0].prefix
            Write-Verbose $interface.ipv4.ipAddress.privateIPAddress
            Write-Verbose $interface.ipv4.ipAddress.publicIPAddress
            Write-Verbose $interface.macAddress
        
            [NetworkInterface]$nic = New-Object NetworkInterface
            $nic.macAddress = $interface.macAddress
            $nic.ip4PublicAddress = $interface.ipv4.ipAddress.publicIPAddress
            $nic.ip4PrivateAddress = $interface.ipv4.ipAddress.privateIPAddress
            $nic.ip4SubnetPrefix = $interface.ipv4.subnet[0].prefix
            $nic.ip4SubnetAddress = $interface.ipv4.subnet[0].address

            $nic
        }
    )

    $metadata.RawResponse = $notes
        
    $metadata

}



Function Invoke-MetadataService {
    [CmdletBinding()]
    param(    
        [String]$URL
    )

    Write-Verbose "Invoke-MetadataService:Requesting:URL: '$URL'"

    $response = Invoke-WebRequest -Uri $URL -UseBasicParsing -Headers @{"Metadata" = "true"}
    if ($response -eq $null) {
        Write-Error "Unable to get a response, no metadata for you"
    }
    else {
        Write-Verbose "Invoke-MetadataService:Success"
        $response.content
    }
    
}