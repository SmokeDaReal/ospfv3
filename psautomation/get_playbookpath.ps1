#!/usr/bin/pwsh -Command

param(
	[Parameter(Mandatory = $true)][string]$PlaybookName
)

$parent = Split-Path $PSScriptRoot -Parent

return (Get-ChildItem (Join-Path $parent -ChildPath "playbooks") -Filter $PlaybookName -Recurse).FullName
