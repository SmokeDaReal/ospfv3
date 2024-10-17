#!/usr/bin/pwsh -Command

[xml]$xml = Get-Content "./topology.xml"

Remove-Item ".\host_vars" -Force -Recurse -ErrorAction SilentlyContinue
New-Item -Path ".\" -Name "host_vars" -ItemType Directory

$xml.routers.router | ForEach-Object {
    "router_id: $($_.id)" | Add-Content ".\host_vars\$($_.hostname)v4.yaml"
    "router_id: $($_.id)" | Add-Content ".\host_vars\$($_.hostname)v6.yaml"
}
