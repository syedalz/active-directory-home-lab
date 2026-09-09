# AD Lab — Day 2 Session Log

*Second entry in the project documentation. Today DC01 went from a plain Windows Server to an actual **domain controller**, and the `corp.lab` domain was created. This log records every step and the reasoning behind it.*

## Objective for Day 2

Turn DC01 into a domain controller by installing Active Directory and creating a brand-new domain, `corp.lab`. This is the step where the domain — the thing every later piece (users, groups, policies, file shares) lives inside — actually comes into existence.

---

## The key concept: two separate phases

Promotion is **two distinct actions**, and understanding the split is the whole point:

1. **Install the AD DS role** — this only adds the *capability* to the server. Nothing changes about the network yet; the server just now *knows how* to be a domain controller.
2. **Promote the server** — this is the action that actually *creates the domain* and turns DC01 into a live domain controller.

Installing the role without promoting does nothing useful — a common point of confusion. You have to do both, in that order, because you can't promote using a capability the server doesn't have yet.

---

## Phase 1 — Install the Active Directory Domain Services (AD DS) role

**What:** Server Manager → Manage → Add Roles and Features → selected **Active Directory Domain Services** → accepted the prompt to "Add Features" (the supporting components AD DS depends on) → Install.

**Why:** AD DS is the role that provides Active Directory itself — the directory service that stores and manages users, computers, groups, and the policies applied to them. The "add required features" prompt appears because AD DS can't run alone; it needs supporting management tools and components, so Windows bundles them in automatically.

At the end of this phase the server *can* be a domain controller but isn't one yet — no domain exists.

---

## Phase 2 — Promote DC01 to a domain controller

Triggered by the **yellow warning flag** in Server Manager → "Promote this server to a domain controller." This opens the configuration wizard. Each screen, and why each choice was made:

### Deployment Configuration → "Add a new forest," root domain `corp.lab`

**What:** Chose **Add a new forest** and named the root domain `corp.lab`.

**Why "new forest":** a **forest** is the top-level container that holds an entire Active Directory — it's the outermost boundary for everything. Because DC01 is the *very first* domain controller, there's no existing domain or forest to join, so one has to be created from scratch. The other wizard options ("add a domain to an existing forest," "add a domain controller to an existing domain") are for expanding an environment that already exists — not this case. Here, `corp.lab` becomes both the new forest *and* its first domain.

**Why the name `corp.lab`:** it imitates a real company domain. `.lab` is used deliberately instead of a real public suffix so the lab can never be confused with a real internet domain.

### Domain Controller Options → functional levels, DNS, and the DSRM password

**What:** Left the **Forest and Domain functional levels** at their default (Windows Server 2016, the current highest level), kept **"Domain Name System (DNS) server"** checked, and set a **Directory Services Restore Mode (DSRM) password**.

**Why the functional levels:** these set the baseline of AD features available and the minimum Windows Server version other domain controllers are allowed to run. Leaving them at the default is correct for a single-DC lab — there's no older DC to stay compatible with.

**Why DNS stays checked:** this installs and configures the DNS service directly on DC01. Active Directory depends completely on DNS to function (clients locate the domain by asking DNS where the domain controller is). This checkbox is exactly *why* DC01's own DNS server was pointed at itself on Day 1 — it was being prepared to become the domain's DNS server, which it now is.

**Why the DSRM password:** Directory Services Restore Mode is a special recovery boot mode used to repair or restore Active Directory if it ever becomes corrupted. Its password is **separate** from the normal Administrator login and is only used in that break-glass recovery scenario. It was set and recorded securely (not written in this document, same as the Administrator password).

### DNS Options → the "delegation cannot be created" warning

**What:** Saw the warning *"A delegation for this DNS server cannot be created…"* and clicked Next anyway.

**Why it's safe to ignore:** a DNS delegation is a pointer created in a *parent* DNS zone so the wider internet can find this zone. In an isolated lab there is no parent zone (`.lab` isn't a real registered domain), so there's nothing to create a delegation in. The warning is expected and harmless here — it would only matter in a real, internet-connected environment.

