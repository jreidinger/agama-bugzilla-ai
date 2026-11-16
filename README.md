# Agama Bugzilla AI Screener

An automated screening and triage environment for the openSUSE / SUSE [Agama](https://github.com/agama-project/agama) installer project, powered by **Gemini CLI** or **Claude Code**, and the [`openSUSE/mcp-bugzilla`](https://github.com/openSUSE/mcp-bugzilla) Model Context Protocol (MCP) server.

---

## Architecture & Security Isolation

```
Host Filesystem (agama-bugzilla-ai/)
├── secrets/bugzilla-token.txt  ──▶ [Read by runners on host only]
│   (Gitignored, NOT mounted)                 │
│                                             ▼ (-e BUGZILLA_API_KEY=...)
│                               ┌──────────────────────────────────────────────┐
│                               │ Container: openSUSE mcp-bugzilla             │
│                               │ Image: registry.opensuse.org/...             │
│                               │ Mode: --read-only                            │
│                               │ Endpoint: http://127.0.0.1:9125/mcp/         │
│                               └──────────────────────▲───────────────────────┘
│                                                      │
│                                              Network Host (MCP Protocol)
│                                                      │
└── workspace/                  ──────────────┐        │
    ├── agama-bugzilla-screener/              ▼        ▼
    │   ├── SKILL.md (Shared Single Source!)  ┌──────────────────────────────────────────────┐
    │   └── references/                       │ Container: Gemini CLI or Claude Code         │
    ├── .gemini/settings.json (Gemini MCP)    │ Mounted: workspace/ -> isolated container    │
    ├── .mcp.json (Claude MCP)                │ Cannot see secrets/ or top-level repo files! │
    └── CLAUDE.md (Points to SKILL.md)        └──────────────────────────────────────────────┘
```

### Key Security & Operational Guarantees

1. **Top-Level Secret Isolation**:
   The AI agent container **only mounts `workspace/`**. It has zero filesystem access to `secrets/`, preventing any exposure of Bugzilla API tokens or host credentials to the agent.
2. **Git Protection**:
   `secrets/` is protected by `.gitignore`. Tokens saved on disk cannot be accidentally committed.
3. **Mandatory Token Validation**:
   Runners require `secrets/bugzilla-token.txt` to exist and contain a valid API key (ignoring `#` comments). They halt with a descriptive error if the file is missing or unconfigured.
4. **Collision-Resistant Port (9125)**:
   The Bugzilla MCP server binds to port `9125` on localhost, avoiding common port collisions (e.g. 8000).
5. **Shared Single Source of Truth**:
   Both Gemini and Claude share the exact same `agama-bugzilla-screener/SKILL.md` and reference guides without duplicating any workflow instructions.
6. **Read-Only Safety**:
   The MCP server runs with `--read-only` (`MCP_READ_ONLY=true`). The agent evaluates bug reports, drafts copy-pasteable responses, and checks card readiness without making unintended changes to Bugzilla.

---

## Quick Start

### 1. Configure Your Bugzilla API Key (Required)

1. Create `secrets/bugzilla-token.txt`:
   ```bash
   echo "YOUR_BUGZILLA_API_KEY" > secrets/bugzilla-token.txt
   chmod 600 secrets/bugzilla-token.txt
   ```
   *(Note: You can generate an API key in Bugzilla under **Preferences** ➡️ **API Keys**)*.

### 2. Launch the Environment

Run the launcher for your preferred AI CLI tool:

#### Option A: Running with Gemini CLI
```bash
./run_gemini.sh
```

#### Option B: Running with Claude Code
```bash
./run_claude.sh
```

Each script will:
1. Validate your API key in `secrets/bugzilla-token.txt`.
2. Ensure container images are up-to-date (pulls or builds container if needed).
3. Start `mcp-bugzilla` in the background on `127.0.0.1:9125` in read-only mode.
4. Launch the AI agent inside the isolated `workspace/` folder.
5. Automatically stop the MCP server container when you exit the AI session.

---

## Directory Structure

```
agama-bugzilla-ai/
├── run_gemini.sh                   # Runner for Gemini CLI
├── run_claude.sh                   # Runner for Claude Code
├── Containerfile.claude            # openSUSE container definition for Claude Code
├── .gitignore                      # Excludes secrets, tokens, and temporary files
├── README.md                       # This documentation
├── secrets/                        # Host-only credentials directory (gitignored)
│   ├── README.md                   # Security guidelines for secrets
│   ├── bugzilla-token.txt.example  # Template for API key
│   └── bugzilla-token.txt          # Your private API key (gitignored)
└── workspace/                      # Mounted workspace for AI agent containers
    ├── README.md                   # Workspace overview
    ├── CLAUDE.md                   # Claude entrypoint (points to SKILL.md)
    ├── .mcp.json                   # Claude MCP configuration (port 9125)
    ├── .claude/settings.json       # Claude MCP project pre-approval
    ├── .gemini/
    │   ├── settings.json           # Gemini MCP configuration (port 9125)
    │   └── skills/
    │       └── agama-bugzilla-screener -> ../../agama-bugzilla-screener (Symlink)
    ├── agama-bugzilla-screener/    # Single source of truth for skill & references
    │   ├── SKILL.md
    │   ├── README.md
    │   └── references/
    │       ├── team-members.md     # Team roster, verified emails, domain backups
    │       ├── card-readiness.md   # 4-point checklist and GitHub card template
    │       ├── comment-templates.md # Copy-paste comment drafts & reports
    │       └── queries.md          # Quicksearch syntax & triage queries
    └── agama-bugzilla-screener.skill # Packaged skill bundle
```

---

## Example Prompts (Works in Both Gemini and Claude)

- **Maintainer Attention Queue**:
  > *"Which bugs needs my attention?"*
  *(Flags immediate team list needinfos, team member needinfos pending $\ge$ 1 day with backup escalation, replied needinfos, and untriaged bugs).*

- **Daily Stand-up Call Report**:
  > *"Generate report for daily call."*
  *(Summarizes L3 escalations, ship-stoppers, P1 bugs, CVEs, and screens new P5 bugs for misclassified critical crashes).*

- **Screen a Specific Bug**:
  > *"Screen bug 1234567. Check if it's ready for an Agama card, and if not, draft a request for logs."*
  *(Instructs reporter to collect logs via `agama logs store` or the web UI download icon).*

- **Sprint Handover Digest**:
  > *"Prepare sprint handover report."*
