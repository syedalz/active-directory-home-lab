# AD Lab — Day 3 Session Log

*Third entry in the project documentation. Today added **DHCP** to DC01 so that client machines will automatically receive an IP address and be told to use the domain controller for DNS. Written with the reasoning behind each step, since the "why" is what makes DHCP make sense.*

## Objective for Day 3

Set up DHCP on DC01 so future client machines get their network configuration automatically — an IP address, and (critically) the address of the DNS server they should use. Without this, every client would have to be configured by hand, and wouldn't know how to find the domain.

---

## What DHCP is, in plain terms

**DHCP (Dynamic Host Configuration Protocol) is the service that automatically hands a device its network settings the moment it joins the network.** When your phone connects to WiFi and just works without you typing in any numbers, that's DHCP doing its job behind the scenes.

A useful analogy: DHCP is like a hotel front desk. A guest arrives (a device joins the network), the desk assigns them a room number for the length of their stay (an IP address, on a time-limited **lease**), and hands them a map showing where things are (which DNS server to use). When the guest checks out, the room frees up for the next person. That "assign, lease, recycle" cycle is exactly what DHCP does with IP addresses.

In this lab, DC01 becomes that front desk for the `corp.lab` network.

---

## The two-phase pattern (same as Day 2)

Like installing Active Directory, DHCP is **install the role, then configure it**:

1. **Install the DHCP Server role** — adds the capability. No addresses get handed out yet.
2. **Authorize it and create a scope** — this is what actually makes it start serving addresses.

---

## Phase 1 — Install the DHCP Server role

**What:** Server Manager → Manage → Add Roles and Features → checked **DHCP Server** → accepted the "Add Features" prompt → Install.

**Why:** this adds the DHCP service to the server. As with AD DS on Day 2, installing the role only gives the server the *ability* to run DHCP — it doesn't hand out a single address until it's configured.

---

## Phase 2 — Authorize DHCP in Active Directory

**What:** After install, a notification flag in Server Manager said **"Complete DHCP configuration."** Clicked it → wizard → used the current **CORP\Administrator** credentials → **Commit** → Close.

**Why this step exists:** in an Active Directory environment, a DHCP server is **not allowed to hand out addresses until it has been authorized in AD**. This is a deliberate security safeguard. Because a DHCP server controls what addresses and DNS settings every device receives, a rogue or misconfigured one could hijack or break the whole network. Requiring authorization in AD means only servers an administrator has explicitly approved can serve addresses. Skip this and the scope you create later just sits there inactive.

This step also creates the DHCP security groups that control who can administer the service.

---

## Phase 3 — Create the scope

A **scope** is the pool of IP addresses a DHCP server is allowed to hand out on a network, together with the extra settings (like DNS) sent along with them. Built via: Tools → DHCP → expand **dc01.corp.lab** → right-click **IPv4** → **New Scope**.

Each screen of the New Scope Wizard and the reasoning:

### Scope name
**What:** named it "Corp LAN." **Why:** purely a label for the administrator; no functional effect.

### IP Address Range
**What:** Start `192.168.20.100`, End `192.168.20.200`, Length `24` (mask `255.255.255.0`).

**Why this range specifically:** it hands out only `.100` through `.200` to clients, which deliberately leaves the lower addresses (`.1`–`.99`) free for servers and other devices that need a **fixed** address — DC01 itself sits at `.10`. Keeping dynamically-assigned client addresses in a separate band from static server addresses prevents collisions and keeps the addressing easy to reason about. The `/24` mask matches the subnet set up on Day 1, so every address handed out is on the same network as DC01.

### Add Exclusions
**What:** skipped. **Why:** exclusions carve out addresses *inside* the range that DHCP should not give away. DC01 at `.10` is already outside the `.100`–`.200` range, so nothing needs excluding.

### Lease Duration
**What:** left the default (8 days).

**Why:** the lease is how long a client keeps its assigned address before it must renew. When a device leaves and its lease expires, the address returns to the pool for reuse — this is what stops the server from running out of addresses over time. Eight days is a sensible default and there's no reason to change it in a lab.

