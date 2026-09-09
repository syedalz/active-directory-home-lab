# AD Lab — Day 1 Session Log

*The first entry in this project's documentation. It records what was set up, what was downloaded, which versions/options were chosen, and the reasoning behind each — including one real troubleshooting incident worth keeping as an interview story.*

## Objective for Day 1

Stand up the foundation of a Windows Active Directory lab: install the virtualization software, build an isolated lab network, create the first virtual machine, install Windows Server on it, and prepare that server to become a domain controller (rename + static IP). The domain itself gets created in the next session.

---

## What was downloaded, and why these versions

| Item | Version chosen | Source | Why this one |
|---|---|---|---|
| **VMware Workstation Pro** | 26H1 (latest build) | Broadcom support portal (free personal-use account) | Chosen over Hyper-V and VirtualBox because the sysadmin job postings name VMware **vCenter/ESXi** — learning VMware's model has direct resume value. The **latest** build was chosen deliberately: newer versions have the best Windows 11 host compatibility, which matters because older builds handle the host security features (see the BSOD incident below) far worse. |
| **Windows Server 2022** | Standard, **Desktop Experience**, 180-day evaluation | Microsoft Evaluation Center | Server 2022 is the mainstream enterprise Windows Server release, so it's what job postings actually reference. **Standard** (not Datacenter) is plenty for a lab. **Desktop Experience** = the version with a graphical desktop, chosen over Server Core (text-only) because it's far easier to learn on. The **evaluation** edition is free, needs no license key, and 180 days is more than enough for this lab. |
| Windows 11 ISO | *(not yet — needed later)* | Microsoft Evaluation Center | Will be needed to build the client machines around Day 5. Deferred to save disk space until needed. |

---

## Host preparation — freeing the CPU for VMware

**The problem being solved:** VMware runs virtual machines best when it has *direct* access to the CPU's hardware virtualization features. But Windows' own hypervisor (used by Hyper-V, WSL2, Windows Sandbox, and the Memory Integrity security feature) grabs those same features first and locks VMware out, forcing it into a slower, less stable mode. So these had to be turned off:

