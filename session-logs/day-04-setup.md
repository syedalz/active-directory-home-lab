# AD Lab — Day 4 Session Log

*Fourth entry in the project documentation. Today built the **Organizational Unit (OU) structure** — the container layout the whole domain is organized into. This was a light build but a heavy *concepts* day, so this log leans into the reasoning: what OUs are, how they differ from groups and Group Policy, and why the structure is shaped the way it is.*

## Objective for Day 4

Design and build a set of Organizational Units that mirror a fictional company, giving the domain a clean structure for users, computers, and groups — and, crucially, giving Group Policy somewhere to attach. No roles installed; this is pure Active Directory design.

---

## The core concept: what an OU is, and why it's necessary

An **Organizational Unit (OU)** is a folder inside the domain that holds users, computers, and groups. Its two real jobs are to **organize** those objects and to serve as the **target for Group Policy**.

The single most important reason to build a custom OU structure: **the default "Users" and "Computers" folders that came with the domain are *containers*, and Group Policy cannot be linked to a container.** Policy can only be attached to an OU. So to apply any policy later (Day 7), you must first build your own OUs to hold your objects and receive that policy. The OU tree is the skeleton everything else hangs on.

---

## Two naming clarifications (both are common traps)

- **"Acme" is just a placeholder company name** — the generic stand-in business used in examples. It has zero technical meaning; it could be any name. It's simply the label for the top-level OU that holds all company objects.
- **The custom "Employees" OU is *not* the built-in "Users" container.** The domain ships with a folder literally called *Users* (a container, can't hold policy). The OU built today is a *separate* object, deliberately named **Employees** to avoid confusion with that built-in folder. Same idea for computers: the custom OU is named **Workstations** to keep it distinct from the built-in *Computers* container. *(If the user OU was left named "Users" instead of "Employees," the structure and reasoning are identical — only the label differs.)*

---

## The structure built

```
corp.lab
└── Acme                    ← top-level company OU (placeholder name)
    ├── Employees           ← user accounts (renamed from "Users" for clarity)
    │   ├── IT
    │   ├── HR
    │   ├── Finance
    │   └── Sales
    ├── Workstations        ← computer accounts
    └── Groups              ← security groups
```

All OUs were created with **"Protect container from accidental deletion"** left checked.

---

## Why this shape

- **Employees separated from Workstations:** Group Policy has a *User* half and a *Computer* half. Keeping user accounts and computer accounts in separate OUs lets user-focused policy target the Employees tree and machine-focused policy target Workstations, without overlap.
- **Department sub-OUs (IT/HR/Finance/Sales):** so each department can receive different policy and have its administration delegated separately. This is what makes it possible to demonstrate targeted policy on Day 7.
- **A dedicated Groups OU:** keeps security groups in one predictable place instead of scattered among user accounts, which keeps the directory navigable and keeps groups out of the way of user-targeted policy.

**Design note (interview-relevant):** this is an *object-type-first* layout (organize by what the object is: users vs computers vs groups). An alternative is *department-first* (an OU per department, each holding its own users/computers/groups). Neither is wrong — the choice depends on how an org delegates administration and applies policy. Object-type-first is simpler and common for a single site.

---

## The concept that took the most work: OU vs Group vs GPO

These three are easy to confuse (and the naming actively works against you). They are three different things doing three different jobs:

| Thing | What it is | What it's for |
|---|---|---|
| **OU** | A folder holding objects | Organizing objects **and** being the *target* Group Policy links to |
| **GPO (Group Policy Object)** | A bundle of settings | *Configuration* — password rules, screen lock, mapped drives, desktop lockdown. Linked to an OU. |
| **Group** | A bundle of user accounts | *Access* — granting a set of users permission to a resource (a file share, a printer) |

Key clarifications that resolved the confusion:

- **"Group Policy" has nothing to do with security groups** — despite the shared word. GPOs apply to **OUs**, not to groups. It's a naming collision in Windows.
- **Policy and access are two separate systems.** A GPO configures a user's *environment*; a group grants a user *access to resources*. Neither can do the other's job — you can't grant file-share access with a GPO, and you can't enforce a screen-lock with a group.
- **Permissions can only be assigned to a user or a group — never to an OU.** When setting who can open a shared folder, Windows only accepts users or security groups; an OU is not a valid entry. This is *why* groups must exist as their own objects even though the department OUs already contain the same people.

**How they cooperate on a single user:** an IT employee's account lives in the **IT OU** (so it catches IT's policy) *and* is a member of the **IT-Team group** (so it gets IT's resource access). One account, filed once for policy, enrolled once for access — two mechanisms working from two angles.

---

## New concepts learned today

| Concept | What it is |
|---|---|
| **Organizational Unit (OU)** | A policy-capable folder for organizing users, computers, and groups. |
| **Container vs OU** | The built-in Users/Computers folders are containers (no policy); OUs can hold policy. |
| **GPO (Group Policy Object)** | A bundle of enforced settings, linked to an OU. |
| **Security group** | A bundle of users used to grant access to resources. |
| **Protect from accidental deletion** | A safeguard flag on OUs; removing it requires View → Advanced Features. |

---

## Config reference (added today)

| Setting | Value |
|---|---|
| Top-level OU | `Acme` (placeholder company name) |
| User OU | `Employees` → sub-OUs: IT, HR, Finance, Sales |
| Computer OU | `Workstations` |
| Group OU | `Groups` |
| Accidental-deletion protection | Enabled on all OUs |

*(All OUs currently empty — populated with users and groups on Day 6.)*

---

## Where things stand + next step

**Day 4 complete:** the domain now has a clean OU structure mirroring a company, ready to receive users, groups, and policy.

**Next session (Day 5):** build the first **Windows 11 client VM** and **join it to `corp.lab`** — the proof-of-life step where DHCP, DNS, and the domain all get exercised at once, and a domain user logs into a machine for the first time.
