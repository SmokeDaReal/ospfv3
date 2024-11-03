#!/usr/bin/pwsh -Command

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


function Get-IfChanged{
    param(
        [Parameter(Mandatory = $true)][string]$routerId
    )

    if([string]::IsNullOrEmpty(($out2 | Where-Object {$_ -like "*changed:*$($routerId)*"}))) { return $false }
    else { return $true }
}

function Fix-Unirouting{
    param(
        [Parameter(Mandatory = $true)][Collections.Generic.List[string]]$badRouters
    )

    $out2 = ansible-playbook (Invoke-Expression ".\get_playbookpath.ps1 -PlaybookName set_ipv6unirouting.yml")

    foreach($router in $badRouters)
    {
        Write-Host ""
        if(Get-IfChanged -routerId $router) { Write-Host "`t`tSuccessfully enabled ipv6 unicast-routing on $($router)" -ForegroundColor Cyan }
        else {  Write-Host "`t`tUnable to enable ipv6 unicast-routing on $($router)" -ForegroundColor DarkRed }
	Write-Host ""
    }
}

function main{
    $out = ansible-playbook (Invoke-Expression ".\get_playbookpath.ps1 -PlaybookName get_ipv6unirouting.yml")
    [xml]$xml = Get-Content "./topology.xml"
    $badRouters = New-Object Collections.Generic.List[string]

    $xml.routers.router | ForEach-Object {
        $routerHname = $_.hostname
        Write-Host "Router hostname: $($routerHname)"
        if(Get-UniRouting -routerId $routerHname){
            Write-Host "`tIPv6 unicast routing is enabled on this device" -ForegroundColor Green
        } else {
            $badRouters.Add($routerHname)
            Write-Host "`tIPv6 unicast routing is disabled on this device" -ForegroundColor Red
        }

        Write-Host ""
    }

    if($badRouters.Count -eq 0){ return $true }
    else{
        $prompt = Read-Host "If you want to enable ipv6 unicast-routing on the misconfigured routers, press Y"
        if($prompt -eq "Y") {
            Fix-Unirouting -badRouters $badRouters
            main
        }
        else{ return $false }
    }
}

main