### Configure DHCP Options → Router (Default Gateway)
**What:** chose to configure options now, then left the **gateway blank**.

**Why:** the default gateway is the address of the router that leads *out* of the local network to the internet. This is an isolated lab with no internet path, so there's no gateway to hand out — leaving it blank is correct.

### Domain Name and DNS Servers (the critical screen)
**What:** confirmed Parent domain = `corp.lab`, and DNS server = `192.168.20.10` (DC01).

**Why this is the most important setting on the whole wizard:** this is what tells every client "your DNS server is DC01." Because Active Directory clients *find* the domain by asking DNS where the domain controller is, a client that isn't pointed at the domain's DNS server simply cannot locate or join `corp.lab` — even if it has a perfectly good IP address. This single option is the bridge between "the client has network access" and "the client can use the domain." If a client later gets an address but can't join the domain, this is the first thing to check.

### WINS Servers
**What:** left blank. **Why:** WINS is a legacy name-resolution service superseded by DNS; not needed.

### Activate Scope
**What:** chose "Yes, activate this scope now" → Finish.

**Why:** a scope has to be activated before it will lease any addresses. Activating is the on-switch.

---

## Verification

In the DHCP console, the scope under IPv4 shows a **green up-arrow**, meaning it's active and ready to lease addresses.

**Note on testing:** DHCP can't be fully tested today, and that's expected — a DHCP server only proves itself when a real machine asks it for an address, and there are no client machines yet (those come on Day 5). The "done" signal for today is the active scope. The real payoff comes when CLIENT01 boots on Day 5 and automatically receives a `192.168.20.1xx` address with DC01 already set as its DNS.

---

## Troubleshooting: "New Scope" was greyed out

**Symptom:** the "New Scope" option couldn't be selected.

**Cause and fix:** "New Scope" only appears when right-clicking the **IPv4** node specifically — not the server name and not the top "DHCP" root. Expanding the server and right-clicking IPv4 directly makes it selectable. (If it's still greyed after that, the usual culprits are a stale console — fixed by pressing F5 or closing and reopening the DHCP console — or the server not being authorized yet, shown by a red down-arrow on the server node, fixed by right-clicking the server → Authorize.)

**Lesson worth keeping:** in the Windows management consoles, the available actions depend on exactly which node is selected. Right-clicking the correct level of the tree matters.

---

## New concepts learned today

| Concept | What it is |
|---|---|
| **DHCP** | Service that automatically assigns IP addresses and network settings to devices. |
| **Scope** | The pool of addresses a DHCP server hands out on a network, plus associated options. |
| **Lease** | A time-limited assignment of an address to a client; expires and recycles when unused. |
| **DHCP authorization** | AD safeguard requiring a DHCP server to be approved before it can serve addresses. |
| **DHCP options** | Extra settings sent with an address — gateway, DNS server, domain name. |
| **Default gateway** | The router address that leads out of the local network (none, in this isolated lab). |

---

## Config reference (added today)

| Setting | Value |
|---|---|
| DHCP role | Installed on DC01, authorized in AD |
| Scope name | Corp LAN |
| Address range | `192.168.20.100` – `192.168.20.200` |
| Subnet mask | `255.255.255.0` (/24) |
| Lease duration | 8 days (default) |
| Default gateway | None (isolated lab) |
| DNS server option | `192.168.20.10` (DC01) |
| DNS domain option | `corp.lab` |
| WINS | None |
| Scope status | Active |

---

## Where things stand + next step

**Day 3 complete:** DC01 now runs DHCP with an active scope that will automatically give client machines an address and point them at the domain's DNS.

**Next session (Day 4):** design and build the **Organizational Unit (OU) structure** — the container layout that mirrors a company (departments, users, workstations, groups). No new roles; it's pure Active Directory design, and it comes before creating users and policies because Group Policy attaches to OUs, so the structure is the skeleton everything else hangs on.
