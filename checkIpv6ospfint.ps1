#!/usr/bin/pwsh -Command

$out = ansible-playbook get_ipv6ospfint.yml

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

function main{
    [xml]$xml = Get-Content "./topology.xml"

    $xml.routers.router | ForEach-Object {
        $routerHname = $_.hostname
        Write-Host "Router hostname: $($routerHname)"
        $_.interface | ForEach-Object {
            if(!([string]::IsNullOrEmpty($_.area))) {
                $res = (Get-IfStat -routerId $routerHname -interfaceId (Resolve-Name -interfaceName $_.id) -expectedArea $_.area)
                if($res -eq "gutArea") {
                    Write-Host "`tInterface $($_.id) has OSPF configured, with the correct area $($_.area)" -ForegroundColor Green
                } elseif($res -eq "noIf") {
                    Write-Host "`tInterface $($_.id) does not have OSPF configured!" -ForegroundColor Red
                } else {
                    Write-Host "`tInterface $($_.id) has OSPF configured, but with wrong area: $($res)" -ForegroundColor DarkRed
                }
            }
        }
    }
}

main
