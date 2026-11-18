---
name: agama-bugzilla-screener
description: Triage, screen, and analyze Agama Bugzilla bugs in read-only mode. Use when screening incoming Agama bugs, identifying bugs needing maintainer attention, checking team needinfos unanswered for >= 1 day, generating reports for daily stand-up calls, validating card readiness, requesting logs, or preparing sprint handovers.
---

# Agama Bugzilla Screener

Screen and triage Bugzilla issues for the openSUSE/SUSE Agama installer project using the `openSUSE/mcp-bugzilla` Model Context Protocol (MCP) server.

## Operational Mandate: Read-Only Mode

This skill operates strictly in **read-only / advisory mode**:
1. **Never invoke modifying tools**: Do not call `add_comment`, `update_bug_status`, `assign_bug`, `update_bug_fields`, or `mark_as_duplicate`.
2. **Inspect via read tools**: Use `bugs_quicksearch`, `bug_info`, `bug_comments`, `bug_history`, `list_attachments`, `download_attachment`, `get_component_defaults`, and `bug_url`.
3. **Deliver prepared maintainer packages**: For every screened bug, provide:
   - Direct Bugzilla link (`https://bugzilla.suse.com/show_bug.cgi?id=<id>`).
   - Clear diagnostic summary.
   - Recommended action (Card creation, needinfo request, reassignment, or duplicate closure).
   - Copy-paste ready Bugzilla comment text.

---

## Core Screening Workflows

### 1. Maintainer Attention Action Plan ("which bugs needs my attention")

When asked *"which bugs needs my attention"* or *"what are my duties as maintainer today"*:

#### Step 1.1: Immediate Action — Team Mailing List Needinfos (`yast-maintainers`, `yast-internal`, `autoyast-maintainers`)
- **Rule**: Bugs with `needinfo?` set on team mailing lists **must be answered immediately** by the maintainer. No grace period!
- **YaST Maintenance Scope**: The maintainer must also take care of YaST bugs filed against SLE 12 and SLE 15, as well as parts of YaST still used by Agama (only **bootloader**, **storage**, **yast2-ruby-bindings**, and **core**).
- **YaST Triage & Reassignment Rule**: Before reassigning any YaST bug, check:
  - If the bug is against **SLE 12** or **SLE 15**: Maintainer must take care of it.
  - If the bug affects YaST parts used by Agama (**bootloader**, **storage**, **yast2-ruby-bindings**, **core**): Maintainer must take care of it.
  - **Reassign to `yast-community` ONLY IF** it is not used by Agama or not in SLE.
- Run queries (see [references/queries.md](references/queries.md)):
  - `bugs_quicksearch(query='flag:needinfo?(yast-maintainers)')`
  - `bugs_quicksearch(query='flag:needinfo?(yast-internal)')`
  - `bugs_quicksearch(query='flag:needinfo?(autoyast-maintainers)')`
- For each bug: review the question, verify context, and prepare an immediate answer, ownership claim, or out-of-scope reassignment.

#### Step 1.2: Follow-up Action — Individual Team Member Needinfos Pending $\ge$ 1 Day
- **Rule**: Team members listed in [references/team-members.md](references/team-members.md) are given **1 day (24 hours)** to answer questions directed to them.
- If pending for **$\ge$ 1 day without reply**:
  - Intervene to ping the member on Slack (`#proj-agama`).
  - If the member is unavailable or offline, identify and ping their **backup in their expert area** (Storage, Network, Software Architecture, UI/UX) according to [references/team-members.md](references/team-members.md).
- Find active needinfos: `bugs_quicksearch(query='component:Agama flag:needinfo? status:NEW,CONFIRMED,IN_PROGRESS,REOPENED')`
- Check flag timestamp via `bug_info` or `bug_history`. If elapsed time $\ge$ 24 hours, add to the follow-up list with recommended ping action.

#### Step 1.3: Review Action — Needinfos Replied by Reporters
Check bugs where the reporter provided feedback or attached logs:
- In `component:Agama flag:needinfo?`, inspect recent comments via `bug_comments(bug_id=..., limit=2)`.
- If the latest comment is from the reporter or contains an attachment, flag it as ready for maintainer re-evaluation.

#### Step 1.4: Triage Action — Incoming Untriaged Agama Bugs
Find active Agama bugs with no pending needinfo:
- Call `bugs_quicksearch(query='component:Agama status:NEW,CONFIRMED,REOPENED -flag:needinfo?', include_fields='id,product,component,priority,severity,assigned_to,status,resolution,summary,url,last_change_time')`
- **Exclude Already-Triaged Bugs**:
  1. Primary check: If `bug["url"]` contains a GitHub issue link (`github.com/.../issues/...`), the bug is already triaged. **Exclude it from the untriaged work-to-do list!**
  2. Fallback check (when `url` is empty or occupied by a non-GitHub link): Inspect `bug_comments(bug_id=...)`. If any comment mentions an Agama GitHub issue link (e.g. `github.com/agama-project/.../issues/<id>` or "Card created in Agama backlog"), the bug is already triaged into a card. **Exclude it from the untriaged work-to-do list!**
