# Agama Bugzilla Screener

An automated bug screening and triage assistant for the openSUSE / SUSE [Agama](https://github.com/agama-project/agama) installer project.

This skill equips AI agents (such as **Gemini CLI** and **Claude**) with the domain knowledge and procedural workflows needed to screen incoming Agama Bugzilla reports, evaluate card readiness, request diagnostic logs, identify out-of-scope issues, and prepare sprint handovers.

---

## Architecture & Operational Principle

```
┌────────────────────────────────────────────────────────┐
│               AI Agent (Gemini CLI / Claude)           │
│                                                        │
│  [agama-bugzilla-screener Skill / Custom Instructions] │
└───────────────────────┬────────────────────────────────┘
                        │ Model Context Protocol (MCP)
                        ▼
┌────────────────────────────────────────────────────────┐
│     openSUSE/mcp-bugzilla Server (--read-only)         │
└───────────────────────┬────────────────────────────────┘
                        │ Bugzilla REST API
                        ▼
┌────────────────────────────────────────────────────────┐
│  SUSE / openSUSE Bugzilla (bugzilla.suse.com)          │
└────────────────────────────────────────────────────────┘
```

> 🔒 **Read-Only Safety Guarantee**:
> The MCP server and skill operate in **read-only / advisory mode**. The agent does not modify Bugzilla records directly. Instead, it inspects bugs and generates prepared output packages (Bugzilla links, card proposals, draft comments, and flag change recommendations) for the human maintainer to review and apply.

---

## 1. Setting up `mcp-bugzilla` Server

The skill connects to Bugzilla via the [`openSUSE/mcp-bugzilla`](https://github.com/openSUSE/mcp-bugzilla) MCP server.

### Prerequisites

- **Python**: 3.13 or newer
- **Package Runner**: `uv` / `uvx` (recommended) or `pip` / container engine (`podman` / `docker`)
- **Bugzilla API Key**: Generate an API key in Bugzilla via **Preferences** ➡️ **API Keys**

### Running with `uvx` (Recommended)

`uvx` executes the package in an isolated temporary environment without permanent installation:

```bash
# Test running the server in read-only stdio mode against SUSE Bugzilla
BUGZILLA_API_KEY="YOUR_API_KEY" uvx mcp-bugzilla \
  --bugzilla-server https://bugzilla.suse.com \
  --transport stdio \
  --read-only
```

*(For openSUSE Bugzilla, use `--bugzilla-server https://bugzilla.opensuse.org`)*.

### Alternative: Running with Containers (Podman / Docker)

If you prefer running via a container over HTTP transport:

```bash
podman run -d -p 8000:8000 \
  -e BUGZILLA_SERVER=https://bugzilla.suse.com \
  -e BUGZILLA_API_KEY="YOUR_API_KEY" \
  -e MCP_READ_ONLY=true \
  -e MCP_HOST=0.0.0.0 \
  -e MCP_PORT=8000 \
  registry.opensuse.org/opensuse/mcp-bugzilla:latest
```

---

## 2. Setup with Gemini CLI

### Step 2.1: Configure the MCP Server

Add the Bugzilla MCP server to your Gemini CLI configuration.

Edit or create `.gemini/settings.json` (or `gemini.json` in your workspace/home directory):

```json
{
  "mcpServers": {
    "bugzilla": {
      "command": "uvx",
      "args": [
        "mcp-bugzilla",
        "--bugzilla-server",
        "https://bugzilla.suse.com",
        "--transport",
        "stdio",
        "--read-only"
      ],
      "env": {
        "BUGZILLA_API_KEY": "YOUR_BUGZILLA_API_KEY"
      }
    }
  }
}
```

*If using the HTTP container daemon instead:*
```json
{
  "mcpServers": {
    "bugzilla": {
      "url": "http://127.0.0.1:8000/mcp/"
    }
  }
}
```

### Step 2.2: Install the Skill

You can install the packaged `.skill` bundle or copy the skill directory.

#### Option A: Install via `gemini skills` CLI (Recommended)

Package the skill (if not already packaged):
```bash
python3 -c "
import os, zipfile
skill_dir = 'agama-bugzilla-screener'
output_file = 'agama-bugzilla-screener.skill'
with zipfile.ZipFile(output_file, 'w', zipfile.ZIP_DEFLATED) as zf:
    for root, _, files in os.walk(skill_dir):
        for f in files:
            p = os.path.join(root, f)
            zf.write(p, os.path.relpath(p, skill_dir))
"
```

Install into workspace scope:
```bash
gemini skills install agama-bugzilla-screener.skill --scope workspace
```
*(Or use `--scope user` for global access across all workspaces).*

#### Option B: Direct Workspace Folder
Place the `agama-bugzilla-screener/` folder inside your project directory or `.gemini/skills/agama-bugzilla-screener/`.

### Step 2.3: Reload and Verify

In an interactive Gemini CLI session:
1. Reload skills:
   ```text
   /skills reload
   ```
2. Verify that `agama-bugzilla-screener` is listed:
   ```text
   /skills list
   ```

---

## 3. Setup with Claude

### Option A: Claude Desktop

#### Step 3.1: Configure MCP Server
Open your Claude Desktop configuration file:
- **Linux**: `~/.config/Claude/claude_desktop_config.json`
- **macOS**: `~/Library/Application Support/Claude/claude_desktop_config.json`
- **Windows**: `%APPDATA%\Claude\claude_desktop_config.json`

Add the `bugzilla` server under `mcpServers`:

```json
{
  "mcpServers": {
    "bugzilla": {
      "command": "uvx",
      "args": [
        "mcp-bugzilla",
        "--bugzilla-server",
        "https://bugzilla.suse.com",
        "--transport",
        "stdio",
        "--read-only"
      ],
      "env": {
        "BUGZILLA_API_KEY": "YOUR_BUGZILLA_API_KEY"
      }
    }
  }
}
```

Restart Claude Desktop. A hammer icon 🔨 should appear indicating the Bugzilla tools are available.

#### Step 3.2: Load the Skill Instructions
1. In Claude Desktop, create a new **Project** named **Agama Bug Screening**.
2. Under **Project Knowledge**, upload the files:
   - `SKILL.md`
   - `references/queries.md`
   - `references/card-readiness.md`
   - `references/comment-templates.md`
3. Under **Custom Instructions**, paste:
   ```text
   You are the Agama Bug Screener assistant. Follow the procedures and rules in SKILL.md and its references. Always operate in read-only mode, inspect bugs via Bugzilla MCP tools, verify card readiness against the 4-point checklist, instruct reporters to collect logs using `agama logs store` or the web UI, and prepare ready-to-paste response packages with Bugzilla URLs for the maintainer.
   ```

---

### Option B: Claude Code (CLI)

#### Step 3.1: Add MCP Server to Claude Code
Run the following command in your terminal:

```bash
claude mcp add bugzilla uvx mcp-bugzilla \
  --bugzilla-server https://bugzilla.suse.com \
  --transport stdio \
  --read-only
```

Set your API key in your environment (`export BUGZILLA_API_KEY="YOUR_KEY"` in `~/.bashrc` or `~/.zshrc`).

#### Step 3.2: Add Skill Instructions to `CLAUDE.md`
In your workspace root, add or update `CLAUDE.md`:

```markdown
# Agama Bug Screening Instructions

When asked to screen, triage, or analyze Agama Bugzilla bugs:
- Read and follow `agama-bugzilla-screener/SKILL.md` and files in `agama-bugzilla-screener/references/`.
- Never execute write operations on Bugzilla. Always run in read-only mode.
- Target bugs with `needinfo?` set on `yast-maintainers` or `yast-internal`.
- When requesting logs, always specify `agama logs store` or the web UI download icon.
- Format card-ready bugs using the template in `references/card-readiness.md`.
```

---

## 4. Usage Examples & Prompts

Once configured, you can interact with the agent using natural language prompts:

### Scan Team Needinfo Queues
> *"Check if there are any Bugzilla bugs with needinfo requested on yast-maintainers or yast-internal."*

### Triage Incoming Untriaged Bugs
> *"Scan for new untriaged Agama bugs and check which ones are ready for backlog cards."*

### Screen a Specific Bug Report
> *"Screen bug 1234567. Check if it's ready for an Agama card, and if not, draft a request for logs."*

### Generate Sprint Handover Digest
> *"Generate the sprint handover note for Agama bugs: list bugs waiting on needinfo, cards ready for the backlog, and any open CVEs."*

---

## 5. File Structure Reference

```
agama-bugzilla-screener/
├── README.md                         # Setup and configuration guide (this file)
├── SKILL.md                          # Skill definition, trigger description & workflow
└── references/
    ├── queries.md                    # Quicksearch syntax for needinfo lists & queues
    ├── card-readiness.md             # 4-point checklist and GitHub backlog card format
    └── comment-templates.md          # Copy-paste responses (logs request, reassignments, handover)
```
