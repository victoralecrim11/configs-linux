#!/usr/bin/env bash
# Funcoes comuns. YES e DRY_RUN sao definidas pelo instalador.
info() { printf '[INFO] %s\n' "$*"; }
warn() { printf '[AVISO] %s\n' "$*" >&2; }
die() { printf '[ERRO] %s\n' "$*" >&2; exit 1; }
require_cmd() { command -v "$1" >/dev/null 2>&1 || die "Comando obrigatorio nao encontrado: $1"; }
confirm() {
  local resposta=""
  if (( YES )); then info "Confirmado por --yes: $1"; return 0; fi
  [[ -t 0 ]] || die "Execucao sem terminal: use --dry-run ou confirme explicitamente com --yes."
  read -r -p "$1 [s/N] " resposta || return 1
  [[ "$resposta" =~ ^[sSyY]$ ]]
}
prepare_state() {
  STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/linux-hybrid-v2"
  mkdir -p -- "$STATE_DIR/backups" || die "Nao foi possivel criar $STATE_DIR"
  LOG_FILE="$STATE_DIR/install-$(date +%Y%m%d-%H%M%S)-$$.log"
  exec > >(tee -a "$LOG_FILE") 2>&1
  info "Log: $LOG_FILE"
}
backup_kde() {
  local backup="$STATE_DIR/backups/$(date +%Y%m%d-%H%M%S)-$$" f
  mkdir -p -- "$backup"
  for f in kdeglobals kwinrc plasmashellrc plasma-org.kde.plasma.desktop-appletsrc ksmserverrc kremarc; do
    [[ ! -f "${XDG_CONFIG_HOME:-$HOME/.config}/$f" ]] || cp -p -- "${XDG_CONFIG_HOME:-$HOME/.config}/$f" "$backup/$f"
  done
  info "Backup local KDE: $backup"
}
APT_UPDATED=0
apt_update() {
  if (( !APT_UPDATED )); then
    sudo apt-get update || die "Falha ao atualizar o indice do APT."
    APT_UPDATED=1
  fi
}
apt_install_safe() {
  local label="$1" pkg candidate simulation
  shift
  local to_install=()
  apt_update
  for pkg in "$@"; do
    if dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null | grep -q '^install ok installed$'; then
      info "Ja instalado: $pkg"
      continue
    fi
    candidate="$(LC_ALL=C apt-cache policy "$pkg" 2>/dev/null | awk '/Candidate:/{print $2;exit}')"
    if [[ -z "$candidate" || "$candidate" == "(none)" ]]; then
      warn "Pacote indisponivel no APT de $DISTRO_NAME: $pkg"
    else
      to_install+=("$pkg")
    fi
  done
  (("${#to_install[@]}")) || return 0
  simulation="$(LC_ALL=C apt-get --simulate install "${to_install[@]}" 2>&1)" ||
    die "Simulacao APT falhou ($label): $simulation"
  if grep -Eq '^Remv ' <<< "$simulation"; then
    printf '%s\n' "$simulation" >&2
    die "APT removeria pacotes existentes. Cancelando $label."
  fi
  info "$label: instalando ${to_install[*]}"
  sudo apt-get install -y "${to_install[@]}" || die "Falha na instalacao de $label"
}
has_package() { dpkg-query -W -f='${Status}' "$1" 2>/dev/null | grep -q '^install ok installed$'; }