- For each truly untriaged bug (no GitHub issue in `url` or comments), perform diagnostic screening:
  - **Card Ready**: Meets all 4 criteria (see [references/card-readiness.md](references/card-readiness.md)). Prepare backlog card markdown and remind maintainer to set the Bugzilla URL field to the newly created GitHub card link (or post it in a comment if URL is occupied).
  - **Missing Logs/Info**: Prepare draft comment requesting logs via `agama logs store` or Web UI download, and set `needinfo? <reporter>`.
  - **Out of Scope**: Issue is in kernel, storage driver, systemd, or NetworkManager. Prepare reassignment recommendation. (Note: YaST bugs against SLE 12/15 or in bootloader, storage, yast2-ruby-bindings, or core are in scope for the maintainer; only reassign to `yast-community` if not used by Agama or not in SLE).
  - **Duplicate**: Matches an existing issue. Prepare duplicate closure draft.

#### Step 1.5: Output the Maintainer Action Plan
Format the response using Section 7 of [references/comment-templates.md](references/comment-templates.md), providing a prioritized checklist of actions for today's shift.

---

### 2. Daily Stand-up Call Report ("generate report for daily call")

When requested to prepare notes or a report for the team's daily stand-up call:

#### Step 2.1: Query High-Priority Bugs
Find all active high-priority bugs affecting Agama (consult [references/queries.md](references/queries.md)):
- **L3 Escalations**: `bugs_quicksearch(query='component:Agama summary:"L3:" status:NEW,CONFIRMED,IN_PROGRESS,REOPENED')`
- **Ship-Stoppers**: `bugs_quicksearch(query='component:Agama flag:ship_stopper+ status:NEW,CONFIRMED,IN_PROGRESS,REOPENED')`
- **Priority P1**: `bugs_quicksearch(query='component:Agama priority:P1 status:NEW,CONFIRMED,IN_PROGRESS,REOPENED')`
- **CVE / Security**: `bugs_quicksearch(query='component:Agama summary:CVE- status:NEW,CONFIRMED,IN_PROGRESS,REOPENED')`

#### Step 2.2: Summarize What Changed
For each high-priority bug found:
- Call `bug_history(bug_id=..., limit=5)` to check recent field changes (status, assignee, flags, priority).
- Call `bug_comments(bug_id=..., limit=3)` to check recent discussion, customer responses, or developer patches.
- Formulate a 1-2 sentence summary: current state, what changed recently, and what is needed next.

#### Step 2.3: Screen New P5 Bugs for Misclassified Criticals
Reporters often leave bug priority at the default `P5 - None`:
- Call `bugs_quicksearch(query='component:Agama priority:P5 status:NEW,CONFIRMED', limit=15)`
- Inspect summaries and descriptions for critical/urgent symptoms:
  - Fatal installer crashes or unhandled exceptions / backtraces
  - Storage calculation or partition creation failures / disk wiping
  - System unbootable after installation
  - Network / repository reachability errors completely blocking install
- If any bug shows urgent symptoms, flag it in the report with a recommendation to bump priority to P1/P2.

#### Step 2.4: Output the Report
Format the findings using Section 6 of [references/comment-templates.md](references/comment-templates.md).

---

### 3. Deep Bug Analysis & Diagnostics

When triaging a specific bug ID:
1. **Retrieve Metadata & Discussion**:
   - Call `bug_info(bug_ids=[bug_id])` for status, product, component, version, priority, reporter, and flags.
   - Call `bug_comments(bug_id=bug_id, limit=10)` to review recent comments and steps to reproduce.
2. **Inspect Attachments**:
   - Call `list_attachments(bug_id=bug_id)` to check for installer logs (e.g., `agama-logs.tar.gz`, `y2log`, journal logs).
   - If relevant logs are present, download and examine key errors via `download_attachment(attachment_id=..., delivery="auto")`.
3. **Check for Duplicates**:
   - Call `bugs_quicksearch(query='component:Agama "<error_or_keyword>"')` to search for known issues.

---

### 4. Sprint Handover Compilation

At sprint boundaries (every 2 weeks), compile the maintainer handover report:
1. List all bugs still waiting for reply (`needinfo`).
2. List cards created/recommended for the backlog during the sprint.
3. List active CVEs or security bugs.
See Section 5 of [references/comment-templates.md](references/comment-templates.md) for the handover markdown format.
