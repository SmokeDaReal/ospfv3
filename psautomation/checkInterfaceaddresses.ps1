#!/usr/bin/pwsh -Command

function Resolve-Name{
    param(
        [Parameter(Mandatory = $true)][string]$interfaceName
    )

    if($interfaceName.Contains('f')){
        return "FastEthernet$($interfaceName.Substring(1))"
    }
    elseif($interfaceName.Contains('s')){
        return "Serial$($interfaceName.Substring(1))"
    }
}

function Get-IP{
    param(
        [Parameter(Mandatory = $true)][string]$routerId,
        [Parameter(Mandatory = $true)][string]$interfaceName
    )

    $ips = @()

    $startIndex = $out.IndexOf(($out | Where-Object {$_ -like "*$($routerId)*=> {*"}))

    [int]$x = $startIndex
    while($out[$x] -ne "}"){
        if($out[$x] -like "*" + (Resolve-Name -interfaceName $interfaceName) + "*"){
            [int]$j = $x + 1
            while(($out[$j] -match '\s*"\s*(.*?)\s*"\s*') -and !($out[$j].Contains("["))){
                $ips += $matches[1]
                $j++
            }
        }
        $x++
    }

    return $ips
}

function Get-IfChanged{
    param(
        [Parameter(Mandatory = $true)][string]$routerId,
        [Parameter(Mandatory = $true)][string]$interfaceId
    )

    if([string]::IsNullOrEmpty(($out2 | Where-Object {$_ -like "*changed:*$($routerId)*$($interfaceId)*"}))) { return $false }
    else { return $true }
}

function Fix-Ipv6Address{
    param(
        [Parameter(Mandatory = $true)][Collections.Generic.List[string]]$badRouters
    )

    $out2 = ansible-playbook (Invoke-Expression ".\get_playbookpath.ps1 -PlaybookName set_interfaces.yml")

    foreach($item in $badRouters)
    {
        Write-Host ""
        $router = $item.Split('-')[0]
        $int = $item.Split('-')[1]
        if(Get-IfChanged -routerId $router -interfaceId $int) { Write-Host "`t`tSuccessfully set IPv6 address on $($router), interface: $($int)" -ForegroundColor Cyan }
        else {  Write-Host "`t`tUnable to set IPv6 address on $($router), interface: $($int)" -ForegroundColor DarkRed }
	Write-Host ""
    }
}

function main{
    $out = ansible-playbook (Invoke-Expression ".\get_playbookpath.ps1 -PlaybookName get_interfaces.yml")
    [xml]$xml = Get-Content "./topology.xml"
    $badRouters = New-Object Collections.Generic.List[string]

    $xml.routers.router | ForEach-Object {
        $routerHname = $_.hostname
        Write-Host "Router hostname: $($routerHname)"
        $_.interface | ForEach-Object{
            [string]$ip = ($_.ipv6).Split('/')[0]
            $ipArray = Get-IP -routerId $routerHname -interfaceName $_.id
            if(!([string]::IsNullOrEmpty(($ipArray | Where-Object{ $_ -like "*$($ip)*" })))) {
                Write-Host "`tInterface IP on $($_.id): $($_.ipv6) is correct!" -ForegroundColor Green
            } else {
                Write-Host "`tInterface IP on $($_.id): $($_.ipv6) is NOT correct!" -ForegroundColor Red
                $badRouters.Add("$($routerHname)-$($_.id)")
            }
        }

	    Write-Host ""
    }

    if($badRouters.Count -eq 0){ return $true }
    else{
        $prompt = Read-Host "If you want to modify the IPv6 addresses on the misconfigured routers and interfaces, press Y"
        if($prompt -eq "Y") {
            Fix-Ipv6Address -badRouters $badRouters
            main
        }
        else{ return $false }
    }
}

main
