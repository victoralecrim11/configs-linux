#!/usr/bin/env bash
# Teste isolado da integracao Flatpak/Discover: nao usa APT ou Flatpak reais.
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf -- "$TMP"' EXIT
export HOME="$TMP/home"
export TEST_USER_REMOTE="$TMP/user-flathub"
export TEST_SYSTEM_REMOTE="$TMP/system-flathub"
export TEST_LOG="$TMP/flatpak-calls.log"
export PATH="$TMP/mock:$PATH"
mkdir -p "$HOME" "$TMP/mock"
: > "$TEST_LOG"
cat > "$TMP/mock/flatpak" <<'SH'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$TEST_LOG"
case "$*" in
  'remotes --user --columns=name')
    [[ ! -f "$TEST_USER_REMOTE" ]] || printf 'flathub\n'
    ;;
  'remotes --system --columns=name')
    [[ ! -f "$TEST_SYSTEM_REMOTE" ]] || printf 'flathub\n'
    ;;
  'remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo')
    touch "$TEST_USER_REMOTE"
    ;;
  *) echo "Chamada Flatpak inesperada: $*" >&2; exit 2 ;;
esac
SH
chmod +x "$TMP/mock/flatpak"
source "$ROOT/lib/flatpak-discover.sh"
info() { :; }
die() { echo "$*" >&2; exit 1; }
require_cmd() { command -v "$1" >/dev/null 2>&1; }
package_install_safe() {
  [[ "$1" == "Flatpak e Discover" && "$#" -eq 5 ]] || return 1
  [[ "$2" == flatpak && "$3" == plasma-discover &&
     "$4" == plasma-discover-backend-flatpak && "$5" == kde-config-flatpak ]]
}
has_package() {
  [[ "$1" != "${TEST_MISSING_PACKAGE:-}" ]]
}
setup_flatpak_discover
[[ -f "$TEST_USER_REMOTE" ]]
[[ "$(grep -c '^remote-add ' "$TEST_LOG")" -eq 1 ]]
setup_flatpak_discover
[[ "$(grep -c '^remote-add ' "$TEST_LOG")" -eq 1 ]]
echo '[OK] Flatpak: instalacao idempotente no escopo usuario'

rm -f -- "$TEST_USER_REMOTE"
touch "$TEST_SYSTEM_REMOTE"
setup_flatpak_discover
[[ ! -f "$TEST_USER_REMOTE" ]]
[[ "$(grep -c '^remote-add ' "$TEST_LOG")" -eq 1 ]]
echo '[OK] Flatpak: remoto de sistema ja existente nao duplicado'

if ( export TEST_MISSING_PACKAGE=kde-config-flatpak; setup_flatpak_discover >/dev/null 2>&1 ); then
  echo '[ERRO] Pacote ausente nao foi detectado.' >&2; exit 1
fi
echo '[OK] Flatpak: pacote faltante bloqueia conclusao'

out="$(bash "$ROOT/install.sh" --profile full --with-visual-presets --dry-run \
  --os-release "$ROOT/tests/fixtures/debian-13.os-release")"
grep -q 'Flatpak, Discover e Flathub' <<< "$out"
grep -q 'Presets opcionais: Sweet, Layan' <<< "$out"
if bash "$ROOT/install.sh" --profile dev --with-visual-presets --dry-run \
  --os-release "$ROOT/tests/fixtures/debian-13.os-release" >/dev/null 2>&1; then
  echo '[ERRO] Presets visuais foram aceitos no perfil dev.' >&2; exit 1
fi
echo '[OK] presets visuais disponiveis apenas via opt-in Premium/Full'
