#!/usr/bin/pwsh -Command

Write-Host "Updating the host variable files for Ansible based on the latest topology.xml"
Invoke-Expression "./generateHostVarsfromXML.ps1"

Write-Host "----------Checking IPv6 unicast routing----------`n"
if(!(Invoke-Expression "./checkIpv6unirouting.ps1")) { exit }

Write-Host "----------Checking IPv6 addresses----------`n"
if(!(Invoke-Expression "./checkInterfaceaddresses.ps1")) { exit }

Write-Host "----------Checking if OSPFv3 is enabled----------`n"
if(!(Invoke-Expression "./checkOspfEnabled.ps1")) { exit }

Write-Host "----------Checking which interfaces participate in OSPFv3 communication----------`n"
if(!(Invoke-Expression "./checkIpv6ospfint.ps1")) { exit }

Write-Host "----------Checking OSPFv3 neighbor states----------`n"
if(!(Invoke-Expression "./checkIpv6ospfneighbor.ps1")) { exit }
