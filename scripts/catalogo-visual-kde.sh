#!/usr/bin/env bash
# Catalogo portavel de receitas visuais; nao exporta snapshots pessoais.
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
MANAGER="$ROOT/scripts/perfis-kde.sh"
DEST="${XDG_DATA_HOME:-$HOME/.local/share}/linux-hybrid/profiles"
CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/linux-hybrid/visual-assets"
usage() {
  cat <<'HELP'
Catalogo de perfis visuais KDE 6
  bash scripts/catalogo-visual-kde.sh listar
  bash scripts/catalogo-visual-kde.sh instalar NOME [--dry-run]
  bash scripts/catalogo-visual-kde.sh instalar-todos [--dry-run]
Perfis: sweet-kde-videoyt, layan-minimalist-modern, catppuccin-mocha-videoyt, garuda-dr460nized, breeze-escuro-dock, breeze-classico
Instalar registra os perfis SEM APLICAR a aparencia. Perfis existentes sao preservados.
Para ativar: bash scripts/perfis-kde.sh aplicar NOME
O preset Sweet reproduz os componentes conhecidos, nao garante identidade pixel a pixel.
HELP
}
profiles=(sweet-kde-videoyt layan-minimalist-modern catppuccin-mocha-videoyt garuda-dr460nized breeze-escuro-dock breeze-classico)
description() {
  case "$1" in
    sweet-kde-videoyt) echo "Sweet escuro, Candy Icons, Sweet-Dark, blur e Krema inferior (referencia YouTube; wallpaper original nao incluso)" ;;
    layan-minimalist-modern) echo "Layan Dark, Kvantum, icones Tela, wallpaper Layan e dock Krema inferior (referencia visual)" ;;
    catppuccin-mocha-videoyt) echo "Catppuccin Mocha Mauve, painel superior, Krema inferior auto-oculta; wallpaper do video nao incluido" ;;
    garuda-dr460nized) echo "Sweet Dark, BeautyLine, wallpaper Maldrakor, blur, Magic Lamp e Krema inferior (inspirado no Garuda)" ;;
    breeze-escuro-dock) echo "Breeze Dark, icones Breeze, painel superior e Krema inferior" ;;
    breeze-classico) echo "Breeze padrao, painel inferior e dock desligada" ;;
    *) echo "Perfil desconhecido: $1" >&2; exit 2 ;;
  esac
}
asset_copy() {
  local repo="$1" branch="$2" target="$3" source="$CACHE/$1" url
  case "$repo" in
    Sweet-plasma6) url=https://github.com/EliverLara/Sweet.git ;;
    Sweet-kde) url=https://github.com/EliverLara/Sweet-kde.git ;;
    candy-icons) url=https://github.com/EliverLara/candy-icons.git ;;
    *) return 2 ;;
  esac
  if [[ ! -d "$source/.git" ]]; then
    mkdir -p "$CACHE"
    git clone --quiet --depth=1 ${branch:+--branch "$branch"} "$url" "$source"
  fi
  [[ -d "$source" ]] || return 1
  mkdir -p "$target"
  tar -C "$source" --exclude=.git -cf - . | tar -C "$target" -xf -
}
install_sweet() {
  local data="${XDG_DATA_HOME:-$HOME/.local/share}" k="$CACHE/Sweet-plasma6/kde"
  command -v git >/dev/null || { echo "git necessario para instalar Sweet" >&2; exit 1; }
  if [[ ! -d "$CACHE/Sweet-plasma6/.git" ]]; then
    mkdir -p "$CACHE"
    git clone --quiet --depth=1 --branch dark-plasma-6 https://github.com/EliverLara/Sweet.git "$CACHE/Sweet-plasma6"
  fi
  # Cache do clone e usado como fonte para copiar apenas os subdiretorios pertinentes.
  mkdir -p "$data/plasma/desktoptheme/Sweet" "$data/plasma/look-and-feel/Sweet" \
    "$data/color-schemes" "$data/aurorae/themes" "$data/icons"
  asset_copy Sweet-kde "" "$data/plasma/desktoptheme/Sweet"
  cp -a "$k/look-and-feel/." "$data/plasma/look-and-feel/Sweet/"
  cp -n "$k/colorschemes/Sweet.colors" "$data/color-schemes/Sweet.colors"
  cp -a -n "$k/aurorae/Sweet-Dark" "$data/aurorae/themes/"
  cp -a -n "$k/cursors/Sweet-cursors" "$data/icons/"
  asset_copy candy-icons "" "$data/icons/candy-icons"
}
install_layan() {
  local source="$CACHE/Layan-kde"
  command -v git >/dev/null || { echo "git necessario para instalar Layan" >&2; exit 1; }
  if [[ ! -d "$source/.git" ]]; then
    mkdir -p "$CACHE"
    git clone --quiet --depth=1 https://github.com/vinceliuice/Layan-kde.git "$source"
  fi
  # Instalador upstream executado como usuario normal (sem sudo).
  (cd "$source" && bash ./install.sh)
}

