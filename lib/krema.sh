#!/usr/bin/env bash
# Instalacao do Krema: Ubuntu 26.04 PPA ou Debian 13 OBS (repos oficiais do projeto).
install_krema() {
  if command -v krema >/dev/null 2>&1; then
    info "Krema ja instalado; instalacao ignorada."
    return 0
  fi
  require_kde_wayland_session
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
      # Use permissao 0644: install.sh opera com umask 077. "sudo tee"
      # criava krema-obs.list com 0600; o APT do usuario nao via o pacote.
      local source_file="/etc/apt/sources.list.d/krema-obs.list"
      local src_url="https://download.opensuse.org/repositories/home:/isac322/Debian_13/"
      local key_file="/usr/share/keyrings/krema-obs.gpg"
      if [[ -e "$source_file" || -L "$source_file" ]]; then
        [[ -f "$source_file" && ! -L "$source_file" ]] ||
          die "Fonte Krema OBS nao e arquivo regular: $source_file"
        sudo chmod 0644 "$source_file" ||
          die "Falha ao corrigir permissoes da fonte OBS Krema."
        grep -Fqx "deb [signed-by=$key_file] $src_url /" "$source_file" ||
          die "Conteudo inesperado em $source_file; corrija manualmente antes de prosseguir."
        [[ -s "$key_file" && -r "$key_file" ]] ||
          die "Chave OBS Krema ausente ou ilegivel: $key_file"
        info "Fonte OBS Krema existente; permissao verificada (0644)."
      elif sudo grep -RqsE 'home:/isac322/Debian_13|home:isac322/Debian_13' /etc/apt/sources.list.d/ 2>/dev/null; then
        info "Repositorio OBS Krema configurado por outra fonte APT."
      else
        apt_install_safe "Ferramentas para repositorio OBS" curl gnupg ca-certificates
        local tmpdir key_url
        tmpdir="$(mktemp -d)"
        key_url="https://download.opensuse.org/repositories/home:isac322/Debian_13/Release.key"
        curl --fail --show-error --location --retry 2 "$key_url" -o "$tmpdir/Release.key" ||
          { rm -rf -- "$tmpdir"; die "Falha ao baixar chave do OBS Krema."; }
        gpg --batch --yes --dearmor -o "$tmpdir/krema.gpg" "$tmpdir/Release.key" ||
          { rm -rf -- "$tmpdir"; die "Chave do Krema invalida."; }
        sudo install -m 0644 "$tmpdir/krema.gpg" "$key_file" ||
          { rm -rf -- "$tmpdir"; die "Falha ao instalar chave do OBS Krema."; }
        printf 'deb [signed-by=%s] %s /\n' "$key_file" "$src_url" > "$tmpdir/krema-obs.list"
        sudo install -m 0644 "$tmpdir/krema-obs.list" "$source_file" ||
          { rm -rf -- "$tmpdir"; die "Nao foi possivel configurar fonte Krema OBS."; }
        rm -rf -- "$tmpdir"
        info "Fonte OBS Krema criada com permissoes 0644."
      fi
      [[ -r "$source_file" || ! -e "$source_file" ]] ||
        die "Fonte OBS inacessivel para o usuario: $source_file"
      APT_UPDATED=0
      ;;
    *) die "Krema sem suporte para o backend $DISTRO_BACKEND." ;;
  esac

  apt_install_safe "Dock Krema" krema
  command -v krema >/dev/null 2>&1 ||
    die "Pacote Krema indisponivel ou nao instalado; painel KDE original preservado."
  info "Krema instalado."
}
