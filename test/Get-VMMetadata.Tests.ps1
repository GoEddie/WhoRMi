$here = Split-Path -Parent $MyInvocation.MyCommand.Path


Describe "Get-VMMetadata" {
    It "works" {
        . "$here/../src/whormi.ps1"
        Mock Invoke-MetadataService {
            Get-Content "$here/instance.json"
        }

        
        $metadata = Get-VMMetadata -verbose
        $metadata.location | Should Be 'westeurope'
    }
}
