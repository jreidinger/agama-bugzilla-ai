---
name: agama-bugzilla-screener
description: Triage, screen, and analyze Agama Bugzilla bugs in read-only mode. Use when screening incoming Agama bugs, identifying bugs needing maintainer attention, checking team needinfos unanswered for >= 1 day, generating reports for daily stand-up calls, validating card readiness, requesting logs, or preparing sprint handovers.
---

# Agama Bugzilla Screener

Screen and triage Bugzilla issues for the openSUSE/SUSE Agama installer project using the `openSUSE/mcp-bugzilla` and official GitHub MCP servers.

## Operational Mandates: Read-Only Mode & Dedicated MCP Tools

### 1. Bugzilla Operations (Strictly Read-Only)
- Inspect exclusively via read tools: `bugs_quicksearch`, `bug_info`, `bug_comments`, `bug_history`, `list_attachments`, `download_attachment`, `get_component_defaults`, and `bug_url`.
- Never invoke modifying tools (`add_comment`, `update_bug_status`, `assign_bug`, `update_bug_fields`, `mark_as_duplicate`). Always deliver prepared copy-pasteable packages for the maintainer.

### 2. GitHub Operations (Exclusive GitHub MCP Tools)
- All GitHub queries (issues, comments, project board cards) **MUST EXCLUSIVELY use the GitHub MCP server tools** (`projects_list`, `projects_get`, `list_issues`, `get_issue`, `search_issues`, `list_issue_comments`).
- **PROHIBITED**: Do **NOT** execute `gh` CLI commands and do **NOT** use `web_fetch` or `curl` on GitHub URLs.

---

## Core Screening Workflows

### 1. Maintainer Attention Action Plan ("which bugs needs my attention")

When asked *"which bugs needs my attention"* or *"what are my duties as maintainer today"*:

1. **Immediate Action — Team Mailing List Needinfos**:
   - Query `yast-maintainers`, `yast-internal`, and `autoyast-maintainers` needinfo queues (see [references/queries.md](references/queries.md)).
   - Must be answered **immediately** by the maintainer. Apply the YaST Scope Gate (in [references/queries.md](references/queries.md)) before reassigning.
2. **Follow-up Action — Team Member Needinfos ($\ge$ 1 Day Unanswered)**:
   - Identify active needinfos on team members from [references/team-members.md](references/team-members.md) pending for $\ge$ 24 hours.
   - Propose pinging the member on Slack (`#proj-agama`) or escalating to their domain backup.
3. **Review Action — Needinfos Replied by Reporters**:
   - Check bugs where reporters replied with comments or attachments for maintainer re-evaluation.
4. **Triage Action — Incoming Untriaged Agama Bugs**:
   - Query active Agama bugs without active needinfo.
   - **Filter Out Already-Triaged Bugs**: Exclude any bug with a GitHub issue link in its `url` field or comments (see [references/queries.md](references/queries.md)).
   - For remaining untriaged bugs, evaluate against the 4-point checklist ([references/card-readiness.md](references/card-readiness.md)) to classify: **Card Ready**, **Needs Logs** (request via `agama logs store` or Web UI), **Out of Scope** (reassign), or **Duplicate**.
5. **Output Action Plan**:
   - Format using Section 7 of [references/comment-templates.md](references/comment-templates.md).

---

### 2. Daily Stand-up Call Report ("generate report for daily call")

When asked to prepare notes or a report for the team's daily stand-up call:

1. **High-Priority Bugs**:
   - Query active L3 escalations (`L3:` prefix), ship-stopper flags (`ship_stopper+`), P1 bugs, and CVEs (see [references/queries.md](references/queries.md)).
   - Summarize what changed recently (via `bug_history` and `bug_comments`) in 1–2 sentences.
2. **Screen New P5 Bugs**:
   - Scan recent P5 bugs for misclassified critical crashes, data loss, partition wiping, or boot failures.
3. **Check Current Sprint Board for Filled Review Notes**:
   - Check the Agama Current sprint board view: [https://github.com/orgs/agama-project/projects/2/views/1](https://github.com/orgs/agama-project/projects/2/views/1).
   - Inspect all cards in **`Review`** or **`Done`**.
   - Verify that the "Review" section in the description or comments is **actually filled in with substantive implementation and testing details** (not empty or left with default template placeholders; see [references/queries.md](references/queries.md)).
   - Flag any missing or incomplete cards so the bug sorter can raise them during the call.
4. **Output Report**:
   - Format using Section 6 of [references/comment-templates.md](references/comment-templates.md).

---

### 3. Deep Bug Analysis & Diagnostics

When triaging a specific bug ID:
1. **Metadata & Comments**: Retrieve via `bug_info` and `bug_comments`.
2. **Attachments & Logs**: Inspect installer logs (`agama-logs.tar.gz`, journal) via `list_attachments` and `download_attachment`.
3. **Duplicates**: Search for matching keywords across all bug statuses.
4. **Action Package**: Output the prepared card markdown, log request comment, or reassignment draft.

---

### 4. Sprint Handover Compilation

At sprint boundaries (every 2 weeks), compile the maintainer handover report (pending needinfos, backlog cards created, active CVEs) using Section 5 of [references/comment-templates.md](references/comment-templates.md).
