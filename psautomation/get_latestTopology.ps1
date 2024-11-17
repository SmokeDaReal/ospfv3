#!/usr/bin/pwsh -Command

$topologies = Get-ChildItem -Path (Join-Path $PSScriptRoot -ChildPath "topologies") -Filter "topology*.xml"

$latest = $topologies[0]
foreach($current in $topologies)
{
    if([int](($current.BaseName).Split('-')[1]) -gt [int](($latest.BaseName).Split('-')[1])){ $latest = $current }
}

return ($latest.FullName)
