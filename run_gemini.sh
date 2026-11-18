#!/usr/bin/env bash
#
# run_gemini.sh - Orchestration script for Agama Bugzilla & GitHub AI Screener
#
# 1. Verifies that secrets/bugzilla-token.txt and secrets/github-token.txt exist
# 2. Fetches latest container images for mcp-bugzilla and gemini-cli
# 3. Starts openSUSE mcp-bugzilla server in read-only mode on port 9125
# 4. Configures Bugzilla and GitHub read-only MCP servers in workspace/.gemini/settings.json
# 5. Mounts the isolated workspace directory to gemini-cli (protecting top-level secrets)
# 6. Cleans up background MCP container when gemini-cli exits

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SECRETS_DIR="${SCRIPT_DIR}/secrets"
TOKEN_FILE="${SECRETS_DIR}/bugzilla-token.txt"
GITHUB_TOKEN_FILE="${SECRETS_DIR}/github-token.txt"
WORKSPACE_DIR="${SCRIPT_DIR}/workspace"

MCP_PORT="${MCP_PORT:-9125}"
BUGZILLA_SERVER="${BUGZILLA_SERVER:-https://bugzilla.suse.com}"
GEMINI_HOME="${GEMINI_HOME:-$HOME/.gemini}"

MCP_IMAGE="${MCP_IMAGE:-registry.opensuse.org/opensuse/mcp-bugzilla:latest}"
GEMINI_IMAGE="${GEMINI_IMAGE:-registry.opensuse.org/devel/bci/tumbleweed/containerfile/opensuse/gemini-cli:latest}"

MCP_CONTAINER_NAME="agama-mcp-bugzilla-$$"

# 1. Ensure required directories exist
mkdir -p "${SECRETS_DIR}" "${WORKSPACE_DIR}/.gemini"

# 2. Check Bugzilla token
if [ ! -f "${TOKEN_FILE}" ]; then
  echo "❌ Error: Secrets file '${TOKEN_FILE}' does not exist." >&2
  echo "" >&2
  echo "Please create '${TOKEN_FILE}' with your Bugzilla API key:" >&2
  echo "  echo \"YOUR_BUGZILLA_API_KEY\" > '${TOKEN_FILE}'" >&2
  echo "  chmod 600 '${TOKEN_FILE}'" >&2
  echo "" >&2
  echo "You can generate an API key in Bugzilla under Preferences -> API Keys." >&2
  exit 1
fi

BUGZILLA_API_KEY="$(grep -v '^[[:space:]]*#' "${TOKEN_FILE}" | tr -d '[:space:]' || true)"

if [ -z "${BUGZILLA_API_KEY}" ] || [ "${BUGZILLA_API_KEY}" = "YOUR_BUGZILLA_API_KEY_HERE" ]; then
  echo "❌ Error: Secrets file '${TOKEN_FILE}' does not contain a valid Bugzilla API key." >&2
  echo "It is currently empty, contains only comments, or still has the placeholder text." >&2
  echo "" >&2
  echo "Please save your actual Bugzilla API key as a single line in '${TOKEN_FILE}'." >&2
  exit 1
fi

echo "==> [Auth] Loaded Bugzilla API key from ${TOKEN_FILE}"

# 3. Check GitHub read-only token
if [ ! -f "${GITHUB_TOKEN_FILE}" ]; then
  echo "❌ Error: Secrets file '${GITHUB_TOKEN_FILE}' does not exist." >&2
  echo "" >&2
  echo "Please create '${GITHUB_TOKEN_FILE}' with your read-only GitHub Personal Access Token:" >&2
  echo "  1. Go to https://github.com/settings/personal-access-tokens" >&2
  echo "  2. Select 'agama-project' only in repository access" >&2
  echo "  3. Set Read-only permissions:
     - Repositories tab: Issues, Pull requests, Metadata
     - Organization tab: Projects" >&2
  echo "  4. Save your token into '${GITHUB_TOKEN_FILE}':" >&2
  echo "     echo \"YOUR_GITHUB_TOKEN\" > '${GITHUB_TOKEN_FILE}'" >&2
  echo "     chmod 600 '${GITHUB_TOKEN_FILE}'" >&2
  exit 1
fi

GITHUB_TOKEN="$(grep -v '^[[:space:]]*#' "${GITHUB_TOKEN_FILE}" | tr -d '[:space:]' || true)"

