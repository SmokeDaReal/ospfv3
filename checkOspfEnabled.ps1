#!/usr/bin/pwsh -Command

$out = ansible-playbook get_ipv6ospf.yml

function Get-RoutingProcess{
    param(
        [Parameter(Mandatory = $true)][string]$routerName,
        [Parameter(Mandatory = $true)][string]$routerId
    )

    $ips = @()

    $startIndex = $out.IndexOf(($out | Where-Object {$_ -like "*$($routerName)*=> {*"}))

    $isCorrect = $false
    [int]$x = $startIndex
    while($out[$x] -ne "}"){
        if($out[$x] -like "*Routing Process \""ospfv3 1\"" with ID $($routerId)*"){
             $isCorrect = $true
        }
        $x++
    }

    return $isCorrect
}

function main{
    [xml]$xml = Get-Content "./topology.xml"

    $xml.routers.router | ForEach-Object {
        $routerHname = $_.hostname
        Write-Host "Router hostname: $($routerHname)"
        if(Get-RoutingProcess -routerName $routerHname -routerId ($_.id)){
            Write-Host "`tOSPFv3 is enabled with Id: $($_.id)" -ForegroundColor Green
        } else {
            Write-Host "`tOSPFv3 is NOT enabled with Id: $($_.id)" -ForegroundColor Red
        }
	Write-Host ""
    }
}

main
