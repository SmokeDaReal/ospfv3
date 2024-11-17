#!/usr/bin/pwsh -Command

function Get-NeighborRouterId{
    param(
        [Parameter(Mandatory = $true)][string]$routerName,
        [Parameter(Mandatory = $true)][string]$interfaceId,
        [Parameter(Mandatory = $false)][switch]$idOutput
    )

    $routerObject = $xml.routers.router | Where-Object { $_.hostname -eq $routerName }
    $neighborOnIf = ($routerObject.interface | Where-Object { $_.id -eq $interfaceId }).neighbor

    if($idOutput) { return ($xml.routers.router | Where-Object { $_.hostname -eq $neighborOnIf }).id }
    else { return ($xml.routers.router | Where-Object { $_.hostname -eq $neighborOnIf }).hostname }
}

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

function Get-TrueNeighbor{
    param(
        [Parameter(Mandatory = $true)][string]$routerId,
        [Parameter(Mandatory = $true)][string]$interfaceId
    )

    $startIndex = $out.IndexOf(($out | Where-Object {$_ -like "*$($routerId)*=> {*"}))

    $isCorrect = $false

    [int]$x = $startIndex
    while($out[$x] -ne "}"){
        if($out[$x] -like "*$(Resolve-Name -interfaceName ($interfaceId))*"){
            $nRouterId = Get-NeighborRouterId -routerName $routerId -interfaceId $interfaceId -idOutput
            if($out[$x].Contains($nRouterId)) {
                
                $isCorrect = $true
            }
        }
        $x++
    }

    return $isCorrect
}

function main{
    $out = ansible-playbook (Invoke-Expression ".\get_playbookpath.ps1 -PlaybookName get_ipv6ospfneigh.yml")
    [xml]$xml = Get-Content (Invoke-Expression ".\get_latestTopology.ps1")
    $badRouters = New-Object Collections.Generic.List[string]

    $xml.routers.router | ForEach-Object {
        $routerHname = $_.hostname
        Write-Host "Router hostname: $($routerHname)"
        $_.interface | ForEach-Object {
            if(!([string]::IsNullorEmpty($_.neighbor))){
                $expectedNeighborName = Get-NeighborRouterId -routerName $routerHname -interfaceId ($_.id)
                if(Get-TrueNeighbor -routerId $routerHname -interfaceId $_.id){
                    Write-Host "`tThis router is neighbor with: $($expectedNeighborName)" -ForegroundColor Green
                } else {
                    Write-Host "`tThis router is NOT neighbor with: $($expectedNeighborName)" -ForegroundColor Red
                    $badRouters.Add("$($routerHname)-$($_.id)")
                }
            }
        }

	    Write-Host ""
    }

    if($badRouters.Count -eq 0){ return $true }
    else{
        $prompt = Read-Host "If you want to query the OSPF information on the misconfigured routers and interfaces, press Y"
        if($prompt -eq "Y") {
            Write-Host (Get-Content ".\tippsforospfinterfaces" -Raw) -ForegroundColor DarkMagenta
            pause
            foreach($router in $badRouters){
                $routerName = "$($router.Split('-')[0])v4"
                $ifId = $router.Split('-')[1]
                ansible-playbook (Invoke-Expression ".\get_playbookpath.ps1 -PlaybookName get_ipv6ospfint_detailed.yml") --extra-vars "router=$($routerName) interfaceId=$($ifId)"
                Write-Host ""
            }
        }
        else{ return $false }
    }
}

main
