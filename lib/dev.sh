#!/usr/bin/env bash
# Pacotes para desenvolvimento: catalogo APT comum; extras sao opt-in.
setup_dotnet10() {
  if dotnet --list-sdks 2>/dev/null | grep -q '^10\.'; then
    info ".NET SDK 10 ja disponivel."
    return 0
  fi
  if [[ "$DISTRO_BACKEND" == "cachyos" ]]; then
    package_install_safe ".NET SDK 10" dotnet-sdk-10.0
    dotnet --list-sdks 2>/dev/null | grep -q '^10\\.' ||
      die ".NET SDK 10 nao foi encontrado apos instalar."
    return 0
  fi
  if [[ "$DISTRO_BACKEND" == "debian" ]]; then
    confirm "Adicionar repositorio Microsoft para .NET 10 no Debian 13?" ||
      die "Repositorio Microsoft nao autorizado."
    package_install_safe "Ferramentas de instalacao .NET" curl ca-certificates
    local tmp pkg
    tmp="$(mktemp --suffix=.deb)"
    curl --fail --show-error --location --retry 2 \
      https://packages.microsoft.com/config/debian/13/packages-microsoft-prod.deb -o "$tmp" ||
      { rm -f -- "$tmp"; die "Falha ao baixar pacote oficial Microsoft."; }
    pkg="$(dpkg-deb --field "$tmp" Package 2>/dev/null || true)"
    [[ "$pkg" == "packages-microsoft-prod" ]] ||
      { rm -f -- "$tmp"; die "Pacote Microsoft baixado nao foi reconhecido."; }
    sudo dpkg -i "$tmp" || { rm -f -- "$tmp"; die "Falha ao configurar feed Microsoft."; }
    rm -f -- "$tmp"
    APT_UPDATED=0
  fi
  package_install_safe ".NET SDK 10" dotnet-sdk-10.0
  dotnet --list-sdks 2>/dev/null | grep -q '^10\.' ||
    warn ".NET 10 nao foi instalado; confira repositorios e arquitetura."
}

setup_vscode() {
  if [[ "$DISTRO_BACKEND" == cachyos ]]; then
    if has_package visual-studio-code-bin; then
      info "VS Code Microsoft ja instalado via AUR."
      return 0
    fi
    aur_install_confirmed visual-studio-code-bin
    has_package visual-studio-code-bin ||
      die "Pacote VS Code Microsoft nao encontrado apos AUR."
    return 0
  fi
  if command -v code >/dev/null 2>&1; then
    info "VS Code ja disponivel."
    return 0
  fi
  confirm "Adicionar repositorio da Microsoft para VS Code?" ||
    die "Repositorio VS Code nao autorizado."
  package_install_safe "Ferramentas de assinatura" curl gnupg ca-certificates
  if ! grep -Rqs 'packages.microsoft.com/repos/code' /etc/apt/sources.list.d/ /etc/apt/sources.list 2>/dev/null; then
    local temp arch
    temp="$(mktemp)"
    curl --fail --show-error --location --retry 2 \
      https://packages.microsoft.com/keys/microsoft.asc |
      gpg --batch --yes --dearmor -o "$temp" ||
      { rm -f -- "$temp"; die "Falha ao obter chave de assinatura do VS Code."; }
    sudo install -m 0644 "$temp" /usr/share/keyrings/vscode-microsoft.gpg ||
      { rm -f -- "$temp"; die "Nao foi possivel instalar chave VS Code."; }
    rm -f -- "$temp"
    arch="$(dpkg --print-architecture)"
    printf 'Types: deb\nURIs: https://packages.microsoft.com/repos/code\nSuites: stable\nComponents: main\nArchitectures: %s\nSigned-By: /usr/share/keyrings/vscode-microsoft.gpg\n' "$arch" |
      sudo tee /etc/apt/sources.list.d/vscode-hybrid.sources >/dev/null ||
      die "Falha ao adicionar repositorio VS Code."
    APT_UPDATED=0
  fi
  package_install_safe "Visual Studio Code" code
}

