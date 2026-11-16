# Gemini CLI Workspace

This directory is the mounted working directory for the Gemini CLI container.

## Environment & Configuration

- **Security Isolation**: This workspace is the only directory mounted into the Gemini CLI container (`-v $PWD/workspace:/home/sandbox/tmp:Z`). Top-level repository files and secrets are completely inaccessible to the container.
- **MCP Server Connection**: Configured in `.gemini/settings.json` to connect to the local Bugzilla MCP server at `http://127.0.0.1:9125/mcp/`.
- **Preloaded Skill**: The `agama-bugzilla-screener` skill is installed in `.gemini/skills/agama-bugzilla-screener/` and available automatically.

## Quick Usage

Inside your Gemini CLI session:
- *"Check for bugs with needinfo requested on yast-maintainers or yast-internal."*
- *"Scan for untriaged Agama bugs and check if any are ready for backlog cards."*
- *"Screen bug <ID> and evaluate if diagnostic logs are needed."*
- *"Generate the sprint handover report."*
