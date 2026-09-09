<#
.SYNOPSIS
    Bulk-creates Active Directory user accounts across department OUs.

.DESCRIPTION
    Creates demo users in the corp.lab domain, placing each in the correct
    department OU under Acme > Employees, and forcing a password change at
    first logon. The temporary password is prompted for at runtime rather
    than hard-coded, so no credentials are ever committed to source control.

.NOTES
    Run on the domain controller (DC01) in an ELEVATED PowerShell session.
    Requires the ActiveDirectory module (present by default on a DC).
    Adjust $EmployeesOU and the Dept values if your OU structure differs.
#>

# Prompt for the temporary password at runtime (kept out of source control)
$password = Read-Host -AsSecureString "Enter the temporary password for new users"

# Base distinguished name for the Employees OU (edit to match your structure)
$EmployeesOU = "OU=Employees,OU=Acme,DC=corp,DC=lab"

# Users to create. 'Dept' must match an OU that exists under Employees.
$users = @(
    @{First="Alice";  Last="Nguyen"; User="anguyen"; Dept="IT"},
    @{First="Bob";    Last="Singh";  User="bsingh";  Dept="IT"},
    @{First="Carol";  Last="Diaz";   User="cdiaz";   Dept="HR"},
    @{First="David";  Last="Okafor"; User="dokafor"; Dept="HR"},
    @{First="Eva";    Last="Kaur";   User="ekaur";   Dept="Finance"},
    @{First="Frank";  Last="Muller"; User="fmuller"; Dept="Finance"},
    @{First="Grace";  Last="Lee";    User="glee";    Dept="Finance"},
    @{First="Hassan"; Last="Ali";    User="hali";    Dept="Sales"},
    @{First="Ivy";    Last="Chen";   User="ichen";   Dept="Sales"},
    @{First="Jack";   Last="Brown";  User="jbrown";  Dept="Sales"}
)

foreach ($u in $users) {
    $ou = "OU=$($u.Dept),$EmployeesOU"
    try {
        New-ADUser -Name "$($u.First) $($u.Last)" `
            -GivenName $u.First -Surname $u.Last `
            -SamAccountName $u.User `
            -UserPrincipalName "$($u.User)@corp.lab" `
            -Path $ou `
            -AccountPassword $password `
            -Enabled $true `
            -ChangePasswordAtLogon $true
        Write-Host "Created $($u.First) $($u.Last) in $($u.Dept)" -ForegroundColor Green
    }
    catch {
        Write-Warning "Failed to create $($u.User): $($_.Exception.Message)"
    }
}