setup_docker() {
  if has_package podman-docker; then
    warn "podman-docker presente; nao instalarei Docker Engine para evitar conflitos."
    return
  fi
  package_install_safe "Docker Engine distro" docker.io
  if [[ "$DISTRO_BACKEND" == cachyos ]]; then
    package_install_safe "Docker Compose" docker-compose
    info "Docker: serviço nao ativado automaticamente; execute sudo systemctl enable --now docker se desejar."
    return 0
  fi
  local compose="" candidate p
  for p in docker-compose-v2 docker-compose-plugin docker-compose; do
    candidate="$(LC_ALL=C apt-cache policy "$p" 2>/dev/null | awk '/Candidate:/{print $2;exit}')"
    if [[ -n "$candidate" && "$candidate" != "(none)" ]]; then
      compose="$p"; break
    fi
  done
  # Alternativa portavel: Debian usa docker-compose-plugin ou docker-compose-v2
  if [[ -n "$compose" ]]; then
    package_install_safe "Docker Compose" "$compose"
  else
    warn "Docker Compose nao identificado; instale separadamente de fonte confiavel."
  fi
  info "Docker sera mantido na configuracao padrao do sistema; confira permissao do usuario."
}

# NVM oficial, instalado no HOME do usuario (sem sudo).
setup_nvm() (
  set +u
  export NVM_DIR="${NVM_DIR:-${XDG_CONFIG_HOME:+$XDG_CONFIG_HOME/nvm}}"
  export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
  if [[ ! -s "$NVM_DIR/nvm.sh" ]]; then
    confirm "Instalar NVM oficial (v0.40.3) no diretorio do usuario?" ||
      die "Instalacao NVM cancelada."
    local tmp
    tmp="$(mktemp)"
    curl --fail --show-error --location --retry 2 \
      https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh -o "$tmp" ||
      { rm -f -- "$tmp"; die "Falha ao baixar NVM."; }
    PROFILE=/dev/null bash "$tmp" ||
      { rm -f -- "$tmp"; die "Falha ao instalar NVM."; }
    rm -f -- "$tmp"
  fi
  source "$NVM_DIR/nvm.sh" --no-use
  nvm install --lts || die "Falha ao instalar Node.js LTS."
  if [[ "$(nvm version default)" == N/A ]]; then
    nvm alias default 'lts/*' || die "Falha ao configurar Node padrao."
  fi
  nvm use default || die "Falha ao ativar Node padrao."
  node --version && npm --version || die "Node/npm indisponiveis."
  local rc
  for rc in "$HOME/.bashrc" "${ZDOTDIR:-$HOME}/.zshrc"; do
    if ! grep -Fqs 'nvm.sh' "$rc"; then
      printf '\n# NVM (linux-hybrid)\nexport NVM_DIR=%q\n[ ! -s "$NVM_DIR/nvm.sh" ] || . "$NVM_DIR/nvm.sh"\n' "$NVM_DIR" >> "$rc"
    fi
  done
  if [[ "${SHELL##*/}" == fish ]]; then
    warn "Fish nao suporta NVM nativamente. Use bash para executar nvm, node e npm."
  fi
)

setup_developer() {
  info "Preparando ferramentas Developer no $DISTRO_NAME"
  package_install_safe "Developer" \
    build-essential git curl wget ca-certificates unzip jq \
    python3 python3-pip python3-venv pipx \
    openjdk-21-jdk maven \
    php-cli php-mbstring php-xml php-curl composer

  setup_nvm || die "Falha na configuracao NVM."
  (( WITH_NODE )) && package_install_safe "Node.js (pacotes da distribuicao)" nodejs npm
  (( WITH_DOCKER )) && setup_docker
  (( WITH_DOTNET )) && setup_dotnet10
  (( WITH_VSCODE )) && setup_vscode
  info "Ambiente Developer concluido (pacotes indisponiveis foram reportados)."
}