# Instala apenas arquivos de tema no XDG_DATA_HOME. Nao executa o instalador
# upstream (que aplicaria o tema ao Plasma antes de registrar o preset).
install_catppuccin() {
  local data="${XDG_DATA_HOME:-$HOME/.local/share}"
  local source="$CACHE/catppuccin-kde"
  local theme="Catppuccin-Mocha-Mauve"
  command -v git >/dev/null || { echo "git necessario para instalar Catppuccin" >&2; exit 1; }
  if [[ ! -d "$source/.git" ]]; then
    mkdir -p "$CACHE"
    git clone --quiet --depth=1 https://github.com/catppuccin/kde.git "$source"
  fi
  local colors="$source/generated/color-schemes/CatppuccinMochaMauve.colors"
  local defaults="$source/generated/look-and-feel/Classic/$theme/contents/defaults"
  local metadata="$source/generated/look-and-feel/Classic/$theme"
  local base="$source/Resources/LookAndFeel/Catppuccin-Mocha-Global"
  local aurorae="$source/Resources/Aurorae/CatppuccinMocha-Classic"
  [[ -f "$colors" && -f "$defaults" && -f "$metadata/metadata.json" &&
     -d "$base" && -d "$aurorae" ]] || {
    echo "Estrutura Catppuccin upstream mudou; nada sera aplicado. Revise o preset." >&2
    return 1
  }
  mkdir -p "$data/color-schemes" "$data/aurorae/themes" "$data/plasma/look-and-feel"
  cp -n "$colors" "$data/color-schemes/"
  if [[ ! -d "$data/aurorae/themes/CatppuccinMocha-Classic" ]]; then
    cp -a "$aurorae" "$data/aurorae/themes/"
    cp -n "$source/Resources/Aurorae/Common/Catppuccin-Classicrc" \
      "$data/aurorae/themes/CatppuccinMocha-Classic/CatppuccinMocha-Classicrc"
  fi
  if [[ ! -d "$data/plasma/look-and-feel/$theme" ]]; then
    cp -a "$base" "$data/plasma/look-and-feel/$theme"
    cp -a "$metadata/metadata.json" "$metadata/metadata.desktop" \
      "$data/plasma/look-and-feel/$theme/"
    cp -a "$defaults" "$data/plasma/look-and-feel/$theme/contents/defaults"
  fi
}
install_garuda() {
  local data="${XDG_DATA_HOME:-$HOME/.local/share}"
  local source="$CACHE/beautyline" icon_index wallpaper="$CACHE/Maldrakor.jpg"
  install_sweet
  mkdir -p "$CACHE" "$data/icons" "$data/wallpapers/garuda-wallpapers"
  if [[ ! -d "$source/.git" ]]; then
    git clone --quiet --depth=1 https://gitlab.com/garuda-linux/themes-and-settings/artwork/beautyline.git "$source"
  fi
  icon_index="$(find "$source" -name index.theme -type f -print -quit)"
  [[ -n "$icon_index" ]] || { echo "BeautyLine: index.theme nao encontrado" >&2; return 1; }
  if [[ ! -f "$data/icons/BeautyLine/index.theme" ]]; then
    mkdir -p "$data/icons/BeautyLine"
    tar -C "$(dirname "$icon_index")" --exclude=.git -cf - . | tar -C "$data/icons/BeautyLine" -xf -
  fi
  if [[ ! -s "$data/wallpapers/garuda-wallpapers/Maldrakor.jpg" ]]; then
    command -v curl >/dev/null || { echo "curl necessario para wallpaper" >&2; return 1; }
    curl --fail --location --silent --show-error --output "$wallpaper.tmp" \
      https://gitlab.com/garuda-linux/themes-and-settings/artwork/garuda-wallpapers/-/raw/master/src/garuda-wallpapers/Maldrakor.jpg
    mv -- "$wallpaper.tmp" "$wallpaper"
    cp -- "$wallpaper" "$data/wallpapers/garuda-wallpapers/Maldrakor.jpg"
  fi
}
set_key() { kwriteconfig6 --file "$1" --group "$2" --key "$3" "$4"; }
register_one() {
  local name="$1" dry="$2" p config dock colors icons look decoration
  description "$name" >/dev/null
  p="$DEST/$name"
  if [[ -f "$p/.snapshot" ]]; then
    printf '[EXISTE] %s (preservado, nao sobrescrito)\n' "$name"
    return 0
  fi
  case "$name" in
    sweet-kde-videoyt) dock=on; colors=Sweet; icons=candy-icons; look=Sweet; decoration=__aurorae__svg__Sweet-Dark ;;
    layan-minimalist-modern) dock=on; colors=Layan; icons=Tela-dark; look=com.github.vinceliuice.Layan; decoration=__aurorae__svg__Layan ;;
    catppuccin-mocha-videoyt) dock=on; colors=CatppuccinMochaMauve; icons=breeze; look=Catppuccin-Mocha-Mauve; decoration=__aurorae__svg__CatppuccinMocha-Classic ;;
    garuda-dr460nized) dock=on; colors=Sweet; icons=BeautyLine; look=Sweet; decoration=__aurorae__svg__Sweet-Dark ;;
    breeze-escuro-dock) dock=on; colors=BreezeDark; icons=breeze; look=org.kde.breezedark.desktop; decoration= ;;
    breeze-classico) dock=off; colors=BreezeLight; icons=breeze; look=org.kde.breeze.desktop; decoration= ;;
  esac
  printf '[PLANO] %s (dock=%s): %s\n' "$name" "$dock" "$(description "$name")"
  [[ "$dry" == 0 ]] || return 0
  [[ "$EUID" -ne 0 ]] || { echo "Nao execute com sudo." >&2; exit 1; }
  [[ "${XDG_CURRENT_DESKTOP:-}" == *KDE* || "${XDG_CURRENT_DESKTOP:-}" == *Plasma* ]] || {
    echo "Registre os perfis dentro da sessao KDE." >&2; exit 1;
  }
  command -v kwriteconfig6 >/dev/null || { echo "kwriteconfig6 ausente" >&2; exit 1; }
  if [[ "$name" == sweet-kde-videoyt ]]; then install_sweet; fi
  if [[ "$name" == garuda-dr460nized ]]; then install_garuda; fi
  if [[ "$name" == layan-minimalist-modern ]]; then install_layan; fi
  if [[ "$name" == catppuccin-mocha-videoyt ]]; then install_catppuccin; fi
  # O gerenciador marca uma captura como ativa; registrar um preset nao deve
  # mudar o indicador do perfil que o usuario realmente esta utilizando.
  local active="$DEST/.ativo" old_active="" had_active=0
  if [[ -f "$active" ]]; then old_active="$(cat "$active")"; had_active=1; fi
  bash "$MANAGER" criar "$name" --dock "$dock"
  if [[ "$had_active" == 1 ]]; then
    printf '%s\n' "$old_active" > "$active"
  else
    rm -f -- "$active"
  fi
  config="$p/config"
  mkdir -p "$config"
  [[ -f "$config/kdeglobals" ]] || : > "$config/kdeglobals"
  [[ -f "$config/kwinrc" ]] || : > "$config/kwinrc"
  set_key "$config/kdeglobals" KDE LookAndFeelPackage "$look"
  set_key "$config/kdeglobals" Icons Theme "$icons"
  set_key "$config/kdeglobals" General ColorScheme "$colors"
  if [[ -n "$decoration" ]]; then
    set_key "$config/kwinrc" org.kde.kdecoration2 library org.kde.kwin.aurorae
    set_key "$config/kwinrc" org.kde.kdecoration2 theme "$decoration"
    for effect in blurEnabled contrastEnabled magiclampEnabled; do
      kwriteconfig6 --file "$config/kwinrc" --group Plugins --key "$effect" --type bool true
    done
  fi
  if [[ "$name" == layan-minimalist-modern ]]; then
    wallpaper="${XDG_DATA_HOME:-$HOME/.local/share}/wallpapers/Layan/contents/images/2560x1440.png"
    if [[ -f "$wallpaper" && -f "$config/plasma-org.kde.plasma.desktop-appletsrc" ]]; then
      sed -i "s|^Image=.*|Image=$wallpaper|; s|^PreviewImage=.*|PreviewImage=$wallpaper|" "$config/plasma-org.kde.plasma.desktop-appletsrc"
    fi
    # Efeitos discretos; wallpaper do tema instalado no diretorio local.
    kwriteconfig6 --file "$config/kwinrc" --group Plugins --key blurEnabled --type bool true
    kwriteconfig6 --file "$config/kwinrc" --group Plugins --key contrastEnabled --type bool true
  fi
  if [[ "$name" == garuda-dr460nized ]]; then
    local wallpaper="${XDG_DATA_HOME:-$HOME/.local/share}/wallpapers/garuda-wallpapers/Maldrakor.jpg"
    if [[ -f "$wallpaper" && -f "$config/plasma-org.kde.plasma.desktop-appletsrc" ]]; then
      sed -i "s|^Image=.*|Image=$wallpaper|; s|^PreviewImage=.*|PreviewImage=$wallpaper|" "$config/plasma-org.kde.plasma.desktop-appletsrc"
    fi
    kwriteconfig6 --file "$config/kwinrc" --group Plugins --key squashEnabled --type bool false
  fi
  if [[ "$name" == catppuccin-mocha-videoyt ]]; then
    # Top panel + Krema autohide are applied by the existing profile manager.
    # Preserve the current wallpaper: the video image has not been sourced.
    kwriteconfig6 --file "$config/kwinrc" --group Plugins --key blurEnabled --type bool true
    kwriteconfig6 --file "$config/kwinrc" --group Plugins --key contrastEnabled --type bool true
  fi
  if [[ "$name" == breeze-classico || "$name" == breeze-escuro-dock ]]; then
    # Nao herdar decoracao Sweet ao registrar perfis Breeze.
    set_key "$config/kwinrc" org.kde.kdecoration2 library org.kde.breeze
    set_key "$config/kwinrc" org.kde.kdecoration2 theme Breeze
  fi
  printf 'catalog_recipe=%s\n' "$name" >> "$p/info"
  printf '[CRIADO] %s (nao aplicado)\n' "$name"
}
case "${1:---help}" in
  -h|--help) usage ;;
  listar-nomes)
    printf '%s\n' "${profiles[@]}" ;;
  listar)
    for name in "${profiles[@]}"; do
      printf '%-24s %s%s\n' "$name" "$(description "$name")" "$([[ -f "$DEST/$name/.snapshot" ]] && echo ' [SALVO]' || true)"
    done ;;
  instalar|instalar-todos)
    action="$1"; name="${2:-}"; dry=0
    if [[ "$action" == instalar ]]; then
      [[ -n "$name" ]] || { usage; exit 2; }
      [[ "${3:-}" == "" || "${3:-}" == --dry-run ]] || { usage; exit 2; }
      [[ "${3:-}" != --dry-run ]] || dry=1
      register_one "$name" "$dry"
    else
      [[ "$name" == "" || "$name" == --dry-run ]] || { usage; exit 2; }
      [[ "$name" != --dry-run ]] || dry=1
      for name in "${profiles[@]}"; do register_one "$name" "$dry"; done
    fi ;;
  *) usage; exit 2 ;;
esac
