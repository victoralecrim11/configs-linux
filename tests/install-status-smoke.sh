#!/usr/bin/env bash
# Teste isolado de estado e inventario: sem sudo, APT ou mudancas no KDE real.
set -Eeuo pipefail
PROJECT_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf -- "$TMP"' EXIT
export HOME="$TMP/home"
export XDG_STATE_HOME="$TMP/state"
export PATH="$TMP/mock:$PATH"
mkdir -p "$HOME" "$TMP/mock"
cat > "$TMP/mock/dpkg-query" <<'SH'
#!/usr/bin/env bash
pkg="${@: -1}"
[[ "$pkg" != "${TEST_MISSING_PACKAGE:-}" ]] || exit 1
printf 'install ok installed'
SH
cat > "$TMP/mock/krema" <<'SH'
#!/usr/bin/env bash
exit 0
SH
chmod +x "$TMP/mock/"*
source "$PROJECT_ROOT/lib/install-status.sh"
DISTRO_ID=debian
DISTRO_VERSION=13

# Consulta nao grava nenhum registro sem conclusao.
output="$(bash "$PROJECT_ROOT/install.sh" --status)"
grep -q 'premium.*sem registro' <<< "$output"
grep -q 'dev.*sem registro' <<< "$output"
grep -q 'full.*sem registro' <<< "$output"
[[ ! -e "$XDG_STATE_HOME/linux-hybrid-v2/perfis-instalacao" ]]
bash "$PROJECT_ROOT/install.sh" --profile full --dry-run >/dev/null
[[ ! -e "$XDG_STATE_HOME/linux-hybrid-v2/perfis-instalacao" ]]
echo '[OK] status/dry-run nao geram conclusao falsa'

# Inventario real do mock: todos presentes, inclusive extras.
install_status_check full "node,docker,dotnet,vscode"
[[ "$INSTALL_STATUS_MISSING" == "" ]]
[[ "$INSTALL_STATUS_PRESENT" == "$INSTALL_STATUS_TOTAL" ]]
install_status_write dev concluido "node" instalador ""
install_status_write premium concluido none instalador ""
install_status_write full concluido node instalador ""
[[ "$(stat -c '%a' "$(install_status_root)/full.state")" == 600 ]]
[[ "$(install_status_read "$(install_status_root)/full.state" status)" == concluido ]]
output="$(bash "$PROJECT_ROOT/install.sh" --list-profiles)"
grep -qE '^premium +concluido ' <<< "$output"
grep -qE '^dev +concluido ' <<< "$output"
grep -qE '^full +concluido ' <<< "$output"
echo '[OK] premium/dev/full registrados com estado verificavel'

# Falha simulada detectada na consulta, mesmo que o registro diga concluido.
export TEST_MISSING_PACKAGE=openjdk-21-jdk
output="$(bash "$PROJECT_ROOT/install.sh" --status)"
grep -qE '^dev +desatualizado ' <<< "$output"
grep -qE '^full +desatualizado ' <<< "$output"
grep -qE '^premium +concluido ' <<< "$output"
if bash "$PROJECT_ROOT/install.sh" --verify-profile full >/dev/null 2>&1; then
  echo '[ERRO] Full ausente passou na verificacao.' >&2; exit 1
fi
echo '[OK] dependencia ausente invalida resultado anterior'

# Arquivo de registro nunca eh executado; manipula-se como dados.
export TEST_MISSING_PACKAGE=''
install_status_write dev falhou none instalador 'simulacao'
output="$(bash "$PROJECT_ROOT/install.sh" --status)"
grep -qE '^dev +falhou ' <<< "$output"
echo '[OK] falha de etapa e status preservados'

# Apenas nomes conhecidos podem ser gravados.
if install_status_write '../unsafe' concluido none instalador '' >/dev/null; then
  echo '[ERRO] Perfil nao autorizado aceito.' >&2; exit 1
fi
echo 'Testes de status de instalacao passaram.'
