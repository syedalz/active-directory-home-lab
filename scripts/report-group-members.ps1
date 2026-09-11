# Returns list of members belonging to Finance Group

$groupName = "Finance-Team"
$groupMembers = Get-ADGroupMember -Identity $groupName
Write-Host "Finance team has $($groupMembers.Count) members:"
$groupMembers | Select-Object Name
