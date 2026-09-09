# AD Lab — Day 6 Session Log

*Sixth entry in the project documentation. Today populated the domain with **user accounts and security groups** — the point where the directory stops being empty structure and becomes a working organization. Includes the PowerShell script used for bulk creation, and the VMware Tools fix needed to run it.*

## Objective for Day 6

Fill the OU structure from Day 4 with real objects: user accounts placed in their department OUs, and the security groups that will later control who can access which resources. Approach used: create one user by hand to learn the anatomy, then bulk-create the rest with PowerShell (the real-world way, and far faster than the GUI wizard).

---

## Part 1 — User account anatomy (created by hand)

Created one user manually in Active Directory Users and Computers (Acme → Employees → IT OU → New → User) to understand the key fields:

- **Full name** — the display name shown in the directory.
- **User logon name / UPN** — e.g. `jsmith@corp.lab`. This is what the user actually signs in with; the part before the `@` (the SamAccountName) is the older short form.
- **Password** — must satisfy the domain's default complexity rules (upper + lower + number/symbol, 7+ characters).
- **User must change password at next logon** — left checked. This is standard practice: the admin sets a temporary password, and the user replaces it with their own private one on first login, so the admin never knows the real password.
- **Password never expires** — left unchecked (passwords should expire).

Creating one by hand made clear exactly what the bulk script would automate.

---

## Part 2 — Security groups

Created four department groups in the Groups OU (New → Group): **IT-Team, HR-Team, Finance-Team, Sales-Team**. Each with:

- **Group type = Security** — this is what lets a group be used to grant access to resources (files, printers). The alternative, a *Distribution* group, is only for email lists and can't hold permissions.
- **Group scope = Global** — the standard scope for organizing users by department in a single-domain setup.

These groups are the access mechanism: on Day 8 they'll be attached to file shares so that group membership decides who can open what.

---

## Part 3 — Group membership and nesting

- **Membership:** added the hand-created user to IT-Team (group Properties → Members → Add). Membership is what actually ties a user to the access a group grants.
- **Nesting (optional, done):** created an **All-Staff** group and added the four department groups *as members of it* — a group inside a group. Anything granted to All-Staff then flows automatically to everyone in every department team. Nesting is how real organizations avoid managing access one person at a time.

---

## Part 4 — Bulk creation with PowerShell

Creating 10+ users through the GUI wizard would be tedious and error-prone, so the rest were created with a script — which is how IT actually provisions accounts at scale.

### The clipboard fix (VMware Tools)

The script wouldn't paste into the VM at first, because **VMware Tools was not installed on DC01**. VMware Tools is the guest add-on that enables copy/paste between host and VM (plus proper screen resolution and smoother mouse). Fixed by: VM menu → Install VMware Tools → run setup from the mounted DVD inside DC01 → reboot. This improves the whole lab, not just paste.

The script was then pasted into **PowerShell ISE** (a proper script editor) rather than the plain console — ISE handles multi-line scripts cleanly, whereas the plain console can run lines prematurely on paste.

### The script used

```powershell
# --- Bulk-create lab users across departments ---
$password = ConvertTo-SecureString "Passw0rd!2025" -AsPlainText -Force

$users = @(
    @{First="Alice";   Last="Nguyen";  User="anguyen";  Dept="IT"},
    @{First="Bob";     Last="Singh";   User="bsingh";   Dept="IT"},
    @{First="Carol";   Last="Diaz";    User="cdiaz";    Dept="HR"},
    @{First="David";   Last="Okafor";  User="dokafor";  Dept="HR"},
    @{First="Eva";     Last="Kaur";    User="ekaur";    Dept="Finance"},
    @{First="Frank";   Last="Muller";  User="fmuller";  Dept="Finance"},
    @{First="Grace";   Last="Lee";     User="glee";     Dept="Finance"},
    @{First="Hassan";  Last="Ali";     User="hali";     Dept="Sales"},
    @{First="Ivy";     Last="Chen";    User="ichen";    Dept="Sales"},
    @{First="Jack";    Last="Brown";   User="jbrown";   Dept="Sales"}
)

foreach ($u in $users) {
    $ou = "OU=$($u.Dept),OU=Employees,OU=Acme,DC=corp,DC=lab"
    New-ADUser -Name "$($u.First) $($u.Last)" -GivenName $u.First -Surname $u.Last `
        -SamAccountName $u.User -UserPrincipalName "$($u.User)@corp.lab" `
        -Path $ou -AccountPassword $password -Enabled $true -ChangePasswordAtLogon $true
    Write-Host "Created $($u.First) $($u.Last) in $($u.Dept)"
}
```

### How the script works

- **`ConvertTo-SecureString`** converts a plain-text password into the encrypted form `New-ADUser` requires; set once, reused for all users.
- **The `$users` array** is the list of people — each `@{...}` is one user's data.
- **The `foreach` loop** runs `New-ADUser` once per person, building the correct OU path from each user's department automatically.
- **`-ChangePasswordAtLogon $true`** forces each user to set their own password at first login (same as the GUI checkbox).
- **`Write-Host`** prints a confirmation line per user.

The OU path (`OU=Employees,OU=Acme,...`) has to match the actual OU names, or every line fails with a "directory object not found" error — a reminder that the distinguished-name path reads most-specific-first.

*Note: the script above was provided and used as a walkthrough this session. The plan is to re-author scripts like this from scratch as part of Project 2, since writing them (not running them) is where the actual skill is built.*

---

## Security note (for the portfolio repo)

The lab default password appears in the script above for lab convenience only. **When this project goes into a public repo, real passwords must not be committed** — they'd be replaced with a prompt, a parameter, or a reference to a secrets store. Modeling that habit matters for a security-focused portfolio.

---

## New concepts learned today

| Concept | What it is |
|---|---|
| **SamAccountName / UPN** | A user's short logon name and their full `user@domain` login name. |
| **Password complexity / change-at-logon** | Default rules a password must meet; forcing a reset on first login. |
| **Security vs Distribution group** | Security groups grant access; Distribution groups are email-only. |
| **Group scope (Global)** | The standard scope for department groups in a single domain. |
| **Group nesting** | Placing a group inside another group so access flows through. |
| **New-ADUser** | The PowerShell cmdlet that creates AD user accounts. |
| **ConvertTo-SecureString** | Converts a plain password into the encrypted form cmdlets require. |
| **VMware Tools** | Guest add-on enabling clipboard, resolution, and smoother integration. |

---

## Config reference (added today)

| Setting | Value |
|---|---|
| Users | 1 created by hand + 10 via script, across IT/HR/Finance/Sales |
| Department groups | IT-Team, HR-Team, Finance-Team, Sales-Team (Global, Security) |
| Nested group | All-Staff (contains the four department groups) |
| Password policy on accounts | Change required at first logon |
| VMware Tools | Installed on DC01 |

---

## Where things stand + next step

**Day 6 complete:** the domain now contains users organized into department OUs and the security groups that will govern access. It finally looks and behaves like a real organization.

**Next session (Day 7):** create **Group Policy Objects (GPOs)** — write policies on DC01 (a password policy, a desktop/security lockdown, a mapped drive) and watch them enforce on CLIENT01 when a user logs in. This is the payoff for building the OU structure, since GPOs link to those OUs.
