# AD Lab — Day 8 Session Log

*Eighth entry in the project documentation. Today built **file services** — department shared folders locked down with group-based permissions — and proved department isolation. This is the session where the security groups from Day 6 finally get *used*, completing the "policy via OU, access via group" model.*

## Objective for Day 8

Create department file shares on DC01 and control access with permissions so that a Finance user can reach the Finance share but not HR's — using the security groups created on Day 6 as the access mechanism.

---

## Core concept: two permission systems that stack

A Windows share has **two separate permission layers**, and network access is the *most restrictive* combination of both:

- **Share permissions** — apply only when reaching the folder over the network (`\\DC01\Finance`). Coarse: Read / Change / Full Control on the whole share.
- **NTFS permissions** — apply always (network and local). Granular: per-folder/per-file, fine-grained rights.
- **Effective network access = the more restrictive of the two.** Share Full Control + NTFS Read = Read.

**Best practice used here:** keep Share permissions permissive and do the real access control in **NTFS**, so access is governed by one system instead of two overlapping ones. Being able to explain "most restrictive wins, so lock down with NTFS" is a common interview point.

---

## What was built

### 1. The folders
Created `C:\Shares` on DC01 with two department subfolders: `C:\Shares\Finance` and `C:\Shares\HR`. (Two departments is enough to prove isolation; the pattern repeats for IT/Sales.)

### 2. Share-level permissions
Each folder → Properties → Sharing → Advanced Sharing → "Share this folder" → Permissions. Removed **Everyone**, added the department group (**Finance-Team** on Finance, **HR-Team** on HR) with Change/Read. Network paths: `\\DC01\Finance` and `\\DC01\HR`. This layer kept simple/permissive by design.

### 3. NTFS permissions (the real control)
Each folder → Properties → Security → Advanced → **Disable inheritance** → "Convert inherited permissions into explicit permissions." Then **removed `CORP\Users`** (the broad group granting all domain users access), kept **SYSTEM** and **Administrators**, and added the department group (**Finance-Team** / **HR-Team**) with **Modify**.

*Key detail:* `CORP\Users` appeared as **two rows** (one "Read & execute," one "Special") — this is the **same group** shown across two permission entries; both were removed together. Disabling inheritance first is what made those inherited entries removable.

*Why remove Users:* by default the folder inherits permissions granting all domain users read access. Removing that inherited `Users` entry is what actually makes the share private to its department — without this step, both shares look locked down but everyone can still read them.

---

## Troubleshooting incident: access denied despite correct permissions

**Symptom:** the Finance user couldn't open the Finance share even though permissions looked correct.

**Root cause:** the user **was not actually a member of Finance-Team** — the group existed but hadn't been populated, so the NTFS permission (granted *to the group*) didn't reach her.

**Fix:** added the Finance users to **Finance-Team** in ADUC (Groups OU → Finance-Team → Properties → Members → Add). **Then the user had to log out and back in** — because group membership is baked into a user's **logon token at login**, so a membership change doesn't take effect until the next fresh sign-in (a lock/unlock isn't enough).

**Lesson (a real help-desk checklist):** when access is denied, three things must all line up —
1. **Resource permissions** are correct, **and**
2. the user is **a member of the group** that's granted access, **and**
3. the user has **logged in fresh** since the membership changed.
Missing any one produces "access denied" that looks like a permissions bug but isn't.

---

## Print services — deliberately scoped out

The plan pairs file *and* print services, but a print server with no physical printer demonstrates nothing. Print services was intentionally skipped — it's the same role family (a shared resource governed by permissions). Scoping it out is a reasonable engineering call, noted here rather than left as a silent gap.

---

## Verification

From CLIENT01, logged in fresh as a Finance user (`ekaur`): `\\DC01\Finance` **opened**, and `\\DC01\HR` was **denied**. Group-based department isolation confirmed.

---

## The model, now complete

This session completes the concept introduced on Day 4: **users live in OUs (which deliver policy) and belong to groups (which grant access)** — two separate mechanisms hanging off the same user. Day 7 proved the policy half (Control Panel blocked via OU-linked GPO); Day 8 proves the access half (file shares gated via group-based NTFS permissions). Both, built end to end.

---

## New concepts learned today

| Concept | What it is |
|---|---|
| **Share vs NTFS permissions** | Two permission layers; effective network access is the most restrictive of both. |
| **Most restrictive wins** | Why access control is best done in NTFS with permissive share permissions. |
| **NTFS inheritance** | Folders inherit parent permissions; disabling inheritance lets you remove inherited entries. |
| **Removing the Users group** | The step that actually makes a folder private, by cutting broad domain-user access. |
| **Access via group** | Granting NTFS permissions to a security group, not individual users. |
| **Logon token** | Group membership is evaluated at login; changes need a fresh sign-in to take effect. |
| **Access troubleshooting checklist** | Permissions + group membership + fresh login must all align. |

---

## Config reference (added today)

| Setting | Value |
|---|---|
| Finance share | `C:\Shares\Finance` → `\\DC01\Finance`; NTFS: Finance-Team = Modify; Users removed |
| HR share | `C:\Shares\HR` → `\\DC01\HR`; NTFS: HR-Team = Modify; Users removed |
| Group membership | Finance users added to Finance-Team (and HR users to HR-Team) |
| Print services | Intentionally scoped out (no physical printer) |

---

## Where things stand + next step

**Day 8 complete:** department file shares with group-based access control, isolation verified from the client. The full AD model — identity, addressing, name resolution, policy, and access — is now built and demonstrated.

**Next session (Day 9):** **documentation** — assemble the portfolio piece (network diagram, README, screenshots of the OU tree, a GPO applying, and the share isolation). Because these session logs were written all along, Day 9 is mostly assembly rather than reconstruction.
