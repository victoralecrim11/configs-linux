#!/usr/bin/env bash
# Registro local de instalacao. Nao equivale a um perfil visual KDE.
# O inventario confirma pacotes presentes; o registro confirma execucao bem-sucedida
# do instalador. Instalações anteriores sem registro nao sao inferidas.
install_status_root() {
  printf '%s\n' "${XDG_STATE_HOME:-$HOME/.local/state}/linux-hybrid-v2/perfis-instalacao"
}
install_status_packages() {
  # Componentes compartilhados pelos perfis dev-fullstack, premium e full.
  printf '%s\n' fonts-firacode fonts-jetbrains-mono fonts-inter \
    flatpak plasma-discover plasma-discover-backend-flatpak kde-config-flatpak
  case "$1" in
    premium)
      printf '%s\n' papirus-icon-theme fonts-firacode btop fastfetch librsvg2-bin curl ca-certificates krema
      ;;
    dev)
      printf '%s\n' build-essential git curl wget ca-certificates unzip jq \
        python3 python3-pip python3-venv pipx openjdk-21-jdk maven \
        php-cli php-mbstring php-xml php-curl composer
      ;;
    full)
      install_status_packages dev
      install_status_packages premium
      ;;
    *) return 2 ;;
  esac
}
install_status_extras() {
  # Os extras so sao necessarios se o usuario os solicitou.
  local flags="${1:-none}"
  [[ "$flags" == "none" || -z "$flags" ]] && return 0
  case ",$flags," in *,node,*) printf '%s\n' nodejs npm ;; esac
  case ",$flags," in *,docker,*) printf '%s\n' docker.io ;; esac
  case ",$flags," in *,dotnet,*) printf '%s\n' dotnet-sdk-10.0 ;; esac
  case ",$flags," in *,vscode,*) printf '%s\n' code ;; esac
}
install_status_requested_extras() {
  local extras=() item
  for item in node docker dotnet vscode; do
    local name="WITH_${item^^}"
    if [[ "${!name:-0}" == 1 ]]; then extras+=("$item"); fi
  done
  if (( ${#extras[@]} )); then
    local IFS=,
    printf '%s\n' "${extras[*]}"
  else printf '%s\n' none; fi
}
install_status_check() {
  local profile="$1" extras="${2:-none}" pkg
  local -A seen=()
  INSTALL_STATUS_TOTAL=0
  INSTALL_STATUS_PRESENT=0
  INSTALL_STATUS_MISSING=""
  while IFS= read -r pkg; do
    [[ -n "$pkg" && -z "${seen[$pkg]+x}" ]] || continue
    pkg="$(package_resolve "$pkg")"
    [[ -z "${seen[$pkg]+x}" ]] || continue
    seen["$pkg"]=1
    INSTALL_STATUS_TOTAL=$((INSTALL_STATUS_TOTAL+1))
    if has_package "$pkg"; then
      INSTALL_STATUS_PRESENT=$((INSTALL_STATUS_PRESENT+1))
    else
      if [[ -n "$INSTALL_STATUS_MISSING" ]]; then INSTALL_STATUS_MISSING+=","; fi
      INSTALL_STATUS_MISSING+="$pkg"
    fi
  done < <(
    install_status_packages "$profile"
    if [[ "$profile" != premium ]]; then install_status_extras "$extras"; fi
  )
  # Presenca do pacote sem executavel pode indicar instalacao danificada.
  if [[ "$profile" != dev ]] && ! command -v krema >/dev/null 2>&1; then
    if [[ ",$INSTALL_STATUS_MISSING," != *",krema,"* ]]; then
      INSTALL_STATUS_MISSING+=",krema-executavel"
    fi
  fi
  [[ -z "$INSTALL_STATUS_MISSING" ]]
}
install_status_read() {
  local path="$1" field="$2"
  [[ -f "$path" && ! -L "$path" ]] || return 0
  # Nunca execute ("source") os dados de estado.
  sed -n "s/^$field=//p" "$path" | head -1
}
install_status_write() {
  local profile="$1" state="$2" extras="${3:-none}" origin="${4:-instalador}" details="${5:-}"
  local root file temp
  case "$profile" in premium|dev|full) ;; *) return 2 ;; esac
  case "$state" in concluido|parcial|falhou) ;; *) return 2 ;; esac
  root="$(install_status_root)"
  mkdir -p -m 700 "$root" || return 1
  chmod 700 "$root" || return 1
  file="$root/$profile.state"
  temp="$(mktemp "$root/.status-$profile-XXXXXXXX")" || return 1
  {
    printf 'version=1\n'
    printf 'profile=%s\n' "$profile"
    printf 'status=%s\n' "$state"
    printf 'date=%s\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
    printf 'distro=%s\n' "${DISTRO_ID:-unknown}"
    printf 'distro_version=%s\n' "${DISTRO_VERSION:-unknown}"
    printf 'extras=%s\n' "$extras"
    printf 'origin=%s\n' "$origin"
    printf 'missing=%s\n' "$details"
  } > "$temp" || { rm -f "$temp"; return 1; }
  chmod 600 "$temp" || { rm -f "$temp"; return 1; }
  mv -f -- "$temp" "$file"
}
install_status_display() {
  local name display_name file saved origin extras missing result total present
  local root="$(install_status_root)"
  printf '%-15s %-16s %-14s %-16s %s\n' 'PERFIL' 'REGISTRO' 'PACOTES' 'ORIGEM' 'DETALHES'
  for name in premium dev full; do
    display_name="$name"
    [[ "$name" != dev ]] || display_name=dev-fullstack
    file="$root/$name.state"
    saved="$(install_status_read "$file" status)"
    origin="$(install_status_read "$file" origin)"
    extras="$(install_status_read "$file" extras)"
    [[ -n "$extras" ]] || extras=none
    if install_status_check "$name" "$extras"; then
      result="ok"
    else
      result="incompleto"
    fi
    present="$INSTALL_STATUS_PRESENT"
    total="$INSTALL_STATUS_TOTAL"
    missing="$INSTALL_STATUS_MISSING"
    if [[ -z "$saved" ]]; then
      saved="sem registro"
      origin="-"
    elif [[ "$saved" == concluido && "$result" != ok ]]; then
      saved="desatualizado"
    fi
    printf '%-15s %-16s %2s/%-10s %-16s %s\n' \
      "$display_name" "$saved" "$present" "$total" "${origin:--}" \
      "${missing:-pacotes verificados}"
  done
  printf '\nOs registros representam execucoes do instalador, nao perfis visuais.\n'
  printf 'Sem registro = nenhuma conclusao comprovada pelo rastreador (mesmo se pacotes existirem).\n'
}
install_status_verify() {
  local profile="$1" extras="${2:-none}" display_name="$1"
  [[ "$display_name" != dev ]] || display_name=dev-fullstack
  case "$profile" in premium|dev|full) ;; *) return 2 ;; esac
  if install_status_check "$profile" "$extras"; then
    printf '[OK] %s: %s/%s pacotes presentes; executaveis basicos verificados.\n' \
      "$display_name" "$INSTALL_STATUS_PRESENT" "$INSTALL_STATUS_TOTAL"
  else
    printf '[INCOMPLETO] %s: %s/%s pacotes presentes.\n' \
      "$display_name" "$INSTALL_STATUS_PRESENT" "$INSTALL_STATUS_TOTAL"
    printf 'Ausentes: %s\n' "$INSTALL_STATUS_MISSING"
    return 1
  fi
}