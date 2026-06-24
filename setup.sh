#!/usr/bin/env bash
# Deploy quadlet files to a local Podman VM for developer testing.
set -euo pipefail

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

usage() {
  echo "Usage: $(basename "$0") -d <service-dir> [-m <machine>]"
  echo ""
  echo "  -d <service-dir>  Directory containing quadlet files (required)"
  echo "  -m <machine>      Podman machine name (default: \$PODMAN_MACHINE or podman-machine-default)"
  echo ""
  echo "Example:"
  echo "  $(basename "$0") -d ./rabbitmq"
  echo "  $(basename "$0") -d ./authentik -m my-dev-vm"
  exit 1
}

SERVICE_DIR=""
MACHINE="${PODMAN_MACHINE:-podman-machine-default}"

while getopts ":d:m:" opt; do
  case $opt in
  d) SERVICE_DIR="$(cd "$OPTARG" && pwd)" ;;
  m) MACHINE="$OPTARG" ;;
  *) usage ;;
  esac
done

[[ -n "$SERVICE_DIR" ]] || usage
[[ -d "$SERVICE_DIR" ]] || {
  echo "❌ Directory not found: $OPTARG" >&2
  exit 1
}

SERVICE_NAME="$(basename "$SERVICE_DIR")"
POD_SERVICE="${SERVICE_NAME}-pod.service"
QUADLET_DEST="~/.config/containers/systemd/${SERVICE_NAME}"
HEALTH_TIMEOUT=120
HEALTH_INTERVAL=5

# ---------------------------------------------------------------------------
# Output helpers
# ---------------------------------------------------------------------------

info() { echo "ℹ️  $*"; }
success() { echo "✅ $*"; }
warn() { echo "⚠️  $*"; }
step() {
  echo ""
  echo "🔧 $*"
}

die() {
  echo "" >&2
  echo "❌ $*" >&2
  exit 1
}

vm_ssh() {
  podman machine ssh "$MACHINE" -- "$@"
}

# ---------------------------------------------------------------------------
# Banner
# ---------------------------------------------------------------------------

echo ""
echo "🐳 Podman VM Deploy — ${SERVICE_NAME}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
info "Service : $SERVICE_NAME"
info "Machine : $MACHINE"
info "Source  : $SERVICE_DIR"
info "Dest    : $QUADLET_DEST"

# ---------------------------------------------------------------------------
# 1. Verify machine is running
# ---------------------------------------------------------------------------

step "Checking Podman machine..."

if ! podman machine inspect "$MACHINE" &>/dev/null; then
  die "Podman machine '$MACHINE' not found. Run: podman machine init $MACHINE"
fi

MACHINE_STATE=$(podman machine inspect "$MACHINE" --format '{{.State}}' 2>/dev/null || echo "unknown")
if [[ "$MACHINE_STATE" != "running" ]]; then
  warn "Machine is '${MACHINE_STATE}' — starting it..."
  podman machine start "$MACHINE" || die "Failed to start machine '$MACHINE'"
fi
success "Machine is running"

# ---------------------------------------------------------------------------
# 2. Locate quadlet files
# ---------------------------------------------------------------------------

step "Locating quadlet files in ${SERVICE_DIR}..."

QUADLET_FILES=()
for ext in container pod volume network yml yaml; do
  while IFS= read -r -d '' f; do
    QUADLET_FILES+=("$f")
  done < <(find "$SERVICE_DIR" -maxdepth 1 -name "*.${ext}" -print0 2>/dev/null || true)
done