- **Windows Features unchecked:** *Virtual Machine Platform* and *Windows Hypervisor Platform*. (Hyper-V and Windows Sandbox weren't present at all — this machine runs **Windows 11 Home**, which doesn't ship those features. That's normal, not a problem.) Windows Subsystem for Linux was also unchecked, though that was belt-and-suspenders — disabling Virtual Machine Platform already stops WSL2.
- **Boot setting changed:** ran `bcdedit /set hypervisorlaunchtype off` from an admin prompt. This is a *separate* switch from the Windows Features checkboxes — it stops the Windows hypervisor from launching at startup. Unchecking the features alone isn't enough; without this command the hypervisor can still start at boot and quietly steal the virtualization from VMware. This is the step most tutorials cause people to skip.
- **CPU virtualization** was confirmed enabled (Task Manager → Performance → CPU → "Virtualization: Enabled").

**Memory Integrity** was initially left **ON**, to preserve that security protection. This decision was reversed later in the session — see below.

---

## The isolated lab network

Built in VMware's **Virtual Network Editor**: added **VMnet2**, set to **Host-only**, with **"Use local DHCP service" unchecked**.

**Why host-only with DHCP off:** the domain controller is going to serve DHCP and DNS itself. A host-only network walls the lab off from the real home network, and turning VMware's own DHCP off means the DC won't fight the home router over handing out IP addresses. The lab becomes fully self-contained and safe to break.

**Subnet:** a clash appeared because VMnet1 (a VMware default) already used `192.168.10.0`. Two networks can't share a subnet, so VMnet2 was moved to **`192.168.20.0 / 255.255.255.0`**. This is why all lab addressing uses the **`192.168.20.x`** range. The specific numbers are arbitrary — the only requirement is one unused subnet.

---

## Creating the DC01 virtual machine

Built via the New VM wizard with these choices:

- **"I will install the operating system later"** — chosen to skip VMware's "Easy Install," which would otherwise auto-pick the edition and disk layout. Manual control was wanted so the *Desktop Experience* edition could be selected deliberately.
- **Guest OS:** Windows Server 2022
- **Name:** DC01
- **Disk:** 60 GB, stored as a single file (thin-provisioned — this is a ceiling, not space used immediately; it grows as the server fills)
- **RAM:** 4 GB · **CPU:** 2 cores — sized to fit comfortably on the 16 GB host
- **Network adapter:** set to **Custom → VMnet2** (the easy-to-miss step that actually attaches the VM to the isolated network)
- **CD/DVD:** pointed at the Server 2022 ISO

---

## Troubleshooting incident: install BSOD (keep this as an interview story)

**Symptom:** the first Windows Server install crashed partway through with a "Your PC ran into a problem" blue screen.

**Root cause:** a documented VMware conflict. With **Memory Integrity** left on, the host runs in "VBS mode" (Virtualization-Based Security). VMware's own knowledge base documents that Windows guests can blue-screen inside VMware Workstation specifically when the host is in this mode. So the crash wasn't random — it was the direct consequence of leaving Memory Integrity on.

**Fix:** turned **Memory Integrity off** (Windows Security → Device security → Core isolation details), rebooted, deleted the half-formed partitions left by the crashed attempt (down to a single "Unallocated Space"), and reinstalled. It completed cleanly, confirming the diagnosis.

**Important reversibility note:** Memory Integrity is off *only for the duration of building this lab* — it's a temporary, reversible state. When the lab is finished, turn it back on. Because Memory Integrity depends on the hypervisor that `hypervisorlaunchtype off` disabled, restoring real protection later requires **both** turning the toggle on **and** running `bcdedit /set hypervisorlaunchtype auto`, then rebooting.

---

## Windows Server install + post-install config

- Installed **Windows Server 2022 Standard (Desktop Experience)** via a Custom (clean) install onto the cleaned disk.
- Set an **Administrator password** (stored securely by me — not recorded in this document on purpose).
- **Renamed the machine to `DC01`** and rebooted. Done *before* promotion because the name becomes the DC's permanent identity in the domain — changing it after promotion is a headache.
- **Set a static IP.** A domain controller's address must never change, and it must be set before the DC starts serving DNS:
  - IP: `192.168.20.10`
  - Subnet mask: `255.255.255.0`
  - Gateway: *(blank — isolated lab, no internet path)*
  - Preferred DNS: `192.168.20.10` — **pointed at itself**, because this machine is about to become the domain's DNS server, so it must resolve names via itself.
  - Verified with `ipconfig /all`. No reboot needed — network settings apply immediately (unlike the rename).

---

## Key configuration reference

| Setting | Value |
|---|---|
| Hypervisor | VMware Workstation Pro 26H1 |
| Guest OS | Windows Server 2022 Standard (Desktop Experience), 180-day eval |
| VM name | DC01 |
| VM resources | 4 GB RAM, 2 vCPU, 60 GB single-file disk |
| Lab network | VMnet2 · Host-only · DHCP off · `192.168.20.0/24` |
| DC01 static IP | `192.168.20.10` / `255.255.255.0` · gateway none · DNS → self |
| Planned domain name | `corp.lab` |
| Host security state | Memory Integrity OFF · `hypervisorlaunchtype off` · Virtual Machine Platform + Windows Hypervisor Platform disabled |

---

## Where things stand + next steps

**Day 1 is complete:** VMware installed, isolated network built, DC01 running Windows Server 2022, renamed, and given a static IP.

**Next session (Day 2):** promote DC01 to a domain controller — install the Active Directory Domain Services role and create the **`corp.lab`** domain. This is the step where the domain actually comes into existence, and DNS gets installed alongside it (which is why DC01's DNS already points at itself).

**Outstanding to-dos:**
- Download the Windows 11 evaluation ISO before the client-build step (~Day 5).
- When the whole lab is finished: turn Memory Integrity back on (toggle **plus** `bcdedit ... auto`) to restore host security.