if [ -z "${GITHUB_TOKEN}" ] || [ "${GITHUB_TOKEN}" = "YOUR_GITHUB_READONLY_TOKEN_HERE" ]; then
  echo "❌ Error: Secrets file '${GITHUB_TOKEN_FILE}' does not contain a valid GitHub token." >&2
  echo "Please save your actual GitHub read-only token as a single line in '${GITHUB_TOKEN_FILE}'." >&2
  exit 1
fi

echo "==> [Auth] Loaded GitHub read-only token from ${GITHUB_TOKEN_FILE}"

# 4. Always fetch latest container images
echo "==> [Fetch] Pulling latest container images..."
podman pull "${MCP_IMAGE}"
podman pull "${GEMINI_IMAGE}"

# 5. Cleanup trap to terminate background MCP container and remove runtime configs upon script exit or signal
cleanup() {
  echo ""
  echo "==> [Cleanup] Stopping Bugzilla MCP container (${MCP_CONTAINER_NAME})..."
  podman stop -t 2 "${MCP_CONTAINER_NAME}" >/dev/null 2>&1 || true
  rm -f "${WORKSPACE_DIR}/.gemini/settings.json"
}
trap cleanup EXIT INT TERM

# 6. Configure Bugzilla and GitHub read-only MCP servers in workspace
cat <<EOF > "${WORKSPACE_DIR}/.gemini/settings.json"
{
  "mcpServers": {
    "bugzilla": {
      "url": "http://127.0.0.1:${MCP_PORT}/mcp/",
      "type": "http"
    },
    "github": {
      "url": "https://api.githubcopilot.com/mcp/readonly",
      "type": "http",
      "headers": {
        "Authorization": "Bearer ${GITHUB_TOKEN}",
        "X-MCP-Readonly": "true",
        "X-MCP-Toolsets": "default,projects"
      }
    }
  }
}
EOF

# 7. Start the openSUSE mcp-bugzilla container in read-only mode
echo "==> [MCP] Starting openSUSE Bugzilla MCP server on 127.0.0.1:${MCP_PORT}..."
MCP_ENV_OPTS=(
  "-e" "BUGZILLA_SERVER=${BUGZILLA_SERVER}"
  "-e" "MCP_READ_ONLY=true"
  "-e" "MCP_HOST=0.0.0.0"
  "-e" "MCP_PORT=8000"
  "-e" "BUGZILLA_API_KEY=${BUGZILLA_API_KEY}"
)

podman run -d --rm \
  --name "${MCP_CONTAINER_NAME}" \
  -p "127.0.0.1:${MCP_PORT}:8000" \
  "${MCP_ENV_OPTS[@]}" \
  "${MCP_IMAGE}" >/dev/null

# Wait for MCP endpoint to become responsive
echo "==> [MCP] Waiting for server endpoint to respond..."
READY=false
for i in $(seq 1 40); do
  if curl -s -f -o /dev/null "http://127.0.0.1:${MCP_PORT}/mcp/" 2>/dev/null || \
     curl -s -f -o /dev/null "http://127.0.0.1:${MCP_PORT}/" 2>/dev/null; then
    READY=true
    break
  fi
  sleep 0.5
done

if [ "${READY}" = true ]; then
  echo "==> [MCP] Bugzilla MCP server is ready at http://127.0.0.1:${MCP_PORT}/mcp/"
else
  echo "==> [MCP] Warning: Endpoint check timed out. Proceeding to launch Gemini CLI..."
fi

# 8. Launch Gemini CLI container
# Note: Only $WORKSPACE_DIR is mounted to /home/sandbox/tmp, isolating $SECRETS_DIR.
echo "==> [Gemini] Starting Gemini CLI in workspace: ${WORKSPACE_DIR}..."
podman run --rm \
  --userns=keep-id:uid=499 \
  -it \
  --network host \
  -e NODE_TLS_REJECT_UNAUTHORIZED=0 \
  -e GITHUB_TOKEN="${GITHUB_TOKEN}" \
  -v "${GEMINI_HOME}:/home/sandbox/.gemini:Z" \
  -v "${WORKSPACE_DIR}:/home/sandbox/tmp:Z" \
  "${GEMINI_IMAGE}" "$@"
