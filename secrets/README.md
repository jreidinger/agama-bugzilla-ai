# Secrets Directory

This directory stores credentials and API tokens required by local services (such as the Bugzilla MCP server).

## Security Notice

- Files in this directory (except `*.example` and `README.md`) are ignored by `.gitignore`.
- This directory is **never** mounted into the Gemini CLI container, ensuring the AI agent cannot read your API tokens.

## How to Set Up Your Bugzilla Token

1. Create a file named `bugzilla-token.txt` in this directory:
   ```bash
   echo "YOUR_BUGZILLA_API_KEY" > secrets/bugzilla-token.txt
   chmod 600 secrets/bugzilla-token.txt
   ```
2. The `run.sh` script will automatically load this file when launching the `mcp-bugzilla` server container.
