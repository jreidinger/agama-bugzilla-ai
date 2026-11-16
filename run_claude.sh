#!/usr/bin/env bash
#
# run_claude.sh - Orchestration script for Agama Bugzilla AI Screener using Claude
#
# 1. Verifies that secrets/bugzilla-token.txt exists and contains a valid API key
# 2. Ensures latest version of Claude Code is used (rebuilding fast npm layer if outdated)
# 3. Starts openSUSE mcp-bugzilla server in read-only mode on port 9125
# 4. Prepares workspace/.mcp.json and workspace/.claude/settings.json
# 5. Mounts the isolated workspace directory to Claude (protecting top-level secrets)
# 6. Cleans up background MCP container when Claude exits

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SECRETS_DIR="${SCRIPT_DIR}/secrets"
TOKEN_FILE="${SECRETS_DIR}/bugzilla-token.txt"
WORKSPACE_DIR="${SCRIPT_DIR}/workspace"

MCP_PORT="${MCP_PORT:-9125}"
BUGZILLA_SERVER="${BUGZILLA_SERVER:-https://bugzilla.suse.com}"

MCP_IMAGE="${MCP_IMAGE:-registry.opensuse.org/opensuse/mcp-bugzilla:latest}"
CLAUDE_IMAGE="${CLAUDE_IMAGE:-claude-code:latest}"

MCP_CONTAINER_NAME="agama-mcp-bugzilla-claude-$$"

# 1. Ensure required directories exist
mkdir -p "${SECRETS_DIR}" "${WORKSPACE_DIR}/.claude"

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

# 3. Ensure container images are up-to-date
echo "==> [Fetch] Pulling latest Bugzilla MCP server image..."
podman pull "${MCP_IMAGE}"

# Check latest npm release of @anthropic-ai/claude-code
LATEST_CLAUDE_VER=""
if command -v curl >/dev/null 2>&1; then
  LATEST_CLAUDE_VER="$(curl -s -f --connect-timeout 4 https://registry.npmjs.org/@anthropic-ai/claude-code/latest 2>/dev/null | grep -o '"version":"[^"]*"' | head -n1 | cut -d'"' -f4 || true)"
fi

NEED_BUILD=false
if ! podman image exists "${CLAUDE_IMAGE}" 2>/dev/null; then
  echo "==> [Claude] Local image '${CLAUDE_IMAGE}' not found. Building..."
  NEED_BUILD=true
elif [ -n "${LATEST_CLAUDE_VER}" ]; then
  INSTALLED_VER="$(podman run --rm "${CLAUDE_IMAGE}" claude --version 2>/dev/null | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+' | head -n1 || true)"
  if [ -n "${INSTALLED_VER}" ] && [ "${INSTALLED_VER}" != "${LATEST_CLAUDE_VER}" ]; then
    echo "==> [Claude] New Claude Code release found: v${LATEST_CLAUDE_VER} (installed: v${INSTALLED_VER})."
    echo "             Updating npm package (reusing cached OS packages)..."
    NEED_BUILD=true
  else
    echo "==> [Claude] Image '${CLAUDE_IMAGE}' is up-to-date (v${INSTALLED_VER:-latest})."
  fi
fi

if [ "${NEED_BUILD}" = true ]; then
  if [ -f "${SCRIPT_DIR}/Containerfile.claude" ]; then
    BUILD_ARGS=()
    if [ -n "${LATEST_CLAUDE_VER}" ]; then
      BUILD_ARGS+=("--build-arg" "CLAUDE_VERSION=${LATEST_CLAUDE_VER}")
    fi
    podman build "${BUILD_ARGS[@]}" -t "${CLAUDE_IMAGE}" -f "${SCRIPT_DIR}/Containerfile.claude" "${SCRIPT_DIR}"
  else
    echo "==> [Claude] Pulling ${CLAUDE_IMAGE}..."
    podman pull "${CLAUDE_IMAGE}"
  fi
fi

# 4. Cleanup trap to terminate background MCP container upon script exit or signal
cleanup() {
  echo ""
  echo "==> [Cleanup] Stopping Bugzilla MCP container (${MCP_CONTAINER_NAME})..."
  podman stop -t 2 "${MCP_CONTAINER_NAME}" >/dev/null 2>&1 || true
}
trap cleanup EXIT INT TERM

# 5. Ensure workspace .mcp.json and .claude/settings.json point to local MCP server
cat <<EOF > "${WORKSPACE_DIR}/.mcp.json"
{
  "mcpServers": {
    "bugzilla": {
      "type": "http",
      "url": "http://127.0.0.1:${MCP_PORT}/mcp/"
    }
  }
}
EOF

cat <<EOF > "${WORKSPACE_DIR}/.claude/settings.json"
{
  "enableAllProjectMcpServers": true
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
  echo "==> [MCP] Warning: Endpoint check timed out. Proceeding to launch Claude..."
fi

# 7. Launch Claude container inside isolated workspace
echo "==> [Claude] Starting Claude in workspace: ${WORKSPACE_DIR}..."

CLAUDE_HOME="${CLAUDE_HOME:-$HOME/.claude}"
CLAUDE_JSON="${CLAUDE_JSON:-$HOME/.claude.json}"

CLAUDE_MOUNTS=(
  "-v" "${WORKSPACE_DIR}:/workspace:Z"
  "-w" "/workspace"
)

if [ -d "${CLAUDE_HOME}" ]; then
  CLAUDE_MOUNTS+=("-v" "${CLAUDE_HOME}:/root/.claude:Z")
fi

if [ -f "${CLAUDE_JSON}" ]; then
  CLAUDE_MOUNTS+=("-v" "${CLAUDE_JSON}:/root/.claude.json:Z")
fi

CLAUDE_ENV_OPTS=()
if [ -n "${ANTHROPIC_API_KEY:-}" ]; then
  CLAUDE_ENV_OPTS+=("-e" "ANTHROPIC_API_KEY=${ANTHROPIC_API_KEY}")
fi

podman run --rm \
  -it \
  --network host \
  "${CLAUDE_MOUNTS[@]}" \
  "${CLAUDE_ENV_OPTS[@]}" \
  "${CLAUDE_IMAGE}" "$@"
