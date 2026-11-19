#!/usr/bin/env bash
# Reaplica fontes disponiveis e atalhos na sessao KDE atual; nao usa sudo.
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
[[ "$EUID" -ne 0 ]] || { echo "Execute sem sudo." >&2; exit 1; }
source "$ROOT/lib/core.sh"
source "$ROOT/lib/common-desktop.sh"
PROJECT_ROOT="$ROOT"
apt_install_safe() {
  local pkg missing=0
  shift
  for pkg in "$@"; do
    if ! dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null | grep -qx 'install ok installed'; then
      warn "$pkg ainda nao esta instalado pelo APT; execute o perfil de instalacao para instalar globalmente."
      missing=1
    fi
  done
  if [[ "$missing" == 1 ]]; then
    info "Fontes instaladas localmente tambem sao reconhecidas pelo fontconfig."
  fi
}
setup_common_desktop