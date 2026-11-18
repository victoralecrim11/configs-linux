#!/usr/bin/env bash
# Testes somente de leitura: NAO usa sudo/apt, NAO modifica configuracoes.
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
for script in "$ROOT/install.sh" "$ROOT"/lib/*.sh "$ROOT"/scripts/*.sh; do
  bash -n "$script"
done
echo "[OK] sintaxe Bash"
# Shell sem variaveis da sessao grafica (ex.: su - victor) deve receber
# diagnostico, sem instalar pacotes, exigir sudo ou falsificar Wayland.
if out="$(env -u XDG_SESSION_TYPE -u XDG_CURRENT_DESKTOP \
  -u WAYLAND_DISPLAY -u XDG_RUNTIME_DIR \
  bash "$ROOT/install.sh" --check-session 2>&1)"; then
  echo "[ERRO] --check-session aceitou shell sem sessao KDE Wayland." >&2
  exit 1
fi
grep -q 'XDG_SESSION_TYPE=<ausente>' <<< "$out"
grep -q 'Socket Wayland: ausente ou inacessivel' <<< "$out"
grep -q 'A instalacao Premium nao deve continuar' <<< "$out"
echo "[OK] diagnostico sem sessao Wayland e sem sudo"
out="$(bash "$ROOT/install.sh" --dry-run --profile premium --os-release "$ROOT/tests/fixtures/ubuntu-26.04.os-release")"
grep -q 'Backend: ubuntu' <<< "$out"
grep -q 'PPA isac322/krema' <<< "$out"
echo "[OK] Ubuntu 26.04 + Premium"
out="$(bash "$ROOT/install.sh" --dry-run --profile full --with-dotnet --with-vscode --os-release "$ROOT/tests/fixtures/debian-13.os-release")"
grep -q 'Backend: debian' <<< "$out"
grep -q 'OBS Debian_13' <<< "$out"
grep -q 'packages-microsoft-prod.deb' <<< "$out"
echo "[OK] Debian 13 + Full"
out="$(bash "$ROOT/install.sh" --dry-run --profile visual --os-release "$ROOT/tests/fixtures/ubuntu-26.04.os-release")"
grep -q 'Perfil: premium' <<< "$out"
echo "[OK] alias visual"
out="$(bash "$ROOT/install.sh" --dry-run --profile dev --with-node --with-docker --os-release "$ROOT/tests/fixtures/debian-13.os-release")"
grep -q 'node=1 docker=1' <<< "$out"
echo "[OK] Dev e extras"
if bash "$ROOT/install.sh" --dry-run --profile premium --os-release "$ROOT/tests/fixtures/fedora-45.os-release" > /dev/null 2>&1; then
  echo "[ERRO] Fedora nao homologado foi aceito." >&2; exit 1
fi
if bash "$ROOT/install.sh" --dry-run --profile dev --os-release "$ROOT/tests/fixtures/debian-12.os-release" > /dev/null 2>&1; then
  echo "[ERRO] Debian 12 foi aceito." >&2; exit 1
fi
echo "[OK] bloqueio de distros nao homologadas"
if bash "$ROOT/install.sh" --profile dev --yes --os-release "$ROOT/tests/fixtures/debian-13.os-release" > /dev/null 2>&1; then
  echo "[ERRO] override de OS permitido em instalacao real." >&2; exit 1
fi
echo "[OK] override de distro permitido somente em simulacao"
echo "Todos os testes de smoke passaram. Nenhuma instalacao foi executada."
