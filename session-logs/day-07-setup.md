# AD Lab — Day 7 Session Log

*Seventh entry in the project documentation. Today built and applied **Group Policy** — the payoff for the OU structure — and watched policies enforce on CLIENT01. It also involved a substantial troubleshooting incident (a DHCP outage that blocked policy processing), which is written up here as the centerpiece because it's the most realistic sysadmin work in the whole lab.*

## Objective for Day 7

Create Group Policy Objects (GPOs) on DC01 and confirm they enforce on CLIENT01: a domain-wide password policy, a computer-targeted login banner, and a user-targeted restriction. The goal is to demonstrate centralized configuration management — set a rule once on the server, have clients obey it automatically.

---

## Core concept: GPOs target Computer or User settings, and apply to the OU they're linked to

Every GPO has two halves — **Computer Configuration** and **User Configuration** — and it only affects objects that live in (or inherit from) the OU it's linked to. Getting a policy to work is really two questions: *is the right setting in the right half*, and *is the GPO linked to an OU that contains the target object*.

---

## Prerequisite: moving CLIENT01 into the Workstations OU

When CLIENT01 joined the domain, its computer account landed in the default **Computers** container — which (as noted on Day 4) can't have GPOs linked to it. So before any computer-targeted policy could reach it, CLIENT01 was **moved from the Computers container into the Workstations OU** (ADUC → right-click → Move). This is what lets computer GPOs linked to Workstations actually apply.

---

## The three GPOs built

### 1. Password policy (domain level)
Edited the **Default Domain Policy** → Computer Configuration → Policies → Windows Settings → Security Settings → Account Policies → Password Policy. Set **minimum password length = 12** and confirmed **complexity = Enabled**.

*Why at the domain level:* domain-account password policy is controlled domain-wide through the Default Domain Policy — this is the one accepted case for editing that default GPO. A password policy linked to an ordinary OU would not govern domain logins.

### 2. Login banner (computer policy → Workstations OU)
Created a GPO named **"Login Banner,"** linked to the Workstations OU, and set Computer Configuration → Policies → Windows Settings → Security Settings → Local Policies → Security Options → **Interactive logon: Message title / Message text**. Wrote a realistic authorized-use notice (real banners establish consent to monitoring, not just "authorized users only"). Because it's a *computer* policy and CLIENT01 now lives in Workstations, it applies to that machine and shows at the login screen for anyone.

### 3. User restriction (user policy → Employees OU)
Created a GPO named **"User Restrictions,"** linked to the Employees OU, and enabled User Configuration → Policies → Administrative Templates → Control Panel → **Prohibit access to Control Panel and PC settings**. Linked at Employees so it flows to every department sub-OU (IT/HR/Finance/Sales) via **inheritance**, reaching all department users.

---

## Troubleshooting incident (the centerpiece): Group Policy failed — no connectivity to a domain controller

**Symptom:** running `gpupdate /force` on CLIENT01 returned a long error: *"Processing of Group Policy failed because of lack of network connectivity to a domain controller."*

**Diagnosis — worked down the layers:**
1. Confirmed **both VMs were powered on** — so it wasn't simply DC01 being off.
2. Checked CLIENT01's address (`ipconfig /all`): it had a **`169.254.x.x` (APIPA)** address — meaning it hadn't gotten a DHCP lease.
3. Verified CLIENT01's network adapter was correctly on **VMnet2** with "Connected" checked — client side was fine.
4. Went to DC01's **DHCP console**: the scope showed a **red arrow (inactive)**.
5. Tried to activate the scope — no Activate option; the console prompted to **authorize the DHCP server**.
6. Right-clicking the server to authorize returned *"The specified servers are already present in the directory service"* — i.e., AD said it *was* authorized, but the console still showed **red**. A sync mismatch between AD's authorization record and the local DHCP service.

**Root cause:** the DHCP Server service had lost sync with its Active Directory authorization (a known state after reboots / suspend-resume) — AD held the authorization record, but the running service wasn't honoring it, so it leased nothing.

**Fix:** restarted the **DHCP Server service** (`services.msc` → DHCP Server → Restart). The service re-read its authorization, the server node went **green**, and the scope became active. Then on CLIENT01: `ipconfig /release` + `ipconfig /renew` pulled a proper **`192.168.20.x`** address, and a reboot let Group Policy process cleanly.

**Why this is the best story in the lab:** the presenting error ("Group Policy failed") pointed at policy, but the real cause was two layers down (DHCP authorization out of sync). The fix required methodically ruling out each layer — VM power, network adapter, client address, DHCP scope, server authorization, the service itself — rather than guessing. That layer-by-layer isolation *is* the job of infrastructure troubleshooting.

---

## Verification

- **Login banner** appeared at CLIENT01's login screen before sign-in — computer GPO confirmed.
- Logged in as department user **`anguyen`**; first login **forced a password change** (Day 6's "change at next logon" flag), and the new password had to be **12+ characters** (Day 7's password policy) — two configured policies interacting live.
- **Control Panel was blocked** for that user — user GPO confirmed.
- `gpresult /r` as anguyen listed **User Restrictions** but not the banner — because a **non-admin user can only see the User half** of the report; the Computer half (where the banner lives) requires running `gpresult` **elevated**. Not a failure — a scope-visibility quirk worth knowing.

---

## New concepts learned today

| Concept | What it is |
|---|---|
| **GPO Computer vs User scope** | Each GPO has a computer half and a user half; the setting must go in the correct one. |
| **GPO linking & inheritance** | A GPO applies to objects in the linked OU and flows down to child OUs. |
| **Default Domain Policy** | The accepted place for domain-wide password/lockout/Kerberos policy. |
| **Moving objects into OUs** | Domain-joined computers land in the default Computers container and must be moved to an OU to receive linked GPOs. |
| **gpupdate /force** | Forces an immediate policy refresh instead of waiting for the periodic cycle. |
| **gpresult /r** | Reports applied GPOs, split into Computer and User settings; the computer half needs an elevated prompt. |
| **Computer vs user apply timing** | Computer policy applies at boot; user policy applies at logon. |
| **DHCP authorization sync** | The DHCP service can lose sync with its AD authorization; a service restart resolves it. |

---

## Config reference (added today)

| Setting | Value |
|---|---|
| CLIENT01 location | Moved to Acme → Workstations OU |
| Password policy | Min length 12, complexity enabled (Default Domain Policy) |
| GPO "Login Banner" | Computer policy, linked to Workstations OU (interactive logon message) |
| GPO "User Restrictions" | User policy, linked to Employees OU (prohibit Control Panel) |
| anguyen | Password changed at first login (now 12+ chars) |

---

## Where things stand + next step

**Day 7 complete:** three GPOs built, applied, and verified on CLIENT01 — after diagnosing and fixing a real DHCP outage that had blocked policy processing. Centralized management (identity, addressing, name resolution, and now policy) is demonstrated end to end.

**Next session (Day 8):** **file services** — create department shared folders and control access with NTFS and share permissions, using the security groups from Day 6, so a Finance user can reach the Finance share but not HR's. This is where the security groups finally get *used* for access.
