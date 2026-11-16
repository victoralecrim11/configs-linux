#!/usr/bin/env bash
# Pacotes para desenvolvimento: catalogo APT comum; extras sao opt-in.
setup_dotnet10() {
  if dotnet --list-sdks 2>/dev/null | grep -q '^10\.'; then
    info ".NET SDK 10 ja disponivel."
    return 0
  fi
  if [[ "$DISTRO_BACKEND" == "debian" ]]; then
    confirm "Adicionar repositorio Microsoft para .NET 10 no Debian 13?" ||
      die "Repositorio Microsoft nao autorizado."
    apt_install_safe "Ferramentas de instalacao .NET" curl ca-certificates
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
  apt_install_safe ".NET SDK 10" dotnet-sdk-10.0
  dotnet --list-sdks 2>/dev/null | grep -q '^10\.' ||
    warn ".NET 10 nao foi instalado; confira repositorios e arquitetura."
}

setup_vscode() {
  if command -v code >/dev/null 2>&1; then
    info "VS Code ja disponivel."
    return 0
  fi
  confirm "Adicionar repositorio da Microsoft para VS Code?" ||
    die "Repositorio VS Code nao autorizado."
  apt_install_safe "Ferramentas de assinatura" curl gnupg ca-certificates
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
  apt_install_safe "Visual Studio Code" code
}

setup_docker() {
  if has_package podman-docker; then
    warn "podman-docker presente; nao instalarei Docker Engine para evitar conflitos."
    return
  fi
  apt_install_safe "Docker Engine distro" docker.io
  local compose=""
  for p in docker-compose-v2 docker-compose-plugin docker-compose; do
    if LC_ALL=C apt-cache policy "$p" 2>/dev/null | grep -Eq 'Candidate: (?!\(none\))'; then
      compose="$p"; break
    fi
  done
  # Alternativa portavel: Debian usa docker-compose-plugin ou docker-compose-v2
  if [[ -n "$compose" ]]; then
    apt_install_safe "Docker Compose" "$compose"
  else
    warn "Docker Compose nao identificado; instale separadamente de fonte confiavel."
  fi
  info "Docker sera mantido na configuracao padrao do sistema; confira permissao do usuario."
}

setup_developer() {
  info "Preparando ferramentas Developer no $DISTRO_NAME"
  apt_install_safe "Developer (APT)" \
    build-essential git curl wget ca-certificates unzip jq \
    python3 python3-pip python3-venv pipx \
    openjdk-21-jdk maven \
    php-cli php-mbstring php-xml php-curl composer

  (( WITH_NODE )) && apt_install_safe "Node.js (pacotes da distribuicao)" nodejs npm
  (( WITH_DOCKER )) && setup_docker
  (( WITH_DOTNET )) && setup_dotnet10
  (( WITH_VSCODE )) && setup_vscode
  info "Ambiente Developer concluido (pacotes indisponiveis foram reportados)."
}
