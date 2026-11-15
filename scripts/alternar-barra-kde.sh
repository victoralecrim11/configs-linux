#!/usr/bin/env bash
# Alterna entre o layout padrão do Plasma e um layout personalizado salvo.
# Compatível com KDE Plasma 6 (Kubuntu). Não execute com sudo.
set -euo pipefail

CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
CONFIG="$CONFIG_DIR/plasma-org.kde.plasma.desktop-appletsrc"
BACKUP_DIR="$HOME/.local/share/backup-barra-kde"
BACKUP="$BACKUP_DIR/barra-personalizada.conf"

if [[ "${EUID}" -eq 0 ]]; then
  echo 'Erro: execute como seu usuário normal, sem sudo.' >&2
  exit 1
fi

mkdir -p "$BACKUP_DIR"

salvar_estado_atual() {
  if [[ -f "$CONFIG" ]]; then
    cp -p "$CONFIG" "$BACKUP_DIR/antes-alteracao-$(date +%Y%m%d-%H%M%S).conf"
  fi
}

reiniciar_com_configuracao() {
  # Pare o Plasma antes de alterar o arquivo para evitar sobrescrita ao sair.
  if ! systemctl --user stop plasma-plasmashell.service; then
    echo 'Não foi possível parar o Plasma. Nenhuma alteração foi feita.' >&2
    exit 1
  fi

  if ! "$@"; then
    echo 'Falha ao mudar o layout. Tentando iniciar o Plasma novamente.' >&2
    systemctl --user start plasma-plasmashell.service || true
    exit 1
  fi

  if ! systemctl --user start plasma-plasmashell.service; then
    echo 'Não foi possível iniciar o Plasma. Saia da sessão e entre novamente.' >&2
    exit 1
  fi
}

aplicar_original() {
  rm -f -- "$CONFIG"
}

aplicar_personalizada() {
  cp -p -- "$BACKUP" "$CONFIG"
}

case "${1:-}" in
  backup)
    if [[ ! -f "$CONFIG" ]]; then
      echo "Configuração do Plasma não encontrada: $CONFIG" >&2
      exit 1
    fi
    cp -p -- "$CONFIG" "$BACKUP"
    echo "Backup personalizado salvo em: $BACKUP"
    ;;
  original)
    salvar_estado_atual
    reiniciar_com_configuracao aplicar_original
    echo 'Layout padrão solicitado. Se o painel não reaparecer, encerre a sessão e entre novamente.'
    ;;
  personalizada)
    if [[ ! -f "$BACKUP" ]]; then
      echo 'Backup personalizado não encontrado. Execute primeiro: bash alternar-barra-kde.sh backup' >&2
      exit 1
    fi
    salvar_estado_atual
    reiniciar_com_configuracao aplicar_personalizada
    echo 'Layout personalizado restaurado.'
    ;;
  *)
    cat <<'AJUDA'
Uso: bash alternar-barra-kde.sh {backup|original|personalizada}
  backup        Salva o layout atual como personalizado.
  original      Redefine os painéis/widgets ao padrão do Plasma.
  personalizada Restaura o layout personalizado salvo.

Importante: o arquivo gerenciado também contém widgets da área de trabalho.
AJUDA
    exit 1
    ;;
esac

[executed on device: kubuntu-vm (c04215db-43c3-4d78-b111-4bcf58f5f159)]