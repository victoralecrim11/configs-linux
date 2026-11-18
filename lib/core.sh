#!/usr/bin/env bash
# Funcoes comuns. YES e DRY_RUN sao definidas pelo instalador.
info() { printf '[INFO] %s\n' "$*"; }
warn() { printf '[AVISO] %s\n' "$*" >&2; }
die() { printf '[ERRO] %s\n' "$*" >&2; exit 1; }
require_cmd() { command -v "$1" >/dev/null 2>&1 || die "Comando obrigatorio nao encontrado: $1"; }

# Verifica a sessao grafica deste processo, nao se ha um desktop aberto em paralelo.
# "su - usuario" pode perder o contexto grafico do SDDM.
wayland_socket_ok() {
  local display="${WAYLAND_DISPLAY:-}" runtime="${XDG_RUNTIME_DIR:-}" socket
  [[ -n "$display" ]] || return 1
  if [[ "$display" == /* ]]; then
    socket="$display"
  else
    [[ -n "$runtime" ]] || return 1
    socket="$runtime/$display"
  fi
  [[ -S "$socket" ]]
}
kde_wayland_session_ok() {
  [[ "${XDG_SESSION_TYPE:-}" == wayland ]] || return 1
  case "${XDG_CURRENT_DESKTOP:-}" in
    *KDE*|*Plasma*) ;;
    *) return 1 ;;
  esac
  wayland_socket_ok
}
print_graphical_diagnostics() {
  local group_list="" loginctl_details=""
  group_list="$(id -nG 2>/dev/null || true)"
  info "Usuario efetivo: $(id -un) (UID=$(id -u))"
  info "Grupos da sessao: $group_list"
  info "XDG_SESSION_TYPE=${XDG_SESSION_TYPE:-<ausente>}"
  info "XDG_CURRENT_DESKTOP=${XDG_CURRENT_DESKTOP:-<ausente>}"
  info "WAYLAND_DISPLAY=${WAYLAND_DISPLAY:-<ausente>}"
  info "XDG_RUNTIME_DIR=${XDG_RUNTIME_DIR:-<ausente>}"
  if wayland_socket_ok; then
    info "Socket Wayland: acessivel neste shell"
  else
    warn "Socket Wayland: ausente ou inacessivel neste shell"
  fi
  if command -v loginctl >/dev/null 2>&1; then
    loginctl_details="$(loginctl show-session self -p Type -p Desktop 2>/dev/null | tr '\n' ' ' || true)"
    [[ -z "$loginctl_details" ]] ||
      info "Sessao logind deste processo: $loginctl_details"
  fi
}
require_kde_wayland_session() {
  kde_wayland_session_ok && return 0
  print_graphical_diagnostics
  die "Terminal sem acesso valido a sessao KDE Plasma Wayland. Feche Konsole, abra-o novamente pelo menu do KDE apos entrar no SDDM e execute como usuario normal. Nao use 'su -', 'sudo su' nem 'sudo bash install.sh'. Use 'bash install.sh --check-session' para diagnosticar sem instalar."
}
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
  if grep -Eq '^(Remv|Purg) ' <<< "$simulation"; then
    printf '%s\n' "$simulation" >&2
    die "APT removeria pacotes existentes. Cancelando $label."
  fi
  info "$label: instalando ${to_install[*]}"
  sudo apt-get install -y "${to_install[@]}" || die "Falha na instalacao de $label"
}
has_package() { dpkg-query -W -f='${Status}' "$1" 2>/dev/null | grep -q '^install ok installed$'; }
