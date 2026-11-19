#!/usr/bin/env bash
# Ativa o efeito Magic Lamp nativo do KWin/Plasma 6.
# Execute como usuario da sessao KDE. Nao reinicia KWin no Wayland.
set -Eeuo pipefail

mode="${1:---apply}"
case "$mode" in
  --apply|--status) ;;
  *) printf 'Uso: bash scripts/efeito-lampada-magica.sh [--apply|--status]\n' >&2; exit 2 ;;
esac

if [[ "$EUID" -eq 0 ]]; then
  printf 'ERRO: execute como usuario normal, sem sudo.\n' >&2
  exit 1
fi
command -v kreadconfig6 >/dev/null 2>&1 || {
  printf 'ERRO: kreadconfig6 nao encontrado.\n' >&2
  exit 1
}
config="${XDG_CONFIG_HOME:-$HOME/.config}/kwinrc"
current="$(kreadconfig6 --file kwinrc --group Plugins --key magiclampEnabled 2>/dev/null || true)"
if [[ "$mode" == --status ]]; then
  printf 'Magic Lamp em kwinrc: %s\n' "${current:-nao definido}"
  printf 'Minimizacao alternativa (squash): %s\n' "$(kreadconfig6 --file kwinrc --group Plugins --key squashEnabled 2>/dev/null || true)"
  if command -v qdbus6 >/dev/null 2>&1; then
    printf 'KWin Effects (D-Bus):\n'
    qdbus6 org.kde.KWin /Effects org.kde.kwin.Effects.listOfEffects 2>/dev/null || true
  fi
  exit 0
fi

case "${XDG_CURRENT_DESKTOP:-}" in
  *KDE*|*Plasma*) ;;
  *) printf 'ERRO: entre na sessao KDE Plasma antes de aplicar.\n' >&2; exit 1 ;;
esac
[[ "${XDG_SESSION_TYPE:-}" == wayland || "${XDG_SESSION_TYPE:-}" == x11 ]] || {
  printf 'ERRO: sessao grafica KDE nao identificada.\n' >&2
  exit 1
}
command -v kwriteconfig6 >/dev/null 2>&1 || {
  printf 'ERRO: kwriteconfig6 nao encontrado.\n' >&2
  exit 1
}
if [[ -L "$config" ]]; then
  printf 'ERRO: kwinrc e um link simbolico; configuracao nao modificada.\n' >&2
  exit 1
fi
mkdir -p -- "${XDG_STATE_HOME:-$HOME/.local/state}/linux-hybrid-v2/backups"
if [[ -f "$config" ]]; then
  backup="${XDG_STATE_HOME:-$HOME/.local/state}/linux-hybrid-v2/backups/kwinrc-pre-magiclamp-$(date +%Y%m%d-%H%M%S)-$$"
  cp -p -- "$config" "$backup"
  printf 'Backup anterior: %s\n' "$backup"
fi

# Efeito nativo; squash compete pela mesma transicao de minimizar.
kwriteconfig6 --file kwinrc --group Plugins --key magiclampEnabled --type bool true
kwriteconfig6 --file kwinrc --group Plugins --key squashEnabled --type bool false

# Reconfigure KWin e tente carregar o efeito em tempo real.
# Apenas gravar kwinrc nao garante carregamento ate o proximo login.
if command -v qdbus6 >/dev/null 2>&1; then
  qdbus6 org.kde.KWin /KWin reconfigure >/dev/null 2>&1 ||
    printf 'AVISO: nao foi possivel solicitar reconfigure ao KWin.\n' >&2
  if qdbus6 org.kde.KWin /Effects org.kde.kwin.Effects.loadEffect magiclamp >/dev/null 2>&1; then
    printf 'Magic Lamp: solicitacao de carregamento enviada ao KWin.\n'
  else
    printf 'AVISO: KWin nao confirmou loadEffect magiclamp; confira suporte do efeito e entre novamente na sessao.\n' >&2
  fi
else
  printf 'AVISO: qdbus6 ausente; configuracao salva para o proximo login.\n' >&2
fi
printf 'Magic Lamp configurada; teste minimizando uma janela.\n'