### Additional Options → NetBIOS name

**What:** The **NetBIOS domain name** auto-filled as `CORP`; left it as-is.

**Why:** NetBIOS is the legacy short name for the domain, used by older protocols and still shown in the `CORP\username` login format. Windows derives it automatically from the first part of `corp.lab`. No reason to change it.

### Paths → left at defaults

**What:** Left the default folder locations for the AD database, log files, and SYSVOL.

**Why:** the defaults are fine for a lab; custom paths only matter in large production setups with dedicated storage.

### Prerequisites Check → Install → automatic reboot

**What:** The wizard ran a prerequisite check that showed a few yellow warnings (DNS delegation, default cryptography settings), then reported *"All prerequisite checks passed successfully."* Clicked **Install**; the server configured Active Directory and **rebooted itself**.

**Why the warnings didn't matter:** yellow warnings are advisory, not blocking — they flag things that would be tightened in production but are fine in a lab. Only a red error would stop the install. The automatic reboot is required because becoming a domain controller is a fundamental change to how the machine boots and authenticates.

---

## What the promotion actually did, behind the scenes

- Created the **Active Directory database** that stores every directory object (users, groups, computers).
- Created **SYSVOL**, a shared folder that holds group policies and logon scripts.
- Installed **DNS** and created the **`corp.lab` forward lookup zone** (the name→IP directory for the domain).
- Created the default directory containers (Users, Computers, Domain Controllers, Builtin).
- Converted the local **Administrator** account into the **domain** Administrator (`CORP\Administrator`), keeping the same password.
- Made DC01 a **Global Catalog** server (the first DC must be one — it's the index used for domain-wide searches and logins).

---

## Verification (how I confirmed it worked)

- **Login changed to `CORP\Administrator`** — the sign-in is now a domain account, not a local one. First confirmation.
- **DNS zone exists:** Tools → DNS → DC01 → Forward Lookup Zones showed a **`corp.lab`** zone.
- **Domain visible:** Tools → Active Directory Users and Computers showed the `corp.lab` domain with its default containers.
- **Name resolution works:** `nslookup corp.lab` at the command line returned **`192.168.20.10`** — proof the domain's DNS is live and resolving the domain name to DC01's address.

---

## New concepts learned today

| Concept | What it is |
|---|---|
| **Forest** | The top-level container/boundary for an entire Active Directory; the first DC creates one. |
| **Domain** | A managed group of users, computers, and resources under one directory (`corp.lab`). |
| **Domain controller** | A server running AD DS that authenticates logins and holds the directory. |
| **Global Catalog** | A forest-wide index used for searches and logins; the first DC must be one. |
| **Functional level** | Sets which AD features are available and the minimum DC OS version allowed. |
| **DSRM** | Directory Services Restore Mode — recovery mode (with its own password) for repairing AD. |
| **NetBIOS name** | The legacy short domain name (`CORP`), used in `CORP\user` logins. |
| **Forward lookup zone** | The DNS directory mapping names to IP addresses for the domain. |

---

## Config reference (added today)

| Setting | Value |
|---|---|
| Forest / root domain | `corp.lab` (new forest) |
| NetBIOS domain name | `CORP` |
| Functional level | Windows Server 2016 (default) |
| DNS | Installed on DC01; `corp.lab` forward lookup zone created |
| Global Catalog | DC01 (first DC) |
| DSRM password | Set and stored securely (not recorded here) |
| Domain admin login | `CORP\Administrator` (same password as before) |

---

## Where things stand + next step

**Day 2 complete:** DC01 is a live domain controller, the `corp.lab` domain exists, and DNS is up and resolving. Everything from here is built *inside* this domain.

**Next session (Day 3):** install and configure **DHCP** so the client machines (built later) automatically receive an IP address and are told to use DC01 as their DNS server — the same "hand out addresses + point clients at the DC" logic, now automated for the domain.
