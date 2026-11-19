# Agama Card Readiness & Backlog Template

This document defines the criteria and template for turning a Bugzilla bug into an actionable card on the Agama backlog board.

---

## 1. The 5-Point Card Readiness Checklist

A bug MUST satisfy all five points before the maintainer creates a card in the Agama backlog:

1. **Reproducibility or Root Cause Understood**:
   - The steps to reproduce are clear, OR
   - The stack trace, journal logs, or code path makes the root cause identifiable without guessing.

2. **Required Logs & Context Attached**:
   - Complete installer logs are attached (collected via `agama logs store` or downloaded from the Agama web UI).
   - If hardware/storage related: disk partitioning layout or hardware specification is attached.
   - If network related: network configuration or installer profile is attached.

3. **Product, Version, and Component Known**:
   - The exact product, version, or ISO build (e.g. openSUSE Tumbleweed snapshot, openSUSE Leap, SUSE Linux Enterprise, or packages/images from the OBS devel project [systemsmanagement:Agama](https://build.opensuse.org/project/show/systemsmanagement:Agama)).
   - Subsystem identified (e.g. Storage, Network, Software selection, Web UI, D-Bus service).

4. **Expected Behavior is Explicit**:
   - Unambiguous statement of what should have happened vs. what actually occurred.

5. **Issue Type is Properly Set**:
   - The issue type is explicitly classified as **`bug`**, **`feature`**, or **`task`**.

---

## 2. Card Status Evaluation Logic

When screening a bug, classify it into one of these states:

- **READY**: Meets all 5 points. Generate the Card Proposal below for the maintainer.
- **NEEDS_INFO**: Fails point 1, 2, or 4. Draft a polite request for logs or clarification (see `references/comment-templates.md`).
- **OUT_OF_SCOPE**: Issue lies outside Agama scope (e.g. kernel panic, systemd, wicked; for YaST bugs not affecting Agama, close as WONTFIX; see `references/queries.md`).
- **DUPLICATE**: Same root cause as an existing issue. Suggest duplicate resolution.

---

## 3. Backlog Entry & Workflow Guidelines

- **Summary for POs**: When an issue is moved to the backlog and contains a long discussion, add a comment with a concise summary to help Product Owners (POs) during sprint planning.
- **Community Contributors**: If a community member wants to work on an issue, assign the issue to them and move it to the backlog. (The issue will be automatically moved to "In Progress" once a PR is opened).

---

## 4. Backlog Card Proposal Template

When a bug is **READY**, format the output so the maintainer can easily copy-paste it into a new GitHub Issue or Agama Project card:

```markdown
### [Bugzilla ID] - [Short Descriptive Title]

**Bugzilla**: [bsc#<BUG_ID>](https://bugzilla.suse.com/show_bug.cgi?id=<BUG_ID>)
**Product / Version**: <e.g., openSUSE Tumbleweed (snapshot YYYYMMDD) / openSUSE Leap 16.0 / OBS systemsmanagement:Agama>
**Domain / Subsystem**: <Storage | Network | Software | Web UI | Core>
**Issue Type**: <Bug | Feature | Task>

#### Description
<Concise explanation of the problem.>

#### Steps to Reproduce
1. <Step 1>
2. <Step 2>
3. <Step 3>

#### Expected Behavior
<What should happen.>

#### Actual Behavior
<What happened instead, error message or UI state.>

#### Technical Notes & Log Evidence
- **Logs attached**: <filename, e.g. `agama-logs.tar.gz`>
- **Relevant error**:
  ```text
  <Paste 3-5 key lines from the log or stack trace>
  ```
- **Initial hypothesis**: <Brief pointer to likely service, API endpoint, or component>

#### Review
*(Must be filled when moving the card to Review or Done)*
- **Summary of changes**: <What was implemented / fixed to resolve the problem>
- **How to test / verify**: <Specific steps or tests used to verify the fix>
- **Evidence / Notes**: <PR link, test run logs, or screenshots>

#### Suggested Next Steps on Bugzilla
1. Set Bugzilla **URL** field to: `<GitHub issue link>` *(Crucial: This marks the bug as triaged and removes it from the maintainer's untriaged work queue)*.
   - *Note*: If the URL field is already occupied (e.g. by an upstream bug or build service link), post a comment with the GitHub link: `"Card created in Agama backlog: <GitHub issue link>"`.
2. Add comment to Bugzilla: "Card created in Agama backlog: <GitHub issue link>"
3. Assign card to maintainer or move to Agama Backlog view on GitHub project board.
4. Maintainer self-assigns Bugzilla bug when sprint execution begins.
```
