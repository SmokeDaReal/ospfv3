#!/usr/bin/pwsh -Command

$out = ansible-playbook get_interfaces.yml

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
            #Write-Host $out[$x]
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

function main{
    [xml]$xml = Get-Content topology.xml

    $xml.routers.router | ForEach-Object {
        $routerHname = $_.hostname
        Write-Host "Router hostname: $($routerHname)"
        $_.interface | ForEach-Object{
            $ipArray = Get-IP -routerId $routerHname -interfaceName $_.id
            if(($ipArray).Contains((($_.ipv6).Split('/')[0])), 'InvariantCultureIgnoreCase'){
                Write-Host "`tInterface IP: $($_.ipv6) is correct!" -ForegroundColor Green
            } else { Write-Host "Interface IP: $($_.ipv6) is NOT correct!" -ForegroundColor Red }
        }
    }
}

main
