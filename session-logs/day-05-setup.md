# AD Lab — Day 5 Session Log

*Fifth entry in the project documentation. Today built the first client machine (CLIENT01, Windows 11) and joined it to the `corp.lab` domain. This is the "proof-of-life" session: DHCP, DNS, and the domain — everything built on Days 1–4 — all got exercised at once for the first time. Includes one troubleshooting incident worth keeping.*

## Objective for Day 5

Stand up a Windows 11 client VM, get it onto the isolated lab network, confirm it automatically receives its network configuration, and join it to the domain — proving the whole environment works end to end.

---

## Why Windows 11 **Enterprise** specifically

Used the Windows 11 Enterprise evaluation ISO. This matters: **Windows 11 Home cannot join a domain** — only Pro and Enterprise can. Since joining the domain is the entire purpose of the client, Home would have been a dead end.

---

## Two Windows 11 quirks that Windows Server didn't have

### 1. TPM 2.0 + Secure Boot requirement

Windows 11 refuses to install without UEFI firmware, Secure Boot, and a TPM 2.0 chip — none of which a plain VM has by default.

**How it was handled:** selecting "Windows 11 x64" as the guest OS type made VMware Workstation add the needed support automatically, including an **Encryption Information** step that sets up a virtual TPM (vTPM). VMware uses VM encryption to protect the TPM's key material, so the VM was configured to encrypt only the files needed for TPM support, with a password set. With the vTPM and Secure Boot in place, the Windows 11 requirements check passed without complaint.

### 2. The offline setup wall

Windows 11 setup (the "out-of-box experience," or OOBE) now pushes hard for a Microsoft account and an internet connection, and won't proceed past the network screen without one. But the client sits on the **isolated VMnet2 network with no internet on purpose**, so this screen became a hard block.

**How it was handled:** at the network screen, opened a command prompt with **Shift+F10** and ran the local-account bypass command (`start ms-cxh:localonly`; on some builds the older `OOBE\BYPASSNRO` is used instead — Microsoft keeps changing this). That launched a local-account setup, a simple local user was created, and OOBE completed to the desktop. This is expected behavior for an offline lab, not an error.

---

## The VM

| Setting | Value |
|---|---|
| Name | CLIENT01 |
| Guest OS | Windows 11 Enterprise (evaluation) |
| Resources | 4 GB RAM, 2 vCPU, 60 GB single-file disk |
| Firmware | UEFI + Secure Boot + vTPM (auto-configured) |
| Network adapter | Custom → **VMnet2** (same isolated network as DC01) |

Attaching to VMnet2 is essential — on any other network the client couldn't reach the domain controller.

---

## The payoff: DHCP and DNS worked automatically

Before joining the domain, ran `ipconfig /all` on the client and confirmed:

- **IPv4 address** in the `192.168.20.100–200` range — handed out by DC01's DHCP scope.
- **DNS server = `192.168.20.10`** — DC01, delivered automatically as part of the DHCP lease.

This is the whole point of Days 1–3 proving itself: the client booted with nothing, and without any manual configuration it received both an address and the correct DNS server. That's the DHCP "DORA" exchange in action — the client broadcast for a server, DC01 offered an address *plus* the DNS option, and the client applied it all. Because the DNS pointer was correct, the client could then find the domain.

---

## Joining the domain

The domain-join setting is buried in Windows 11's Settings app, so the reliable route was used: **Win+R → `sysdm.cpl`** → System Properties → Computer Name tab → Change → selected **Domain**, entered `corp.lab`, and authenticated with **CORP\Administrator** credentials. Got the **"Welcome to the corp.lab domain"** message, rebooted, and logged in as **CORP\Administrator** to confirm a domain login works end to end.

**Note:** logged in as the domain *Administrator* because that's the only domain account that exists so far. Regular department users get created on Day 6 — today just proves the join and the plumbing.

**Handy shortcut learned:** `sysdm.cpl` opens System Properties directly on any Windows version, regardless of how the Settings app has been rearranged. (`ncpa.cpl` similarly opens network adapters — both are worth remembering.)

---

## Troubleshooting incident: client got a `169.254.x.x` address (keep this)

**Symptom:** the first `ipconfig /all` showed an address like `169.254.x.x` instead of a `192.168.20.x` one — DHCP appeared to have failed.

**Root cause:** **DC01 had been powered off** (to save memory). With no DHCP server running, the client's request went unanswered, so Windows self-assigned an **APIPA** address (`169.254.x.x`) — the fallback a device gives itself when no DHCP server responds.

**Fix:** powered DC01 on and let it fully boot, then ran `ipconfig /renew` on the client to force a fresh DHCP request. The client immediately picked up a proper `192.168.20.x` address.

**Lesson worth keeping:** DC01 is the heart of the lab — it's the DHCP server, DNS server, *and* domain controller in one. Any time it's off, clients can't get addresses, resolve names, or log in. **Rule going forward: DC01 boots first and stays running whenever working with a client.** (A `169.254.x.x` address is now instantly recognizable as "the client couldn't reach DHCP.")

---

## New concepts learned today

| Concept | What it is |
|---|---|
| **APIPA (169.254.x.x)** | The address a device self-assigns when no DHCP server answers — a "couldn't reach DHCP" signal. |
| **TPM 2.0 / vTPM** | A security chip Windows 11 requires; VMware emulates it as a virtual TPM. |
| **Secure Boot / UEFI** | Modern firmware + boot-integrity features Windows 11 requires. |
| **OOBE** | The out-of-box experience — Windows' first-run setup wizard. |
| **Domain join** | Adding a computer to a domain so the domain manages its authentication. |
| **Domain login** | Logging into a machine with an account that lives on the DC, not on the local computer. |
| **DORA** | The 4-step DHCP exchange: Discover, Offer, Request, Acknowledge. |

---

## Config reference (added today)

| Setting | Value |
|---|---|
| Client VM | CLIENT01 — Windows 11 Enterprise (eval) |
| Resources | 4 GB RAM, 2 vCPU, 60 GB, vTPM + encryption |
| Network | VMnet2 (isolated) |
| Local account | Created offline during OOBE |
| DHCP-assigned address | `192.168.20.x` (from DC01 scope) |
| DNS server received | `192.168.20.10` (DC01) |
| Domain | Joined to `corp.lab` |
| Verified login | `CORP\Administrator` |

---

## Where things stand + next step

**Day 5 complete:** CLIENT01 is a domain-joined Windows 11 machine, receiving its network config automatically and able to log in against the domain. The environment now works end to end.

**Next session (Day 6):** create the actual **user accounts and security groups** — populating the OU structure from Day 4 with ~15–20 users across departments and the groups that will control resource access. This is where the domain starts behaving like a real organization, and it's the most job-representative day of the build.
