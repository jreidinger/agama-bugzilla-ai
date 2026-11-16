# Agama Team Members & Roster Reference

This document is the single source of truth for the Agama team members, Bugzilla identifiers, mailing lists, and domain expertise.

---

## 1. Team Members Roster

| Name | Primary Email (Bugzilla) | Expertise Areas | Other Duties | Backup Expert(s) for Domain |
| :--- | :--- | :--- | :--- | :--- |
| **Ancor González** | `ancor@suse.com` | Storage | PO | Storage: Iván |
| **David Díaz** | `dgonzalez@suse.com` | UI/UX | — | — |
| **Imobach González** | `igonzalezsosa@suse.com` | Architecture, auto-installation | Product architect | Architecture: Iván, Josef |
| **Iván López** | `jlopez@suse.com` | Architecture, Storage | Retros, meetings, team stuff | Storage: Ancor / Architecture: Imobach, Josef |
| **Josef Reidinger** | `jreidinger@suse.com` | Architecture, Software, Bootloader, Registration | Jack-of-all-trades | Architecture: Imobach, Iván / Software: Ladislav |
| **Knut Anderssen** | `kanderssen@suse.com` | Network | — | Network: Michal |
| **Ladislav Slezák** | `lslezak@suse.com` | Live image, software stack | — | Software: Josef |
| **Michal Filka** | `mfilka@suse.com` | Devel tools, Network | Bugs maintenance | Network: Knut |
| **Lukas Ocilka** | `locilka@suse.com` | *(None listed)* | Team lead, PO | — |

---

## 2. Key Domain Backup Pairings ("No Silo" Rule)

When an individual team member has a `needinfo?` pending for $\ge$ 1 day and is unavailable or unresponsive, the maintainer should ping their domain backup:

- **Storage**: **Ancor González** ⟷ **Iván López**
- **Network**: **Knut Anderssen** ⟷ **Michal Filka**
- **Software Stack**: **Josef Reidinger** ⟷ **Ladislav Slezák**
- **Architecture**: **Imobach González** ⟷ **Iván López** ⟷ **Josef Reidinger**
- **Auto-installation**: **Imobach González** (and `autoyast-maintainers@suse.de`)
- **Live image**: **Ladislav Slezák**
- **Bootloader & Registration**: **Josef Reidinger**
- **UI/UX**: **David Díaz**

---

## 3. Team Mailing Lists (Answer Immediately)

When `needinfo?` is requested on these lists, the sprint maintainer must answer **immediately** (no grace period):

| List Handle / Alias | Email Address | Purpose |
| :--- | :--- | :--- |
| `yast-maintainers` | `yast-maintainers@suse.de` | Default assignee for incoming bugs for YaST and Agama |
| `yast-internal` | `yast-internal@suse.de` | Bugs assigned to Installer team, shared for both YaST and Agama |
| `autoyast-maintainers` | `autoyast-maintainers@suse.de` | AutoYaST incoming queue |

---

## 4. Maintenance Rotation Cadence

Maintainers rotate alphabetically for two-week sprints:

1. Ancor
2. David
3. Imobach
4. Iván
5. Josef
6. Ladislav
7. Michal
8. Knut

*(When Knut finishes, the rotation restarts with Ancor).*

---

## 5. Policy for Needinfo Tracking

- **Team Mailing Lists (`yast-maintainers`, `yast-internal`, `autoyast-maintainers`)**: The maintainer answers immediately upon detection.
- **Individual Team Members**: Allow a **1-day (24 hours) grace period** for the team member to answer themselves. If still pending after $\ge$ 1 day, the maintainer follows up by pinging the member on Slack (`#proj-agama`) or contacting their designated backup expert for that domain (e.g. Storage: Ancor ⟷ Iván; Network: Knut ⟷ Michal; Software Stack: Josef ⟷ Ladislav; Architecture: Imobach ⟷ Iván ⟷ Josef).
