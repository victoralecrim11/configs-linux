#!/usr/bin/env bash
# Tema Premium: KDE + Krema, sem apagar widgets ou instalar kernel customizado.
apply_wallpaper() {
  local dir="$HOME/.local/share/wallpapers/Linux-Hybrid-V2" uri json js
  mkdir -p -- "$dir"
  cat > "$dir/hybrid.svg" <<'SVG'
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 2560 1440" width="2560" height="1440">
<defs>
<linearGradient id="bg" x2="1" y2="1"><stop stop-color="#090f1b"/><stop offset=".55" stop-color="#1a1530"/><stop offset="1" stop-color="#0a1220"/></linearGradient>
<radialGradient id="glow"><stop stop-color="#8855ea" stop-opacity=".50"/><stop offset="1" stop-color="#8855ea" stop-opacity="0"/></radialGradient>
</defs>
<rect width="2560" height="1440" fill="url(#bg)"/>
<ellipse cx="1680" cy="560" rx="1010" ry="860" fill="url(#glow)"/>
<path d="M-250 1300 C 500 700, 1150 1280, 1750 600 S 2600 150, 3000 440" stroke="#7a63dc" stroke-opacity=".18" stroke-width="175" fill="none"/>
</svg>
SVG
  if ! command -v rsvg-convert >/dev/null 2>&1; then
    warn "rsvg-convert ausente: wallpaper SVG salvo, mas nao convertido."
    return
  fi
  rsvg-convert -w 2560 -h 1440 -o "$dir/hybrid.png" "$dir/hybrid.svg" ||
    { warn "Falha ao converter wallpaper PNG."; return; }
  require_cmd python3
  uri="file://$dir/hybrid.png"
  json="$(python3 -c 'import json,sys;print(json.dumps(sys.argv[1]))' "$uri")"
  js="var ds=desktops(); for(var i=0;i<ds.length;i++){var d=ds[i];d.wallpaperPlugin='org.kde.image';d.currentConfigGroup=['Wallpaper','org.kde.image','General'];d.writeConfig('Image',$json);}"
  if command -v busctl >/dev/null 2>&1; then
    busctl --user call org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell evaluateScript s "$js" >/dev/null ||
      warn "Nao foi possivel aplicar o wallpaper automaticamente."
  fi
}

setup_premium() {
  local alternar="$PROJECT_ROOT/scripts/alternar-barra-kde.sh"
  local perfil="$PROJECT_ROOT/scripts/perfil-barra-atual-kde.sh"
  require_kde_wayland_session
  require_cmd plasmashell
  require_cmd kwriteconfig6
  [[ -s "${XDG_CONFIG_HOME:-$HOME/.config}/plasma-org.kde.plasma.desktop-appletsrc" ]] ||
    die "Faca login no KDE e aguarde a criacao do painel antes de instalar Premium."
  package_install_safe "Premium" papirus-icon-theme fonts-firacode btop fastfetch \
    python3 librsvg2-bin curl ca-certificates
  # Salva o painel original na primeira instalacao, sem sobrescrever backups previos.
  if [[ ! -f "${XDG_DATA_HOME:-$HOME/.local/share}/kubuntu-hybrid/perfis-alternancia/original/.snapshot" ]]; then
    bash "$alternar" salvar-original ||
      warn "KDE ja parece personalizado; mantenha um backup manual do painel anterior."
  fi
  install_krema
  if command -v plasma-apply-colorscheme >/dev/null 2>&1; then
    plasma-apply-colorscheme BreezeDark || warn "Nao foi possivel aplicar BreezeDark."
  fi
  if command -v plasma-apply-icons >/dev/null 2>&1; then
    plasma-apply-icons Papirus-Dark || warn "Nao foi possivel aplicar Papirus-Dark."
  else
    kwriteconfig6 --file kdeglobals --group Icons --key Theme Papirus-Dark
  fi
  kwriteconfig6 --file kdeglobals --group General --key AccentColor "139,92,246"
  kwriteconfig6 --file kdeglobals --group General --key AccentColorFromWallpaper false
  kwriteconfig6 --file kdeglobals --group KDE --key AnimationDurationFactor 0.75
  apply_wallpaper
  # Magic Lamp nativa: perfil Premium (e Full, que inclui Premium).
  # Um erro ou incompatibilidade nao deve interromper a instalacao.
  bash "$PROJECT_ROOT/scripts/efeito-lampada-magica.sh" --apply ||
    warn "Efeito Magic Lamp nao ativado; confira Configuracoes > Efeitos da area de trabalho."
  # Este script conserva o painel e aceita Debian quando Krema ja esta instalado.
  bash "$perfil" aplicar || die "Falha ao configurar painel ou dock."
  bash "$alternar" backup || warn "Nao foi possivel registrar o perfil personalizado."
  info "Premium instalado: painel superior, Krema e tema. Pode exigir logout/login."
}
