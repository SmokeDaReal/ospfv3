#!/usr/bin/pwsh -Command

[xml]$xml = Get-Content (Invoke-Expression ".\get_latestTopology.ps1")

Remove-Item ".\host_vars" -Force -Recurse -ErrorAction SilentlyContinue
New-Item -Path ".\" -Name "host_vars" -ItemType Directory

$xml.routers.router | ForEach-Object {
    $temp = @()
    $temp += "router_id: $($_.id)"
    $temp += "interfaces:"
    $_.interface | ForEach-Object {
        if(![string]::IsNullOrEmpty($_.id)) {
            $temp += "  - ios_if: $($_.id)"
            if(![string]::IsNullOrEmpty($_.ipv4)) { $temp += "    ipv4: $($_.ipv4)" }
            if(![string]::IsNullOrEmpty($_.ipv6)) { $temp += "    ipv6: $($_.ipv6)" }
            if(![string]::IsNullOrEmpty($_.neighbor)) { $temp += "    neighbor: $($_.neighbor)" }
            
            if(![string]::IsNullOrEmpty($_.area)) {
                $temp += "    ospfv3:"
                $temp += "      area: $($_.area)"
            }
        }
    }
    
    $temp | Add-Content ".\host_vars\$($_.hostname)v4.yaml"
    $temp | Add-Content ".\host_vars\$($_.hostname)v6.yaml"
}
