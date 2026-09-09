# Windows Active Directory Home Lab

A fully functional single-domain Windows Server environment, built from scratch in a virtualized lab, covering the core of enterprise identity and infrastructure administration: Active Directory, DNS, DHCP, Group Policy, and permission-based file services — with a domain-joined client to demonstrate everything end to end.

> Built to develop and demonstrate hands-on Windows infrastructure skills: domain services, centralized policy, access control, PowerShell automation, and systematic troubleshooting.

---

## Overview

This project builds a small but complete Active Directory environment mirroring a real organization ("Acme"). A Windows Server 2022 machine is promoted to a domain controller and configured to provide identity, name resolution, and address assignment for the network; a Windows 11 client joins the domain and receives its configuration, policies, and resource access automatically. Everything runs on an isolated virtual network so the lab is fully self-contained.

The emphasis throughout is not just on *building* the environment, but on understanding *why* each component works the way it does — and on diagnosing the real failures that came up along the way (see [Troubleshooting](#troubleshooting-highlights)).

---

## Architecture

```
                    Host machine (VMware Workstation Pro)
        ┌──────────────────────────────────────────────────────┐
        │        Isolated virtual network — VMnet2 (host-only)  │
        │                   192.168.20.0/24                     │
        │                                                       │
        │   ┌───────────────────────┐   ┌───────────────────┐  │
        │   │        DC01           │   │     CLIENT01      │  │
        │   │  Windows Server 2022  │   │  Windows 11 Ent.  │  │
        │   │  Domain Controller    │   │  Domain-joined    │  │
        │   │  Roles: AD DS, DNS,   │   │  IP via DHCP      │  │
        │   │         DHCP          │◄──┤  DNS → DC01       │  │
        │   │  Static 192.168.20.10 │   │                   │  │
        │   │  Domain: corp.lab     │   │                   │  │
        │   └───────────────────────┘   └───────────────────┘  │
        └──────────────────────────────────────────────────────┘
```

*(Replace this ASCII sketch with the draw.io diagram — see `/docs`.)*

| Component | Details |
|---|---|
| **Domain** | `corp.lab` (single forest, single domain) |
| **DC01** | Windows Server 2022, Domain Controller — AD DS, DNS, DHCP. Static IP `192.168.20.10` |
| **CLIENT01** | Windows 11 Enterprise, domain-joined; IP + DNS assigned automatically via DHCP |
| **Network** | Isolated host-only network (VMnet2), `192.168.20.0/24`, no internet path |
| **Hypervisor** | VMware Workstation Pro |

---

## What was implemented

**Domain services**
- Promoted DC01 to a domain controller, creating a new forest and the `corp.lab` domain.
- Configured DNS (installed with AD) as the domain's authoritative name service.
- Configured DHCP with an active scope (`192.168.20.100–200`) that assigns clients an address and points them at the domain's DNS — so a client joins the network with zero manual configuration.

**Directory structure**
- Designed an Organizational Unit hierarchy mirroring a company: a top-level OU containing an Employees tree (IT / HR / Finance / Sales), plus Workstations and Groups OUs.
- Structured deliberately so Group Policy can target specific OUs and security groups can control access — the "policy via OU, access via group" model.

**Users and groups**
- Created user accounts across departments and department security groups.
- Automated bulk user provisioning with a **PowerShell script** (`New-ADUser` in a loop) — the real-world approach to account creation at scale. *(See `/scripts`.)*

**Group Policy**
- **Password policy** (domain-wide): enforced minimum length and complexity.
- **Login banner** (computer policy, linked to Workstations): an authorized-use notice shown at sign-in.
- **User restriction** (user policy, linked to Employees): disabled Control Panel access, inherited by all department sub-OUs.
- Verified enforcement on the client with `gpupdate` and `gpresult`.

**File services and access control**
- Created department file shares and secured them with combined **share and NTFS permissions**.
- Used security groups (not individual users) to grant access, and removed inherited broad-access entries so each share is private to its department.
- Verified isolation: a Finance user can open the Finance share but is denied the HR share.

---

## Skills demonstrated

- **Active Directory Domain Services** — forest/domain creation, OU design, users, groups, delegation model
- **DNS & DHCP** — authoritative DNS for the domain; DHCP scope and options
- **Group Policy** — computer vs user policy, OU linking and inheritance, verification
- **Access control** — NTFS vs share permissions, group-based security, permission inheritance
- **PowerShell** — automated user provisioning
- **Virtualization & networking** — VMware, isolated host-only networking, static vs dynamic addressing
- **Troubleshooting** — systematic, layer-by-layer diagnosis of real failures (below)

---

## Troubleshooting highlights

The most valuable part of the project. Each of these was a genuine failure that had to be diagnosed from a symptom down to a root cause:

- **Windows install blue-screen (BSOD).** A Windows guest kept crashing mid-install. Traced to a host virtualization-based-security (Memory Integrity) conflict with the hypervisor — a documented VMware issue. Resolved by disabling the conflicting host feature, and documented the reversible trade-off.

- **Client couldn't get on the network (APIPA `169.254` address).** A domain-join and later a Group Policy failure both came back to the client having no valid address. Diagnosed by working down the layers — VM power, network adapter, client address, DHCP scope, server authorization — to a **DHCP service that had lost sync with its Active Directory authorization**. Resolved by restarting the service to re-establish authorization, then renewing the client lease.

- **"Group Policy failed — no connectivity to a domain controller."** The presenting error pointed at policy, but the real cause was the DHCP issue above two layers down. A reminder that the first error you see is rarely the root cause.

- **Access denied despite correct permissions.** A user with correct NTFS permissions still couldn't reach a share. Cause: they weren't a member of the group the permission was granted to — and after being added, needed a fresh login because group membership is evaluated in the logon token at sign-in. Produced the practical checklist: *permissions + group membership + fresh login must all align.*

---

## Repository structure

```
/                     This README
/docs                 Network diagram + screenshots
/scripts              PowerShell (bulk user provisioning)
/session-logs         Day-by-day build logs with reasoning for each step
```

---

## What I learned

Building this end to end made the core of Active Directory concrete rather than theoretical: how a client goes from a blank machine to a fully managed domain member automatically, how policy and access are two separate mechanisms hanging off the same account, and — most of all — how infrastructure actually fails in practice (rarely a dramatic break, usually one setting out of sync) and how to isolate the cause methodically instead of guessing.

---

*Author: [Your Name] · Built [Month Year]*