[[ ${#QUADLET_FILES[@]} -gt 0 ]] || die "No quadlet files (.container, .pod, .volume, .network) found in $SERVICE_DIR"

for f in "${QUADLET_FILES[@]}"; do
  info "  📄 $(basename "$f")"
done

# ---------------------------------------------------------------------------
# 3. Create destination directory on VM
# ---------------------------------------------------------------------------

step "Ensuring quadlet directory exists on VM..."
vm_ssh "mkdir -p $QUADLET_DEST" || die "Failed to create $QUADLET_DEST on VM"
success "Directory ready: $QUADLET_DEST"

# ---------------------------------------------------------------------------
# 4. Copy files to VM
# ---------------------------------------------------------------------------

step "Copying quadlet files to VM..."
COPY_ERRORS=0

for file in "${QUADLET_FILES[@]}"; do
  filename="$(basename "$file")"
  if podman machine cp "$file" "${MACHINE}:${QUADLET_DEST}/${filename}"; then
    success "  Copied $filename"
  else
    echo "❌  Failed to copy $filename" >&2
    ((COPY_ERRORS++)) || true
  fi
done

[[ $COPY_ERRORS -eq 0 ]] || die "$COPY_ERRORS file(s) failed to copy — aborting"

# ---------------------------------------------------------------------------
# 5. Reload systemd daemon
# ---------------------------------------------------------------------------

step "Reloading systemd daemon on VM..."
vm_ssh "systemctl --user daemon-reload" || die "Failed to reload systemd daemon"
success "Systemd daemon reloaded"

# ---------------------------------------------------------------------------
# 6. Restart service
# ---------------------------------------------------------------------------

step "Restarting ${POD_SERVICE}..."
if ! vm_ssh "systemctl --user restart ${POD_SERVICE}" 2>/dev/null; then
  warn "${POD_SERVICE} not found — attempting enable instead..."
  vm_ssh "systemctl --user enable --now ${POD_SERVICE}" ||
    die "Failed to start ${POD_SERVICE}. Run: journalctl --user -u ${POD_SERVICE}"
fi
success "${POD_SERVICE} started"

# ---------------------------------------------------------------------------
# 7. Wait for healthy
# ---------------------------------------------------------------------------

# Skip health wait if the container has no health check configured
ELAPSED=0
HEALTH_SKIPPED=false

step "Waiting for container to become healthy (timeout: ${HEALTH_TIMEOUT}s)..."

while true; do
  RAW=$(vm_ssh "podman inspect --format '{{.State.Health.Status}}' ${SERVICE_NAME}" 2>/dev/null || true)
  STATUS="${RAW//[^a-zA-Z]/}" # strip any stray whitespace/control chars

  case "$STATUS" in
  healthy)
    success "Container is healthy! 🎉"
    break
    ;;
  "")
    # No health check defined — just confirm the container is running
    RUNNING=$(vm_ssh "podman inspect --format '{{.State.Status}}' ${SERVICE_NAME}" 2>/dev/null || true)
    if [[ "$RUNNING" == "running" ]]; then
      success "Container is running (no health check configured)"
      HEALTH_SKIPPED=true
      break
    fi
    ;;
  esac

  if [[ $ELAPSED -ge $HEALTH_TIMEOUT ]]; then
    warn "Timed out after ${HEALTH_TIMEOUT}s (last status: ${STATUS:-unknown})"
    warn "Check logs: journalctl --user -u ${POD_SERVICE} -f"
    break
  fi

  echo "   ⏳ Status: ${STATUS:-starting} — ${ELAPSED}s elapsed..."
  sleep $HEALTH_INTERVAL
  ((ELAPSED += HEALTH_INTERVAL)) || true
done

# ---------------------------------------------------------------------------
# 8. Summary
# ---------------------------------------------------------------------------

# Parse published ports from the .pod file (if present)
PORTS=()
POD_FILE="${SERVICE_DIR}/${SERVICE_NAME}.pod"
if [[ -f "$POD_FILE" ]]; then
  while IFS= read -r line; do
    if [[ "$line" =~ ^PublishPort=([0-9]+):([0-9]+) ]]; then
      PORTS+=("  🔌 localhost:${BASH_REMATCH[1]}  →  container:${BASH_REMATCH[2]}")
    fi
  done <"$POD_FILE"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🚀 ${SERVICE_NAME} is deployed on VM: ${MACHINE}"
echo ""
if [[ ${#PORTS[@]} -gt 0 ]]; then
  echo "📡 Ports (host → container):"
  for p in "${PORTS[@]}"; do echo "$p"; done
  echo ""
fi
echo "📋 Useful commands:"
echo "     Status : podman machine ssh ${MACHINE} -- systemctl --user status ${POD_SERVICE}"
echo "     Logs   : podman machine ssh ${MACHINE} -- journalctl --user -u ${POD_SERVICE} -f"
echo "     Stop   : podman machine ssh ${MACHINE} -- systemctl --user stop ${POD_SERVICE}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
