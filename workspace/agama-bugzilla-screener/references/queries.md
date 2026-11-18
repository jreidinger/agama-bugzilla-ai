# Bugzilla Queries and Filtering Guide

This reference details how to query and filter Bugzilla issues for Agama bug screening using the `openSUSE/mcp-bugzilla` MCP server in read-only mode.

---

## 1. Core Target Queues for Maintainers

Agama bug maintainers manage their shift through four primary lenses:
1. **Maintainer Attention Queue ("which bugs needs my attention")**:
   - **Immediate Action**: Needinfos requested on team mailing lists (`yast-maintainers` / `yast-internal`).
   - **Follow-up Action ($\ge$ 1 Day)**: Needinfos requested on individual team members unanswered for at least 24 hours.
   - **Triage Action**: Incoming untriaged Agama bugs (card readiness, logs needed, or reassignments).
   - **Review Action**: Needinfos where reporters have replied with logs or comments.
2. **Daily Stand-up Queue ("generate report for daily call")**:
   - Active high-priority bugs (L3, ship-stopper, P1, CVEs) and recent change summaries.
   - New P5 bugs scanned for misclassified critical crashes or data loss.
3. **Untriaged / No Needinfo Queue**:
   - New and confirmed Agama bugs awaiting initial triage.

---

## 2. Team Needinfo Rules: Lists vs. Individual Members

There is a fundamental policy difference between needinfos set on **team mailing lists** vs. **individual team members**:

### A. Team Mailing Lists (`yast-maintainers`, `yast-internal`, `autoyast-maintainers`) — Answer Immediately!
- **Policy**: Must be addressed **immediately** by the current sprint maintainer. No delay or grace period!
- **Mailing Lists**: `yast-maintainers@suse.de`, `yast-internal@suse.de`, `autoyast-maintainers@suse.de`
- **Queries**:
  ```text
  flag:needinfo?(yast-maintainers)
  ```
  ```text
  flag:needinfo?(yast-internal)
  ```
  ```text
  flag:needinfo?(autoyast-maintainers)
  ```
- **Maintainer Responsibility**: Triage the bug immediately, provide the answer, clear the flag, or reassign if out-of-scope.

### B. Individual Team Members — 1-Day Grace Period, Then Ping/Backup
- **Policy**: Give individual team members **1 day (24 hours)** to see and answer the question themselves.
- **When Unanswered for $\ge$ 1 Day**:
  The maintainer intervenes:
  1. Ping the team member on Slack (`#proj-agama`).
  2. If the team member is absent (vacation/sick/offline) or blocked, ping their **backup in their expert domain** according to the team's "No Silo" rule (every domain has at least 2 designated experts: Storage, Network, Software Architecture, UI/UX).
- **Team Roster & Email Mapping**:
  See [references/team-members.md](team-members.md) for the verified list of members (Ancor, David, Imobach, Iván, Josef, Ladislav, Michal, Knut), email addresses, and domain backups.
- **Query**:
  ```text
  component:Agama flag:needinfo? status:NEW,CONFIRMED,IN_PROGRESS,REOPENED
  ```
- **Age Verification Logic ($\ge$ 1 Day)**:
  1. In `bug_info(bug_ids=[id])`, inspect `flags`.
  2. Find flags where `name == "needinfo"`, `status == "?"`, and `requestee` matches an individual team member from [references/team-members.md](team-members.md).
  3. Verify timestamp via flag `creation_date` or `bug_history(bug_id=id, changed_fields="flag,flags")`.
  4. If elapsed time is $\ge$ 24 hours: Flag for maintainer follow-up (ping expert or domain backup).

---

## 3. Untriaged Queue Queries & The "Already Triaged" Rule

