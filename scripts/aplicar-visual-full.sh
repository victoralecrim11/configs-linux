#!/usr/bin/env bash
# Reaplica somente o visual do perfil Full, sem reinstalar aplicativos.
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
[[ "$EUID" -ne 0 ]] || { echo "Execute sem sudo." >&2; exit 1; }
source "$ROOT/lib/core.sh"
source "$ROOT/lib/full-visual.sh"
setup_full_visual