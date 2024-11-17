#!/usr/bin/pwsh -Command

function Resolve-Name{
    param(
        [Parameter(Mandatory = $true)][string]$interfaceName
    )

    if($interfaceName.Contains('f')){
        return "Fa$($interfaceName.Substring(1))"
    }
    elseif($interfaceName.Contains('s')){
        return "Se$($interfaceName.Substring(1))"
    }
}

function Get-IfStat{
    param(
        [Parameter(Mandatory = $true)][string]$routerId,
        [Parameter(Mandatory = $true)][string]$interfaceId,
        [Parameter(Mandatory = $true)][int]$expectedArea
    )

    $startIndex = $out.IndexOf(($out | Where-Object {$_ -like "*$($routerId)*=> {*"}))

    [int]$x = $startIndex
    while($out[$x] -ne "}"){
        if($out[$x] -like "*$($interfaceId)*"){
            if($out[$x] -match '^\s*\S+\s+\d+\s+(\d)') {
                [int]$parsedArea = ($Matches[1]).TrimStart()
                if($parsedArea -eq $expectedArea) {
                    return [string]"gutArea"
                } else {
                    return $parsedArea
                }
            }
        }
        $x++
    }

    return [string]"noIf"
}

function Get-IfChanged{
    param(
        [Parameter(Mandatory = $true)][string]$routerId,
        [Parameter(Mandatory = $true)][string]$interfaceId
    )

    if([string]::IsNullOrEmpty(($out2 | Where-Object {$_ -like "*changed:*$($routerId)*$($interfaceId)*"}))) { return $false }
    else { return $true }
}

function Fix-OspfInterface{
    param(
        [Parameter(Mandatory = $true)][Collections.Generic.List[string]]$badRouters
    )

    $out2 = ansible-playbook (Invoke-Expression ".\get_playbookpath.ps1 -PlaybookName set_ipv6ospfint.yml")

    foreach($item in $badRouters)
    {
        Write-Host ""
        $router = $item.Split('-')[0]
        $int = $item.Split('-')[1]
        if(Get-IfChanged -routerId $router -interfaceId $int) { Write-Host "`t`tSuccessfully set OSPFv3 area on $($router), interface: $($int)" -ForegroundColor Cyan }
        else {  Write-Host "`t`tUnable to set OSPFv3 area on $($router), interface: $($int)" -ForegroundColor DarkRed }
	Write-Host ""
    }
}

function main{
    $out = ansible-playbook (Invoke-Expression ".\get_playbookpath.ps1 -PlaybookName get_ipv6ospfint.yml")
    [xml]$xml = Get-Content (Invoke-Expression ".\get_latestTopology.ps1")
    $badRouters = New-Object Collections.Generic.List[string]

    $xml.routers.router | ForEach-Object {
        $routerHname = $_.hostname
        Write-Host "Router hostname: $($routerHname)"
        $_.interface | ForEach-Object {
            if(!([string]::IsNullOrEmpty($_.area))) {
                $res = (Get-IfStat -routerId $routerHname -interfaceId (Resolve-Name -interfaceName $_.id) -expectedArea $_.area)
                if($res -eq "gutArea") {
                    Write-Host "`tInterface $($_.id) has OSPF configured, with the correct area $($_.area)" -ForegroundColor Green
                } elseif($res -eq "noIf") {
                    $badRouters.Add("$($routerHname)-$($_.id)")
                    Write-Host "`tInterface $($_.id) does not have OSPF configured!" -ForegroundColor Red
                } else {
                    $badRouters.Add("$($routerHname)-$($_.id)")
                    Write-Host "`tInterface $($_.id) has OSPF configured, but with wrong area: $($res)" -ForegroundColor DarkRed
                }
            }
        }

        Write-Host ""
    }

    if($badRouters.Count -eq 0){ return $true }
    else{
        $prompt = Read-Host "If you want to set the predetermined area numbers for OSPFv3 on the misconfigured routers and interfaces, press Y"
        if($prompt -eq "Y") {
            Fix-OspfInterface -badRouters $badRouters
            main
        }
        else{ return $false }
    }
}

main
