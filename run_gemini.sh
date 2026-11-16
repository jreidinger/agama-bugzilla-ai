#!/usr/bin/env bash
#
# run.sh - Orchestration script for Agama Bugzilla AI Screener
#
# 1. Verifies that secrets/bugzilla-token.txt exists and contains a valid API key
# 2. Fetches latest container images for mcp-bugzilla and gemini-cli
# 3. Starts openSUSE mcp-bugzilla server in read-only mode on port 9125
# 4. Mounts the isolated workspace directory to gemini-cli (protecting top-level secrets)
# 5. Cleans up background MCP container when gemini-cli exits

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SECRETS_DIR="${SCRIPT_DIR}/secrets"
TOKEN_FILE="${SECRETS_DIR}/bugzilla-token.txt"
WORKSPACE_DIR="${SCRIPT_DIR}/workspace"

MCP_PORT="${MCP_PORT:-9125}"
BUGZILLA_SERVER="${BUGZILLA_SERVER:-https://bugzilla.suse.com}"
GEMINI_HOME="${GEMINI_HOME:-$HOME/.gemini}"

MCP_IMAGE="${MCP_IMAGE:-registry.opensuse.org/opensuse/mcp-bugzilla:latest}"
GEMINI_IMAGE="${GEMINI_IMAGE:-registry.opensuse.org/devel/bci/tumbleweed/containerfile/opensuse/gemini-cli:latest}"

MCP_CONTAINER_NAME="agama-mcp-bugzilla-$$"

# 1. Ensure required directories exist
mkdir -p "${SECRETS_DIR}" "${WORKSPACE_DIR}/.gemini"

# 2. Check that secrets/bugzilla-token.txt exists and contains an API key
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

# Extract token, ignoring comment lines starting with '#' and stripping whitespace
BUGZILLA_API_KEY="$(grep -v '^[[:space:]]*#' "${TOKEN_FILE}" | tr -d '[:space:]' || true)"

if [ -z "${BUGZILLA_API_KEY}" ] || [ "${BUGZILLA_API_KEY}" = "YOUR_BUGZILLA_API_KEY_HERE" ]; then
  echo "❌ Error: Secrets file '${TOKEN_FILE}' does not contain a valid Bugzilla API key." >&2
  echo "It is currently empty, contains only comments, or still has the placeholder text." >&2
  echo "" >&2
  echo "Please save your actual Bugzilla API key as a single line in '${TOKEN_FILE}'." >&2
  exit 1
fi

echo "==> [Auth] Loaded Bugzilla API key from ${TOKEN_FILE}"

# 3. Always fetch latest container images
echo "==> [Fetch] Pulling latest container images..."
podman pull "${MCP_IMAGE}"
podman pull "${GEMINI_IMAGE}"

# 4. Cleanup trap to terminate background MCP container upon script exit or signal
cleanup() {
  echo ""
  echo "==> [Cleanup] Stopping Bugzilla MCP container (${MCP_CONTAINER_NAME})..."
  podman stop -t 2 "${MCP_CONTAINER_NAME}" >/dev/null 2>&1 || true
}
trap cleanup EXIT INT TERM

# 5. Ensure workspace .gemini/settings.json points to local MCP server
cat <<EOF > "${WORKSPACE_DIR}/.gemini/settings.json"
{
  "mcpServers": {
    "bugzilla": {
      "url": "http://127.0.0.1:${MCP_PORT}/mcp/",
      "type": "http"
    }
  }
}
EOF

# 6. Start the openSUSE mcp-bugzilla container in read-only mode
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

# 7. Launch Gemini CLI container
# Note: Only $WORKSPACE_DIR is mounted to /home/sandbox/tmp, isolating $SECRETS_DIR.
echo "==> [Gemini] Starting Gemini CLI in workspace: ${WORKSPACE_DIR}..."
podman run --rm \
  --userns=keep-id:uid=499 \
  -it \
  --network host \
  -e NODE_TLS_REJECT_UNAUTHORIZED=0 \
  -v "${GEMINI_HOME}:/home/sandbox/.gemini:Z" \
  -v "${WORKSPACE_DIR}:/home/sandbox/tmp:Z" \
  "${GEMINI_IMAGE}" "$@"
