# Disables a user account, removes it from a group, and transfers the user to a new OU

$userName = 'ssmith'
$userDN = (Get-ADUser $userName).DistinguishedName
$dept = 'IT'
Remove-ADGroupMember -Identity "$dept-Team" -Members $userName -Confirm:$false
Disable-ADAccount -Identity $userName
Move-ADObject -Identity $userDN -TargetPath "OU=Disabled Users,OU=Acme,DC=corp,DC=lab"
