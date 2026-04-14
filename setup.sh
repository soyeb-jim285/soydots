#!/usr/bin/env bash
# jimdots setup orchestrator.
# Usage:
#   ./setup.sh                       # run all phases
#   ./setup.sh --only symlinks       # run one phase
#   ./setup.sh --only packages,system
#   ./setup.sh --dry-run             # show actions, change nothing
#   ./setup.sh --yes                 # assume yes for confirm prompts
#   ./setup.sh --help

set -euo pipefail

REPO="$(cd "$(dirname "$0")" && pwd)"
export JIMDOTS_REPO="$REPO"

ONLY=""
export JIMDOTS_DRY_RUN=0
export JIMDOTS_ASSUME_YES=0

usage() {
    cat <<EOF
jimdots setup
Usage: $0 [--only phase[,phase...]] [--dry-run] [--yes] [--help]

Phases (in order):
  preflight packages symlinks system services post nvidia
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --only)    ONLY="$2"; shift 2;;
        --dry-run) JIMDOTS_DRY_RUN=1; shift;;
        --yes)     JIMDOTS_ASSUME_YES=1; shift;;
        -h|--help) usage; exit 0;;
        *) echo "unknown arg: $1" >&2; usage; exit 2;;
    esac
done

# shellcheck source=scripts/lib.sh
. "$REPO/scripts/lib.sh"

declare -a PHASES=(preflight packages symlinks system services post nvidia)
declare -A PHASE_SCRIPT=(
    [preflight]="00-preflight.sh"
    [packages]="10-packages.sh"
    [symlinks]="20-symlinks.sh"
    [system]="30-system.sh"
    [services]="40-services.sh"
    [post]="50-post.sh"
    [nvidia]="60-nvidia.sh"
)

should_run() {
    local name="$1"
    if [[ -z "$ONLY" ]]; then return 0; fi
    local IFS=,
    for p in $ONLY; do [[ "$p" == "$name" ]] && return 0; done
    return 1
}

info "jimdots setup — repo: $REPO"
dry && warn "DRY RUN — no changes will be made"

for phase in "${PHASES[@]}"; do
    if ! should_run "$phase"; then
        log "skipping phase: $phase (filtered by --only)"
        continue
    fi
    script="$REPO/scripts/${PHASE_SCRIPT[$phase]}"
    info "==== phase: $phase ($script) ===="
    if ! bash "$script"; then
        die "phase '$phase' failed — see $JIMDOTS_LOG"
    fi
done

ok "jimdots setup complete"
