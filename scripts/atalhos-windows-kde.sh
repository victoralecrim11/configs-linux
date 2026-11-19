#!/usr/bin/env bash
# Mapeamento Windows -> Plasma 6. Backup e sem alterar atalhos padrao do usuario sem necessidade.
set -Eeuo pipefail
MODE="${1:---dry-run}"
case "$MODE" in --apply|--dry-run) ;; *) echo "Uso: $0 --dry-run|--apply" >&2; exit 2 ;; esac
[[ "$EUID" -ne 0 ]] || { echo "Execute como usuario comum." >&2; exit 1; }
CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}"
APPLICATIONS="${XDG_DATA_HOME:-$HOME/.local/share}/applications"
SHORTCUTS="$CONFIG/kglobalshortcutsrc"
BACKUPS="${XDG_STATE_HOME:-$HOME/.local/state}/linux-hybrid-v2/shortcuts"
# Nunca substituir combinações desconhecidas. Os atalhos nativos abaixo
# sao escritos apenas se a acao existir e nao tiver outra atribuicao.
native=(
  'kwin|Show Desktop|Meta+D'
  'kwin|Overview|Meta+Tab'
  'kwin|Window Quick Tile Left|Meta+Left'
  'kwin|Window Quick Tile Right|Meta+Right'
  'kwin|Walk Through Windows|Alt+Tab'
  'kwin|Window Close|Alt+F4'
  'ksmserver|Lock Session|Meta+L'
  'plasmashell|show-on-mouse-pos|Meta+V'
)
apps=(
  'dolphin|dolphin|Meta+E'
  'settings|systemsettings|Meta+I'
  'terminal|konsole|Ctrl+Alt+T'
  'monitor|plasma-systemmonitor|Ctrl+Shift+Esc'
  'runner|krunner|Meta+R'
  'screenshot|spectacle -r|Meta+Shift+S'
  'code|code|Ctrl+Alt+C'
)
if [[ "$MODE" == --dry-run ]]; then
  printf 'Atalhos Windows para KDE Plasma 6 (sem alteracoes):\n'
  printf '  %s\n' "${native[@]}" "${apps[@]}"
  exit 0
fi
[[ -f "$SHORTCUTS" && ! -L "$SHORTCUTS" ]] || { echo "Arquivo de atalhos KDE ausente ou link simbolico; abortando." >&2; exit 1; }
command -v kwriteconfig6 >/dev/null || { echo "kwriteconfig6 indisponivel." >&2; exit 1; }
mkdir -p -m 700 "$BACKUPS" "$APPLICATIONS"
cp -p "$SHORTCUTS" "$BACKUPS/kglobalshortcutsrc-$(date +%Y%m%d-%H%M%S)-$$.bak"
for entry in "${native[@]}"; do
  IFS='|' read -r group action desired <<< "$entry"
  current="$(kreadconfig6 --file kglobalshortcutsrc --group "$group" --key "$action" 2>/dev/null || true)"
  [[ -n "$current" ]] || { echo "Nao encontrado: $group/$action"; continue; }
  # Preservar configuracoes personalizadas, se ja estiverem atribuidas.
  current_shortcut="${current%%,*}"
  # Meta+W e o padrao KDE para Visao Geral. O preset Windows o move para Meta+Tab.
  if [[ "$group" == kwin && "$action" == Overview && "$current_shortcut" == "Meta+W" ]]; then
    current_shortcut=none
  fi
  if [[ "$current_shortcut" != 'none' && -n "$current_shortcut" && "$current_shortcut" != "$desired" ]]; then
    echo "Preservado (atalho personalizado): $group/$action -> $current_shortcut"
    continue
  fi
  if [[ "$current_shortcut" != "$desired" ]]; then
    kwriteconfig6 --file kglobalshortcutsrc --group "$group" --key "$action" "$desired,${current#*,}"
  fi
done
for entry in "${apps[@]}"; do
  IFS='|' read -r name command shortcut <<< "$entry"
  binary="${command%% *}"
  if ! command -v "$binary" >/dev/null 2>&1; then
    echo "Ignorado (aplicativo ausente): $binary"
    continue
  fi
  target="$APPLICATIONS/linux-hybrid-$name.desktop"
  if [[ -e "$target" && ! -f "$target" || -L "$target" ]]; then
    echo "Nao alterando caminho inseguro: $target" >&2
    continue
  fi
  if [[ -f "$target" ]] && ! grep -q '^X-Linux-Hybrid-Managed=true$' "$target"; then
    echo "Nao sobrescrever atalho nao gerenciado: $target"
    continue
  fi
  cat > "$target" <<DESKTOP
[Desktop Entry]
Type=Application
Name=Linux Hybrid - $name
Exec=$command
NoDisplay=true
Terminal=false
X-Linux-Hybrid-Managed=true
X-KDE-GlobalAccel-CommandShortcut=true
X-KDE-Shortcuts=$shortcut
DESKTOP
  # Registrar a configuracao de atalho no arquivo de preferencias do KDE.
  # O daemon pode exigir logout/login para importar o novo aplicativo.
  kwriteconfig6 --file kglobalshortcutsrc --group "linux-hybrid-$name.desktop" \
    --key _launch "$shortcut,none,Linux Hybrid - $name"
done
if command -v kbuildsycoca6 >/dev/null 2>&1; then kbuildsycoca6 --noincremental >/dev/null 2>&1 || true; fi
echo "Atalhos gravados no KDE (backup: $BACKUPS). Confira Configuracoes > Atalhos."
echo "No Plasma 6 Wayland, o registro em tempo real de lancadores nao e garantido; faca logout/login e teste."