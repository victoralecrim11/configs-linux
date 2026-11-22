#!/usr/bin/env bash
# Testes isolados do backend CachyOS. Nunca acessam pacman/sudo reais.
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
FIXTURE="$ROOT/tests/fixtures/cachyos.os-release"

result="$(bash "$ROOT/install.sh" --profile full --dry-run --os-release "$FIXTURE")"
grep -q 'Backend: cachyos' <<< "$result"
grep -q 'Krema: AUR' <<< "$result"
grep -q 'Pacman -Syu completo' <<< "$result"
echo "[OK] CachyOS reconhecido; dry-run sem alteracoes"

tmp="$(mktemp -d)"
trap 'rm -rf -- "$tmp"' EXIT
cat > "$tmp/pacman" <<'MOCK'
#!/usr/bin/env bash
printf 'pacman %s\n' "$*" >> "$MOCK_LOG"
case "$1" in
  -Q) exit 1 ;;
  -Si) [[ "$2" != pacote-inexistente ]] ;;
  *) echo "Pacman real nao pode executar" >&2; exit 99 ;;
esac
MOCK
cat > "$tmp/sudo" <<'MOCK'
#!/usr/bin/env bash
printf 'sudo %s\n' "$*" >> "$MOCK_LOG"
MOCK
chmod +x "$tmp/pacman" "$tmp/sudo"
(
  export PATH="$tmp:$PATH" MOCK_LOG="$tmp/transacoes"
  source "$ROOT/lib/core.sh"
  source "$ROOT/lib/pacman.sh"
  DISTRO_BACKEND=cachyos
  [[ "$(package_resolve fonts-inter)" == inter-font ]]
  [[ "$(package_resolve openjdk-21-jdk)" == jdk21-openjdk ]]
  [[ "$(package_resolve php-xml)" == php ]]
  [[ "$(package_resolve plasma-discover-backend-flatpak)" == discover ]]
  package_install_safe "Teste fontes" fonts-inter fonts-jetbrains-mono
  package_install_safe "Teste backend Flatpak" plasma-discover plasma-discover-backend-flatpak kde-config-flatpak
)
grep -q '^sudo pacman -Syu --needed inter-font ttf-jetbrains-mono$' "$tmp/transacoes"
grep -q '^sudo pacman -S --needed discover flatpak-kcm$' "$tmp/transacoes"
[[ "$(grep -c '^sudo pacman -Syu' "$tmp/transacoes")" == 1 ]]
echo "[OK] mapeamento, deduplicacao e primeira transacao -Syu"

if (
  export PATH="$tmp:$PATH" MOCK_LOG="$tmp/indisponivel"
  source "$ROOT/lib/core.sh"
  source "$ROOT/lib/pacman.sh"
  DISTRO_BACKEND=cachyos
  package_install_safe "Pacote ausente" pacote-inexistente
) >/dev/null 2>&1; then
  echo "[ERRO] pacote inexistente nao bloqueado" >&2
  exit 1
fi
[[ ! -f "$tmp/indisponivel" || "$(grep -c '^sudo ' "$tmp/indisponivel" || true)" == 0 ]]
echo "[OK] bloqueio de pacote indisponivel antes de sudo"

if bash "$ROOT/install.sh" --profile full --dry-run \
  --os-release "$ROOT/tests/fixtures/arch.os-release" >/dev/null 2>&1; then
  echo "[ERRO] Arch generico foi homologado acidentalmente" >&2
  exit 1
fi
echo "[OK] Arch generico continua bloqueado"