### Definition of "Already Triaged" vs. "Untriaged"
- **ALREADY TRIAGED**: An Agama bug is considered triaged and tracked on the GitHub project board if:
  1. **Primary check**: Bugzilla's **`url`** field contains a link to a GitHub issue (e.g. `https://github.com/agama-project/agama/issues/...`), OR
  2. **Fallback check (when `url` is occupied)**: Bugzilla's comments contain a link to a GitHub issue (e.g., when the `url` field is already occupied by an upstream link or build service URL).
  - **Rule**: Any bug with a GitHub issue link in its `url` field **OR** in any of its comments is already tracked on the GitHub project board and **MUST BE EXCLUDED** from the maintainer's untriaged "work to do" queue!
- **UNTRIAGED (Work to Do)**: Active bugs where neither the `url` field nor the comments contain a GitHub issue link.

### Untriaged Search Query
Search for active Agama bugs without active needinfo requests:

```text
component:Agama status:NEW,CONFIRMED,REOPENED -flag:needinfo?
```
*(Or by product: `product:Agama status:NEW,CONFIRMED,REOPENED -flag:needinfo?`)*

### Filtering Procedure
1. **Check the `url` field**:
   - If `bug["url"]` contains a GitHub issue link (`github.com/.../issues/...`): **Exclude from untriaged list** (already triaged).
2. **Fallback: Check comments** (if `url` is empty or occupied by a non-GitHub link):
   - Inspect comments via `bug_comments(bug_id=id)`:
   - If any comment mentions an Agama GitHub issue link (e.g., `github.com/agama-project/.../issues/<id>` or `github.com/.../issues/<id>` or "Card created in Agama backlog"): **Exclude from untriaged list** (already triaged).
3. If neither contains a GitHub issue link, **treat as untriaged work to do** and evaluate:
   - **Card Ready**: Meets the 4-point checklist (see `references/card-readiness.md`).
   - **Needs Info**: Missing logs -> Draft comment asking for `agama logs store` or Web UI download, set `needinfo? <reporter>`.
   - **Out of Scope**: Issue is kernel/storage driver/systemd/wicked -> Draft reassignment comment.
   - **Duplicate**: Matches an existing issue -> Draft duplicate closure.

---

## 4. Needinfo Replied Queue

Locate bugs where a needinfo request was pending and the reporter or an external contributor commented or attached files:
- Search: `component:Agama flag:needinfo?`
- Inspect recent comments via `bug_comments(bug_id=id, limit=2)`:
  - If the latest comment is from the reporter, external user, or contains an attachment, the bug is ready for maintainer re-evaluation.

---

## 5. High-Priority Queries (Daily Call)

For generating the daily stand-up call report, search for active high-priority bugs and recent changes:

### A. L3 Customer Escalations
Bugs escalated from SUSE Level 2 support to Level 3 development have an `L3:` prefix in the summary:
```text
component:Agama summary:"L3:" status:NEW,CONFIRMED,IN_PROGRESS,REOPENED
```

### B. Ship-Stopper Bugs
Bugs blocking release or milestone milestones flagged with `ship_stopper`:
```text
component:Agama flag:ship_stopper+ status:NEW,CONFIRMED,IN_PROGRESS,REOPENED
```
*(Also check pending requests: `component:Agama flag:ship_stopper?` or `component:Agama flag:ship-stopper+`)*.

### C. Priority P1 (Urgent / Blocker)
Bugs with explicit P1 priority:
```text
component:Agama priority:P1 status:NEW,CONFIRMED,IN_PROGRESS,REOPENED
```

### D. CVE & Security Issues
Active security vulnerabilities affecting Agama:
```text
component:Agama summary:CVE- status:NEW,CONFIRMED,IN_PROGRESS,REOPENED
```
*(Also check security keywords: `component:Agama keywords:security status:NEW,CONFIRMED,IN_PROGRESS,REOPENED`)*.

### E. New P5 Bugs (Screening for Misclassified Criticals)
Reporters often leave priority at the default `P5 - None`. Scan recently filed P5 bugs for severe crash or data-loss symptoms:
```text
component:Agama priority:P5 status:NEW,CONFIRMED
```
Inspect summaries and descriptions for:
- Fatal crashes / tracebacks / unhandled exceptions during install
- Partitioning failure / storage wipe / disk corruption
- System unbootable after installation completes
- Network / repository failure making installation impossible

