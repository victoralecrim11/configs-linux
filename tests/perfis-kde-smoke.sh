#!/usr/bin/env bash
# Teste isolado do gerenciador KDE: sem sudo, sem tocar no Plasma real.
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT="$ROOT/scripts/perfis-kde.sh"
bash -n "$SCRIPT"
[[ "$EUID" -ne 0 ]] || { echo "Execute os testes como usuario nao-root." >&2; exit 1; }
TMP="$(mktemp -d)"
trap 'rm -rf -- "$TMP"' EXIT
export HOME="$TMP/home"
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_CURRENT_DESKTOP=KDE
export XDG_SESSION_TYPE=wayland
export PATH="$TMP/mock:$PATH"
mkdir -p -- "$XDG_CONFIG_HOME" "$XDG_DATA_HOME" "$TMP/mock"
cat > "$TMP/mock/systemctl" <<'MOCK'
#!/usr/bin/env bash
case "$*" in
  *"is-active"*) exit 0 ;;
  *"stop"*) exit 0 ;;
  *"start"*)
    if [[ -n "${FAIL_FIRST_START:-}" && ! -f "$FAIL_FIRST_START" ]]; then
      touch "$FAIL_FIRST_START"
      exit 1
    fi
    exit 0 ;;
esac
MOCK
printf '#!/bin/sh\nexit 1\n' > "$TMP/mock/pgrep"
printf '#!/bin/sh\nexit 0\n' > "$TMP/mock/pkill"
chmod +x "$TMP/mock/"*

CONFIG="$XDG_CONFIG_HOME"
STATE="$XDG_DATA_HOME/linux-hybrid/profiles"
printf 'layout=original\n' > "$CONFIG/plasma-org.kde.plasma.desktop-appletsrc"
printf 'theme=Breeze\n' > "$CONFIG/kdeglobals"
bash "$SCRIPT" salvar original --dock off >/dev/null
[[ -f "$STATE/original/.snapshot" ]] || exit 1
if bash "$SCRIPT" salvar original > /dev/null 2>&1; then
  echo "ERRO: substituiu perfil sem --atualizar" >&2; exit 1
fi
if bash "$SCRIPT" salvar ../escape > /dev/null 2>&1; then
  echo "ERRO: aceitou nome com path traversal" >&2; exit 1
fi

printf 'layout=sweet\n' > "$CONFIG/plasma-org.kde.plasma.desktop-appletsrc"
printf 'theme=Sweet\n' > "$CONFIG/kdeglobals"
printf 'someKWinEffect=true\n' > "$CONFIG/kwinrc"
mkdir -p "$XDG_DATA_HOME/color-schemes"
printf 'Sweet Accent\n' > "$XDG_DATA_HOME/color-schemes/sweet.colors"
bash "$SCRIPT" salvar sweet --recursos --dock keep >/dev/null
[[ -f "$STATE/sweet/resources/color-schemes/sweet.colors" ]] || exit 1
bash "$SCRIPT" detalhes sweet | grep -q 'dock=keep'
bash "$SCRIPT" listar | grep -q sweet
printf 'layout=manualmente-alterado\n' > "$CONFIG/plasma-org.kde.plasma.desktop-appletsrc"
bash "$SCRIPT" aplicar original --dry-run | grep -q SIMULACAO
grep -q manualmente-alterado "$CONFIG/plasma-org.kde.plasma.desktop-appletsrc"
bash "$SCRIPT" aplicar original >/dev/null
grep -q 'layout=original' "$CONFIG/plasma-org.kde.plasma.desktop-appletsrc"
[[ ! -e "$CONFIG/kwinrc" ]] || { echo 'ERRO: arquivo ausente deveria ser removido' >&2; exit 1; }
grep -q '^Hidden=true$' "$CONFIG/autostart/com.bhyoo.krema.autostart.desktop"
bash "$SCRIPT" aplicar sweet >/dev/null
grep -q 'theme=Sweet' "$CONFIG/kdeglobals"
grep -q 'layout=sweet' "$CONFIG/plasma-org.kde.plasma.desktop-appletsrc"
grep -q 'someKWinEffect=true' "$CONFIG/kwinrc"
[[ -f "$XDG_DATA_HOME/color-schemes/sweet.colors" ]]
bash "$SCRIPT" status | grep -q 'sweet'

# Atualizar mantem a versao anterior em historico.
printf 'layout=sweet-atualizado\n' > "$CONFIG/plasma-org.kde.plasma.desktop-appletsrc"
bash "$SCRIPT" atualizar sweet --dock keep >/dev/null
grep -q 'layout=sweet-atualizado' "$STATE/sweet/config/plasma-org.kde.plasma.desktop-appletsrc"
find "$STATE/.historico" -maxdepth 1 -type d -name 'sweet-*' | grep -q sweet

# Um erro no start deve restaurar automaticamente as configs anteriores.
printf 'layout=antes-da-falha\n' > "$CONFIG/plasma-org.kde.plasma.desktop-appletsrc"
export FAIL_FIRST_START="$TMP/falha"
if bash "$SCRIPT" aplicar original >"$TMP/falha.log" 2>&1; then
  echo 'ERRO: deveria abortar quando Plasma nao inicia' >&2; exit 1
fi
unset FAIL_FIRST_START
grep -q 'layout=antes-da-falha' "$CONFIG/plasma-org.kde.plasma.desktop-appletsrc"
printf 'layout=temporario\n' > "$CONFIG/plasma-org.kde.plasma.desktop-appletsrc"
bash "$SCRIPT" restaurar-ultimo >/dev/null
grep -q 'layout=antes-da-falha' "$CONFIG/plasma-org.kde.plasma.desktop-appletsrc"

mkdir -p "$XDG_DATA_HOME/kubuntu-hybrid/perfis-alternancia/personalizada"
printf 'layout=legado\n' > "$XDG_DATA_HOME/kubuntu-hybrid/perfis-alternancia/personalizada/plasma-org.kde.plasma.desktop-appletsrc"
touch "$XDG_DATA_HOME/kubuntu-hybrid/perfis-alternancia/personalizada/.snapshot"
bash "$SCRIPT" importar-legado personalizada >/dev/null
bash "$SCRIPT" detalhes personalizada | grep -q 'kind=legacy'
echo '[OK] Perfis KDE: salvar, proteger, listar, simular, aplicar, rollback, atualizar, recursos e legado.'
