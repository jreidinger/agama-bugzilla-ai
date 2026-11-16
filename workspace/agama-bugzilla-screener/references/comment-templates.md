# Agama Triage Response Templates

All templates are designed for the maintainer to copy-paste directly into Bugzilla or Slack.
**Rule:** Because the MCP server is operating in read-only mode, the agent prepares these comments and flag actions for the human maintainer to execute.

---

## 1. Requesting Logs & Details (Missing Information)

Use this when a bug lacks diagnostic logs or details to reproduce. Always instruct the user to use `agama logs store` or the web UI.

### Template: Requesting Agama Logs
```text
Hello,

Thank you for reporting this issue. To help us investigate, we need the installer diagnostic logs from the affected system.

You can collect the logs in either of the following ways:
1. Via Command Line: Run `agama logs store` from a root shell/terminal (Ctrl+Alt+F2 or SSH). This will bundle and store the log archive.
2. Via Web UI: Click the download logs icon in the Agama web interface (available in the top menu bar or on any error screen).

Please attach the resulting log archive to this bug report. If applicable, please also mention:
- The installation target (bare-metal hardware model or VM type)
- The disk layout and storage configuration
- The exact Agama ISO version or build number

Setting needinfo on reporter.
```

**Maintainer Action**:
- **Flag to set**: `needinfo? <reporter_email>`
- **Direct link**: `https://bugzilla.suse.com/show_bug.cgi?id=<BUG_ID>`

---

## 2. Reassignment (Out-of-Scope Component)

According to Agama principles: *"If a bug is outside of Agama responsibilities, reassign it immediately. Do not 'burn time' on a component you are not familiar with."*

### Template: Out-of-Scope Reassignment
```text
Hello,

Looking at the attached logs, the failure occurs in <COMPONENT_NAME> (<brief technical explanation, e.g. kernel panic during nvme initialization / systemd-networkd failing to configure interface>).

This is outside of Agama installer scope. Reassigning to <TARGET_PRODUCT> / <TARGET_COMPONENT>.
```

**Maintainer Action**:
- **Target Component**: `<TARGET_COMPONENT>`
- **Assignee**: Reset to component default (or look up via `get_component_defaults`)
- **Direct link**: `https://bugzilla.suse.com/show_bug.cgi?id=<BUG_ID>`

---

## 3. Answering Maintainer Needinfo (`yast-maintainers` / `yast-internal`)

When a bug has `needinfo?` set on `yast-maintainers` or `yast-internal`:

### Template A: Agama Confirms Bug & Takes Ownership
```text
Hello,

We have reviewed this report from the Agama side. We confirm the issue and will track it in the Agama backlog for an upcoming sprint.

Clearing needinfo on yast-maintainers.
```
**Maintainer Action**: Clear needinfo on `yast-maintainers` / `yast-internal` (`status = X`).

### Template B: Request Belongs to Classic YaST
```text
Hello,

This report refers to legacy YaST (yast2) installation workflows rather than Agama. Reassigning to YaST2 / <Classic Component>.

Clearing needinfo on yast-maintainers.
```
**Maintainer Action**: Clear needinfo on maintainers, reassign to Classic YaST component.

---

## 4. Marking as Duplicate

### Template: Duplicate Bug
```text
Hello,

This issue has the same root cause as bug #<ORIGINAL_BUG_ID> (<Summary of original bug>).
Marking as duplicate of #<ORIGINAL_BUG_ID> to keep all discussions in one place.
```

**Maintainer Action**:
- Set status to `RESOLVED` / `CLOSED`
- Resolution: `DUPLICATE`
- Duplicate of: `<ORIGINAL_BUG_ID>`

---

## 5. Sprint Handover Digest Template

At the end of each two-week sprint, the maintainer provides a short handover note for the team review meeting:

```markdown
### 📋 Agama Sprint Bug Handover (<SPRINT_DATES>)

**Maintainer**: <Current Maintainer> ➡️ **Next Maintainer**: <Next in rotation>

#### 1. Bugs Waiting for Reply (`needinfo`)
- [bsc#<ID>](https://bugzilla.suse.com/show_bug.cgi?id=<ID>) - *<Summary>* (waiting on <user> since <date>, asked for `agama logs store`)
- [bsc#<ID>](https://bugzilla.suse.com/show_bug.cgi?id=<ID>) - *<Summary>* (waiting on <user>)

#### 2. Cards Created in Backlog
- [bsc#<ID>](https://bugzilla.suse.com/show_bug.cgi?id=<ID>) ➡️ [Agama Card #<ISSUE_ID>](https://github.com/agama-project/agama/issues/<ISSUE_ID>) (*<Title>*)

#### 3. Active Security Issues / CVEs
- *None* / [bsc#<ID>](https://bugzilla.suse.com/show_bug.cgi?id=<ID>) (*<CVE-ID>*: <status>)
```

---

## 6. Daily Stand-up Call Report Template

Use when requested to "generate report for daily call" or "daily stand-up report":