---

## 6. Recommended Field Selections

To keep MCP responses compact and token-efficient:

### In `bugs_quicksearch`:
```python
include_fields = "id,product,component,priority,severity,assigned_to,status,resolution,summary,url,last_change_time"
```

### In `bug_info`:
```python
include_fields = "id,product,component,version,priority,severity,status,resolution,summary,url,reporter,assigned_to,flags,creation_time,last_change_time"
```

### In `bug_history`:
```python
limit = 5
changed_fields = "status,resolution,assigned_to,priority,flags"
```

### In `bug_comments`:
```python
limit = 3
include_fields = "count,id,creator,creation_time,text,attachment_id"
```

---

## 7. YaST vs. Agama Responsibilities & Reassignment Rules

The team maintains both the modern Agama installer and enterprise YaST components under specific rules:

### A. Maintainer YaST Scope
- **SLE 12 and SLE 15**: Bug maintainers must take care of YaST bugs filed against SUSE Linux Enterprise 12 and 15 (e.g., SLES 12, SLES 15). These are enterprise-supported and within the team's maintenance duties.
- **Parts of YaST Still Used by Agama**: Only the following YaST components are still used by Agama:
  - **bootloader** (e.g., `yast2-bootloader`)
  - **storage** (e.g., `yast2-storage-ng`, `libstorage-ng`)
  - **yast2-ruby-bindings**
  - **core** (e.g., `yast2-core`, `yast2`)
  Bugs in these components must be handled by the maintainer.

### B. Triage & Reassignment Gate
Before reassigning any YaST bug:
1. **Check Product**: Is the bug filed against SLE 12 or SLE 15? If **yes**, the maintainer must handle it. Do NOT reassign.
2. **Check Component**: Is the affected YaST component used by Agama (bootloader, storage, yast2-ruby-bindings, core)? If **yes**, the maintainer must handle it. Do NOT reassign.
3. **Reassign to `yast-community` ONLY IF**:
   - The bug is **not used by Agama** (outside bootloader, storage, yast2-ruby-bindings, core), **AND**
   - The bug is **not in SLE** (e.g., openSUSE community-only YaST modules).

---

## 8. GitHub Current Sprint Board Review Check (Daily Call)

As part of the daily call report, the screener checks the **Current sprint view** on the Agama GitHub project board:
- **Board URL**: [https://github.com/orgs/agama-project/projects/2/views/1](https://github.com/orgs/agama-project/projects/2/views/1)
- **Tool Mandate**: Inspect cards and comments **exclusively via GitHub MCP tools** (`projects_list`, `projects_get`, `list_issues`, `get_issue`, `list_issue_comments`). Do **NOT** use `gh` CLI commands and do **NOT** use `web_fetch` or `curl` on GitHub URLs.

### Inspection Procedure for Cards in "Review" or "Done":
1. Inspect all items/cards in the current sprint board with status or column **`Review`** or **`Done`**.
2. For each card, verify whether it contains a **substantive "Review" section** (either in the issue description or in a comment):
   - **Check presence**: Look for `## Review`, `### Review`, `#### Review`, `Review:`, or `Review notes`.
   - **Check for real content (not empty, not default template)**:
     - The section must **NOT** be empty or blank.
     - The section must **NOT** consist only of unedited template placeholders (e.g., `<To be filled...>`, `<What was implemented...>`, `<TODO>`, `<TBD>`, `<Specific steps...>`, or unmodified template bullets).
     - It must describe real implementation changes and verification/test steps.
   - **Fallback to comments**: If the description has no review section or only contains unedited template text, inspect comments via `list_issue_comments`. Check if a team member posted the review details in a comment.
3. **If missing, empty, or unedited placeholder**:
   - Flag the card in the daily call report under `#### 📋 GitHub Current Sprint Cards in Review / Done Missing "Review" Notes`.
   - Specify whether the section is completely missing or still contains default template text so the bug sorter can point it out during the daily call.
