#!/usr/bin/env bash
# Smoke isolado do layout Sweet: nenhuma chamada ao Plasma real / sudo / Krema.
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT="$ROOT/scripts/corrigir-sweet-barra.sh"
bash -n "$SCRIPT"
[[ "$EUID" -ne 0 ]] || { echo "Nao rode como root." >&2; exit 1; }
TMP="$(mktemp -d)"
trap 'rm -rf -- "$TMP"' EXIT
mkdir -p -- "$TMP/mock"
export HOME="$TMP/home"
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_CURRENT_DESKTOP=KDE
export XDG_SESSION_TYPE=wayland
export PATH="$TMP/mock:$PATH"

cat > "$TMP/mock/busctl" <<'MOCK'
#!/usr/bin/env bash
loc="${MOCK_PANEL_LOCATION:-bottom}"
printf 's "id=2,location=%s,height=36,hiding=none,widgets=7,role=toolbar"\n' "$loc"
MOCK
cat > "$TMP/mock/kreadconfig6" <<'MOCK'
#!/usr/bin/env bash
case "$*" in
  *"--key VisibilityMode"*) printf '%s\n' "${MOCK_KREMA_MODE:-0}" ;;
  *"--key Edge"*) echo 1 ;;
  *"--key LookAndFeelPackage"*) echo Sweet ;;
  *) echo '' ;;
esac
MOCK
printf '#!/usr/bin/env bash\nexit 0\n' > "$TMP/mock/pgrep"
chmod +x "$TMP/mock/"*

bash "$SCRIPT" --help | grep -q 'aplicar'
out="$(bash "$SCRIPT" status)"
grep -q 'location=bottom' <<< "$out"
out="$(bash "$SCRIPT" testar)"
grep -q 'OK: painel inferior' <<< "$out"
if MOCK_PANEL_LOCATION=top bash "$SCRIPT" testar >/dev/null 2>&1; then
  echo '[ERRO] Painel superior foi aceito como inferior.' >&2; exit 1
fi
if MOCK_KREMA_MODE=2 bash "$SCRIPT" testar >/dev/null 2>&1; then
  echo '[ERRO] Krema com Dodge foi aceita como AlwaysVisible.' >&2; exit 1
fi
if XDG_CURRENT_DESKTOP=GNOME bash "$SCRIPT" testar >/dev/null 2>&1; then
  echo '[ERRO] Outro desktop foi aceito.' >&2; exit 1
fi
echo '[OK] Barra Sweet: sintaxe, leitura, painel inferior, Krema sempre visivel e rejeicao de estados incorretos.'
