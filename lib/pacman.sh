#!/usr/bin/env bash
# Backend CachyOS (Pacman). Somente repositorios configurados pelo sistema.
# AUR nao entra aqui: requer consentimento explicito e helper separado.
ARCH_SYNC_DONE=0

package_resolve() {
  local name="$1"
  if [[ "${DISTRO_BACKEND:-}" != cachyos ]]; then
    printf '%s\n' "$name"
    return
  fi
  case "$name" in
    build-essential) name=base-devel ;;
    python3|python3-venv) name=python ;;
    python3-pip) name=python-pip ;;
    pipx) name=python-pipx ;;
    openjdk-21-jdk) name=jdk21-openjdk ;;
    php-cli|php-mbstring|php-xml|php-curl) name=php ;;
    fonts-firacode) name=ttf-fira-code ;;
    fonts-jetbrains-mono) name=ttf-jetbrains-mono ;;
    fonts-inter) name=inter-font ;;
    plasma-discover|plasma-discover-backend-flatpak) name=discover ;;
    kde-config-flatpak) name=flatpak-kcm ;;
    librsvg2-bin) name=librsvg ;;
    docker.io) name=docker ;;
    docker-compose-v2|docker-compose-plugin) name=docker-compose ;;
    code) name=visual-studio-code-bin ;;
  esac
  printf '%s\n' "$name"
}

pacman_install_safe() {
  local label="$1" raw pkg
  shift
  local -a wanted=() absent=()
  local -A seen=()
  for raw in "$@"; do
    pkg="$(package_resolve "$raw")"
    [[ -z "${seen[$pkg]+x}" ]] || continue
    seen[$pkg]=1
    if pacman -Q "$pkg" >/dev/null 2>&1; then
      info "Ja instalado: $pkg"
      continue
    fi
    wanted+=("$pkg")
  done
  (("${#wanted[@]}")) || return 0
  # Falha antes de qualquer modificacao se o catalogo atual nao reconhecer
  # alguma dependencia obrigatoria. Nao tentar instalar AUR via Pacman.
  for pkg in "${wanted[@]}"; do
    if ! pacman -Si "$pkg" >/dev/null 2>&1; then
      absent+=("$pkg")
    fi
  done
  if (("${#absent[@]}")); then
    die "Pacotes sem candidato nos repositorios Pacman: ${absent[*]}. Atualize mirrors/sistema e revise o catalogo."
  fi
  info "$label: pacotes ${wanted[*]}"
  if (( !ARCH_SYNC_DONE )); then
    info "Primeira transacao: upgrade COMPLETO (pacman -Syu); revise conflitos antes de confirmar."
    sudo pacman -Syu --needed "${wanted[@]}" ||
      die "Transacao Pacman abortada ou falhou ($label)."
    ARCH_SYNC_DONE=1
  else
    sudo pacman -S --needed "${wanted[@]}" ||
      die "Falha ao instalar pacotes Pacman ($label)."
  fi
}

package_install_safe() {
  case "${DISTRO_BACKEND:-}" in
    ubuntu|debian) apt_install_safe "$@" ;;
    cachyos) pacman_install_safe "$@" ;;
    *) die "Backend sem instalador: ${DISTRO_BACKEND:-desconhecido}" ;;
  esac
}

aur_install_confirmed() {
  local pkg="$1" helper=""
  if command -v paru >/dev/null 2>&1; then
    helper=paru
  elif command -v yay >/dev/null 2>&1; then
    helper=yay
  else
    confirm "O CachyOS nao possui paru/yay instalado. Instalar paru pelo repositorio oficial antes de acessar o AUR?" ||
      die "Sem helper AUR; etapa '$pkg' cancelada."
    package_install_safe "Helper AUR (repositorio CachyOS)" paru
    command -v paru >/dev/null 2>&1 ||
      die "Paru nao encontrado apos instalacao pelo Pacman."
    helper=paru
  fi
  confirm "Instalar '$pkg' pelo AUR com $helper? Confira o PKGBUILD e as perguntas do helper." ||
    die "Instalacao AUR nao autorizada."
  "$helper" -S --needed "$pkg" ||
    die "Falha ou cancelamento da instalacao AUR ($pkg)."
}