```markdown
### 🗣️ Agama Daily Bug Stand-up Report (<DATE>)

#### 🚨 High-Priority Bugs & Escalations
- [bsc#<ID>](https://bugzilla.suse.com/show_bug.cgi?id=<ID>) - **<Summary>** [<P1 | L3 Escalation | Ship-Stopper>]
  - **Status**: <Status> | **Assignee**: <Email/Name>
  - **What Changed**: <1-2 sentences summarizing recent comments, patches, or status changes from bug_history/bug_comments>
  - **Next Step / Blocker**: <What is needed today, e.g. waiting for customer logs or PR review>
*(If none active: "No active L3, ship-stopper, or P1 bugs.")*

#### 🔒 Security / CVE Status
- [bsc#<ID>](https://bugzilla.suse.com/show_bug.cgi?id=<ID>) - **<Summary>** (<CVE-ID>)
  - **Status**: <Status> | **Progress**: <Summary of fix/submission state>
*(If none open: "No active CVE bugs.")*

#### ⚠️ Triage Alert: Urgent Bugs Filed as P5
*(P5 bugs with severe crash, data-loss, or install-blocking symptoms)*
- [bsc#<ID>](https://bugzilla.suse.com/show_bug.cgi?id=<ID>) - **<Summary>**
  - **Why it looks critical**: <e.g., Unhandled exception during partition creation on NVMe>
  - **Suggested Action**: Bump priority from P5 to P1/P2 and triage immediately.
*(If no urgent P5 bugs: "No critical or urgent issues detected in recent P5 reports.")*

#### 📬 Team Needinfo Summary
- **Waiting on Maintainers**: <X> bugs with needinfo requested on `yast-maintainers` / `yast-internal`.
- **Waiting on Reporters**: <Y> bugs waiting for logs/reproduction details.
```

---

## 7. Maintainer Attention Action Plan ("which bugs needs my attention")

Use when the maintainer asks *"which bugs needs my attention"* or *"what are my bug duties today"*:

```markdown
### 🎯 Maintainer Attention Action Plan (<DATE>)

#### 1. 🚨 Immediate Action: Team Mailing List Needinfos
*(Bugs with needinfo on yast-maintainers or yast-internal — MUST be answered immediately by maintainer)*
- [bsc#<ID>](https://bugzilla.suse.com/show_bug.cgi?id=<ID>) - **<Summary>**
  - **Requested**: <yast-maintainers / yast-internal>
  - **Question / Context**: <Brief quote or summary of what external team/reporter is asking>
  - **Immediate Action**: <Answer question, clear needinfo, or reassign out-of-scope>
*(If none: "✅ No bugs waiting on team mailing lists.")*

#### 2. ⏳ Team Member Needinfos Pending $\ge$ 1 Day (Follow-up)
*(Needinfo on individual team members unanswered after 24h grace period)*
- [bsc#<ID>](https://bugzilla.suse.com/show_bug.cgi?id=<ID>) - **<Summary>**
  - **Asked**: <Team Member Name/Email> (waiting <X> days since <Date>)
  - **Domain / Backup**: <Domain, e.g. Storage | Network | UI/UX> ➡️ Backup: <Backup Name>
  - **Follow-up Action**: Ping <Team Member> on Slack (#proj-agama). If unavailable, ping backup (<Backup Name>).
*(If none: "✅ All individual team member needinfos are within the 1-day grace period or answered.")*

#### 3. 📬 Needinfo Replied (Reporters Provided Info)
*(Bugs where external reporters commented or attached logs after a needinfo request)*
- [bsc#<ID>](https://bugzilla.suse.com/show_bug.cgi?id=<ID>) - **<Summary>**
  - **Reporter Update**: <Attached logs / provided steps <Y> hours ago>
  - **Recommended Action**: Review logs and evaluate for card readiness.
*(If none: "✅ No pending replies from reporters.")*

#### 4. 📋 Incoming Untriaged Agama Bugs
*(Active bugs without needinfo that do NOT have a GitHub issue link in their `url` field — bugs with a GitHub URL are already triaged on the project board)*
- [bsc#<ID>](https://bugzilla.suse.com/show_bug.cgi?id=<ID>) - **<Summary>**
  - **Status Evaluation**: <READY_FOR_CARD | NEEDS_LOGS | OUT_OF_SCOPE | DUPLICATE>
  - **Reason**: <Brief justification>
  - **Action**: <Prepared Card proposal / draft comment asking for `agama logs store` or web UI / target reassignment>
*(If none: "✅ No untriaged Agama bugs waiting.")*

#### 5. 📝 Action Checklist for Today's Shift
- [ ] Answer team list needinfo on bsc#<ID> (immediate!)
- [ ] Ping <Team Member> (or backup <Backup Name>) about bsc#<ID> ($\ge$ 1 day pending)
- [ ] Review logs on bsc#<ID> (reporter replied)
- [ ] Paste prepared card for bsc#<ID> into Agama backlog & set Bugzilla URL to GitHub issue link
- [ ] Post draft comment on bsc#<ID> requesting logs via `agama logs store` and set needinfo?
```
