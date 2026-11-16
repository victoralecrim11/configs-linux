#!/usr/bin/env bash
# Instalacao do Krema: Ubuntu 26.04 PPA ou Debian 13 OBS (repos oficiais do projeto).
install_krema() {
  if command -v krema >/dev/null 2>&1; then
    info "Krema ja instalado; instalacao ignorada."
    return 0
  fi
  [[ "${XDG_SESSION_TYPE:-}" == "wayland" ]] ||
    die "O Krema requer sessao KDE Wayland. Entre com Wayland para o perfil Premium."
  confirm "Adicionar o repositorio de terceiros do Krema para $DISTRO_NAME?" ||
    die "Instalacao do Krema nao autorizada."

  case "$DISTRO_BACKEND" in
    ubuntu)
      apt_install_safe "Repositorio PPA" software-properties-common ca-certificates
      require_cmd add-apt-repository
      if ! grep -RqsE 'isac322/krema|isac322-ubuntu-krema' /etc/apt/sources.list.d/ 2>/dev/null; then
        sudo add-apt-repository -y ppa:isac322/krema ||
          die "Nao foi possivel adicionar o PPA oficial do projeto Krema."
      fi
      APT_UPDATED=0
      ;;
    debian)
      apt_install_safe "Ferramentas para repositorio OBS" curl gnupg ca-certificates
      local tmpdir key_url src_url
      tmpdir="$(mktemp -d)"
      key_url="https://download.opensuse.org/repositories/home:isac322/Debian_13/Release.key"
      src_url="https://download.opensuse.org/repositories/home:/isac322/Debian_13/"
      curl --fail --show-error --location --retry 2 "$key_url" -o "$tmpdir/Release.key" ||
        { rm -rf -- "$tmpdir"; die "Falha ao baixar chave do OBS Krema."; }
      gpg --batch --yes --dearmor -o "$tmpdir/krema.gpg" "$tmpdir/Release.key" ||
        { rm -rf -- "$tmpdir"; die "Chave do Krema invalida."; }
      sudo install -m 0644 "$tmpdir/krema.gpg" /usr/share/keyrings/krema-obs.gpg ||
        { rm -rf -- "$tmpdir"; die "Falha ao instalar chave do OBS Krema."; }
      printf 'deb [signed-by=/usr/share/keyrings/krema-obs.gpg] %s /\\n' "$src_url" |
        sudo tee /etc/apt/sources.list.d/krema-obs.list >/dev/null ||
        { rm -rf -- "$tmpdir"; die "Nao foi possivel configurar fonte Krema OBS."; }
      rm -rf -- "$tmpdir"
      APT_UPDATED=0
      ;;
    *) die "Krema sem suporte para o backend $DISTRO_BACKEND." ;;
  esac

  apt_install_safe "Dock Krema" krema
  command -v krema >/dev/null 2>&1 ||
    die "Pacote Krema indisponivel ou nao instalado; painel KDE original preservado."
  info "Krema instalado."
}
