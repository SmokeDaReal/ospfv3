#!/usr/bin/pwsh -Command

$out = ansible-playbook get_ipv6unirouting.yml

function Get-UniRouting{
    param(
        [Parameter(Mandatory = $true)][string]$routerId
    )

    $startIndex = $out.IndexOf(($out | Where-Object {$_ -like "*$($routerId)*=> {*"}))

    $isEnabled = $false

    [int]$x = $startIndex
    while($out[$x] -ne "}"){
        if($out[$x] -like "*true*"){
            $isEnabled = $true
        }
        $x++
    }
    return $isEnabled
}

function main{
    [xml]$xml = Get-Content "./topology.xml"

    $allGood = $true    

    $xml.routers.router | ForEach-Object {
        $routerHname = $_.hostname
        Write-Host "Router hostname: $($routerHname)"
        if(Get-UniRouting -routerId $routerHname){
            Write-Host "`tIPv6 unicast routing is enabled on this device" -ForegroundColor Green
        } else {
	    $allGood = $false
            Write-Host "`tIPv6 unicast routing is disabled on this device" -ForegroundColor Red
        }

        Write-Host ""
    }
    return $allGood
}

return (main)
