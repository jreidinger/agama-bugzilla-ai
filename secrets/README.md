# Secrets Directory

This directory stores credentials and API tokens required by local services and remote MCP servers.

## Security Notice

- Files in this directory (except `*.example` and `README.md`) are ignored by `.gitignore`.
- This directory is **never** mounted into the AI agent containers (`gemini-cli` or `claude-code`), ensuring agents cannot read your raw token files.

## Required Secrets

### 1. Bugzilla API Token (`secrets/bugzilla-token.txt`)
- Generate at: https://bugzilla.suse.com ➡️ Preferences ➡️ API Keys
- Setup:
  ```bash
  echo "YOUR_BUGZILLA_API_KEY" > secrets/bugzilla-token.txt
  chmod 600 secrets/bugzilla-token.txt
  ```

### 2. GitHub Read-Only Personal Access Token (`secrets/github-token.txt`)
- Generate at: https://github.com/settings/personal-access-tokens
- **Repository Access**: Select `agama-project` repositories only.
- **Permissions**:
  - **Repositories tab**: Read-only access to Issues, Pull requests, and Metadata.
  - **Organization tab**: Read-only access to Projects.
- Setup:
  ```bash
  echo "YOUR_GITHUB_TOKEN" > secrets/github-token.txt
  chmod 600 secrets/github-token.txt
  ```
