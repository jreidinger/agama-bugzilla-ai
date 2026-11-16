# Agama Bugzilla AI Screener

An automated screening and triage environment for the openSUSE / SUSE [Agama](https://github.com/agama-project/agama) installer project, powered by **Gemini CLI** and the [`openSUSE/mcp-bugzilla`](https://github.com/openSUSE/mcp-bugzilla) Model Context Protocol (MCP) server.

---

## Architecture & Security Isolation

```
Host Filesystem (agama-bugzilla-ai/)
├── secrets/bugzilla-token.txt  ──▶ [Read by run.sh on host only]
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
    ├── .gemini/settings.json                 ▼        ▼
    └── .gemini/skills/         ┌──────────────────────────────────────────────┐
        └── agama-bugzilla-...  │ Container: Gemini CLI (isolated workspace)   │
                                │ Mounted: workspace/ -> /home/sandbox/tmp:Z   │
                                │ Cannot see secrets/ or top-level repo files! │
                                └──────────────────────────────────────────────┘
```

### Key Security & Operational Guarantees

1. **Top-Level Secret Isolation**:
   Gemini CLI runs in its own isolated container and **only mounts `workspace/`**. It has zero filesystem access to `secrets/`, preventing any exposure of Bugzilla API tokens or host credentials to the agent.
2. **Git Protection**:
   `secrets/` is protected by `.gitignore`. Tokens saved on disk cannot be accidentally committed.
3. **Mandatory Token Validation**:
   `run.sh` requires `secrets/bugzilla-token.txt` to exist and contain a valid API key (ignoring `#` comments). It halts with a descriptive error if the file is missing or unconfigured.
4. **Collision-Resistant Port (9125)**:
   The Bugzilla MCP server binds to port `9125` on localhost, avoiding common port collisions (e.g. 8000).
5. **Read-Only Safety**:
   The MCP server runs with `--read-only` (`MCP_READ_ONLY=true`). The agent evaluates bug reports, drafts copy-pasteable responses, and checks card readiness without making unintended changes to Bugzilla.
6. **Always Up-to-Date**:
   `run.sh` pulls the latest container images for both `mcp-bugzilla` and `gemini-cli` before launching.

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

Run the single orchestration script:

```bash
./run.sh
```

This script will:
1. Validate your API key in `secrets/bugzilla-token.txt`.
2. Pull the latest images for `mcp-bugzilla` and `gemini-cli`.
3. Start `mcp-bugzilla` in the background on `127.0.0.1:9125` in read-only mode.
4. Launch Gemini CLI inside the isolated `workspace/` folder.
5. Automatically stop the MCP server container when you exit Gemini CLI.

---

## Directory Structure

```
agama-bugzilla-ai/
├── run.sh                          # Main launcher (validates token, pulls images, starts MCP, runs Gemini)
├── .gitignore                      # Excludes secrets, tokens, and temporary files
├── README.md                       # This documentation
├── secrets/                        # Host-only credentials directory (gitignored)
│   ├── README.md                   # Security guidelines for secrets
│   ├── bugzilla-token.txt.example  # Template for API key
│   └── bugzilla-token.txt          # Your private API key (gitignored)
└── workspace/                      # Mounted workspace for Gemini CLI container
    ├── README.md                   # Workspace overview
    ├── .gemini/
    │   ├── settings.json           # Auto-configured MCP connection (http://127.0.0.1:9125/mcp/)
    │   └── skills/
    │       └── agama-bugzilla-screener/   # Preloaded screener skill
    │           ├── SKILL.md
    │           ├── README.md
    │           └── references/
    │               ├── card-readiness.md
    │               ├── comment-templates.md
    │               └── queries.md
    ├── agama-bugzilla-screener/    # Skill files accessible in workspace
    └── agama-bugzilla-screener.skill # Packaged skill bundle
```

---

## Using the Bugzilla Screener in Gemini CLI

Once `./run.sh` drops you into Gemini CLI, the `agama-bugzilla-screener` skill is automatically active.

### Example Prompts:

- **Check High-Priority Needinfo Queues**:
  > *"Check if there are any Bugzilla bugs with needinfo requested on yast-maintainers or yast-internal."*

- **Triage Untriaged Agama Bugs**:
  > *"Scan for new untriaged Agama bugs and check which ones are ready for backlog cards."*

- **Screen a Specific Bug**:
  > *"Screen bug 1234567. Check if it's ready for an Agama card, and if not, draft a request for logs."*
  *(When logs are missing, the agent will instruct the reporter to collect them using `agama logs store` or the web UI download icon).*

- **Out-of-Scope Reassignment**:
  > *"Analyze the attached logs for bug 1234567 to see if this is an Agama bug or should be reassigned to kernel/storage/network."*

- **Sprint Handover Digest**:
  > *"Generate the sprint handover note for Agama bugs: list bugs waiting on needinfo, cards ready for the backlog, and any open CVEs."*

---

## Using with Claude (Desktop / CLI)

If you also wish to use this skill with Claude Desktop or Claude Code, see the detailed instructions in [`workspace/agama-bugzilla-screener/README.md`](workspace/agama-bugzilla-screener/README.md).
