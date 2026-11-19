#!/usr/bin/env bash
# Cliques na Krema: minimizar a janela ativa e restaurar ao clicar novamente.
# Funciona independentemente do perfil de instalacao ou tema visual KDE.
set -Eeuo pipefail

mode="${1:---apply}"
case "$mode" in
  --apply|--status) ;;
  *) printf 'Uso: bash scripts/configurar-clique-krema.sh [--apply|--status]\n' >&2; exit 2 ;;
esac
[[ "$EUID" -ne 0 ]] || { printf 'Execute como usuario normal, sem sudo.\n' >&2; exit 1; }

config_dir="${XDG_CONFIG_HOME:-$HOME/.config}"
config_file="$config_dir/kremarc"
if [[ -L "$config_file" ]]; then
  printf 'ERRO: kremarc e um link simbolico; nao sera modificado.\n' >&2
  exit 1
fi
if [[ "$mode" == --status ]]; then
  if ! command -v kreadconfig6 >/dev/null 2>&1; then
    printf 'kreadconfig6 nao esta disponivel.\n' >&2; exit 1
  fi
  printf 'SingleWindowClickAction=%s (esperado 1)\n' "$(kreadconfig6 --file kremarc --group General --key SingleWindowClickAction 2>/dev/null || true)"
  printf 'GroupedWindowClickAction=%s (esperado 2)\n' "$(kreadconfig6 --file kremarc --group General --key GroupedWindowClickAction 2>/dev/null || true)"
  exit 0
fi
command -v kwriteconfig6 >/dev/null 2>&1 || {
  printf 'AVISO: kwriteconfig6 nao encontrado; configuracao Krema nao aplicada.\n' >&2
  exit 1
}
mkdir -p -- "$config_dir"
if [[ -e "$config_file" && ! -f "$config_file" ]]; then
  printf 'ERRO: kremarc nao e um arquivo regular.\n' >&2
  exit 1
fi

# Krema mantem configuracao em memoria. Encerrar antes de escrever evita que
# ela sobrescreva os novos valores ao salvar preferencias no encerramento.
was_running=0
if command -v pgrep >/dev/null 2>&1 && pgrep -x -u "$(id -u)" krema >/dev/null 2>&1; then
  was_running=1
  if ! command -v pkill >/dev/null 2>&1; then
    printf 'ERRO: Krema ativa mas pkill indisponivel; tente apos encerrar a dock.\n' >&2
    exit 1
  fi
  pkill -x -u "$(id -u)" krema || {
    printf 'ERRO: nao foi possivel encerrar Krema para salvar as opcoes.\n' >&2
    exit 1
  }
  for (( attempt=0; attempt<40; attempt++ )); do
    pgrep -x -u "$(id -u)" krema >/dev/null 2>&1 || break
    sleep 0.1
  done
  if pgrep -x -u "$(id -u)" krema >/dev/null 2>&1; then
    printf 'ERRO: Krema ainda esta ativa; nenhuma configuracao foi escrita.\n' >&2
    exit 1
  fi
fi
restart_if_needed() {
  if (( was_running )) && command -v krema >/dev/null 2>&1; then
    (nohup krema >/dev/null 2>&1 </dev/null &)
    printf 'Krema reiniciada para aplicar o comportamento de clique.\n'
  fi
}
trap restart_if_needed EXIT

state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/linux-hybrid-v2/backups"
mkdir -p -m 700 -- "$state_dir"
if [[ -f "$config_file" ]]; then
  backup="$state_dir/kremarc-pre-clique-$(date +%Y%m%d-%H%M%S)-$$.bak"
  cp -p -- "$config_file" "$backup"
  printf 'Backup: %s\n' "$backup"
fi
kwriteconfig6 --file kremarc --group General --key SingleWindowClickAction --type int 1
kwriteconfig6 --file kremarc --group General --key GroupedWindowClickAction --type int 2
printf 'Krema: clique na janela ativa minimiza; clique novamente restaura.\n'
