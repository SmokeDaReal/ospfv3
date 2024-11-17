#!/usr/bin/pwsh -Command

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

function Get-IfChanged{
    param(
        [Parameter(Mandatory = $true)][string]$routerId
    )

    if([string]::IsNullOrEmpty(($out2 | Where-Object {$_ -like "*changed:*$($routerId)*"}))) { return $false }
    else { return $true }
}

function Fix-OspfProcess{
    param(
        [Parameter(Mandatory = $true)][Collections.Generic.List[string]]$badRouters
    )

    $out2 = ansible-playbook (Invoke-Expression ".\get_playbookpath.ps1 -PlaybookName set_ipv6ospf.yml")

    foreach($router in $badRouters)
    {
        Write-Host ""
        if(Get-IfChanged -routerId $router) { Write-Host "`t`tSuccessfully enabled the OSPFv3 process 1 on $($router)" -ForegroundColor Cyan }
        else {  Write-Host "`t`tUnable to enable the OSPFv3 process 1 on $($router)" -ForegroundColor DarkRed }
	Write-Host ""
    }
}

function main{
    $out = ansible-playbook (Invoke-Expression ".\get_playbookpath.ps1 -PlaybookName get_ipv6ospf.yml")
    [xml]$xml = Get-Content (Invoke-Expression ".\get_latestTopology.ps1")
    $badRouters = New-Object Collections.Generic.List[string]

    $xml.routers.router | ForEach-Object {
        $routerHname = $_.hostname
        Write-Host "Router hostname: $($routerHname)"
        if(Get-RoutingProcess -routerName $routerHname -routerId ($_.id)){
            Write-Host "`tOSPFv3 process is running with Id: $($_.id)" -ForegroundColor Green
        } else {
            $badRouters.Add($routerHname)
            Write-Host "`tOSPFv3 process is NOT running with Id: $($_.id)" -ForegroundColor Red
        }

        Write-Host ""
    }

    if($badRouters.Count -eq 0){ return $true }
    else{
        $prompt = Read-Host "If you want to enable the OSPFv3 process 1 with router-id on the misconfigured routers, press Y"
        if($prompt -eq "Y") {
            Fix-OspfProcess -badRouters $badRouters
            main
        }
        else{ return $false }
    }
}

main
