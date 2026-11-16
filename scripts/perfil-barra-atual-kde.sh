#!/usr/bin/env bash
# Perfil da barra observado em 16/11/2026 na kubuntu-vm.
# KDE Plasma 6: painel superior + dock Krema inferior.
# Uso: bash perfil-barra-atual-kde.sh {status|backup|aplicar|restaurar CAMINHO}
set -Eeuo pipefail

CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
PLASMA="$CONFIG_HOME/plasma-org.kde.plasma.desktop-appletsrc"
SHELLRC="$CONFIG_HOME/plasmashellrc"
KREMA="$CONFIG_HOME/kremarc"
BACKUP_ROOT="$HOME/.local/share/kubuntu-hybrid/perfis-barra"

erro() { printf 'ERRO: %s\n' "$*" >&2; exit 1; }
[[ "$EUID" -ne 0 ]] || erro "Execute como usuario comum, sem sudo."
command -v kwriteconfig6 >/dev/null || erro "kwriteconfig6 nao encontrado."
[[ "${XDG_CURRENT_DESKTOP:-}" == *KDE* || "${XDG_CURRENT_DESKTOP:-}" == *Plasma* ]] || erro "Abra uma sessao KDE Plasma."

painel_id() {
  # Procura o painel que contem a bandeja do sistema; sem IDs fixos da VM.
  awk '
    /^\[Containments\]\[[0-9]+\]$/ { id=$0; sub(/^\[Containments\]\[/,"",id);sub(/\]$/,"",id); next }
    /^\[Containments\]\[[0-9]+\]\[Applets\]/ { id=$0;sub(/^\[Containments\]\[/,"",id);sub(/\].*/,"",id) }
    /^plugin=org.kde.plasma.systemtray$/ { print id; exit }
  ' "$PLASMA"
}

backup() {
  mkdir -p "$BACKUP_ROOT"
  local dest="$BACKUP_ROOT/$(date +%Y%m%d-%H%M%S)-$$"
  mkdir -p "$dest"
  for name in plasma-org.kde.plasma.desktop-appletsrc plasmashellrc kremarc; do
    [[ ! -f "$CONFIG_HOME/$name" ]] || cp -p "$CONFIG_HOME/$name" "$dest/$name"
  done
  printf '%s\n' "$dest"
}

status() {
  local id
  id=$(painel_id)
  echo "Painel KDE: ${id:-nao encontrado}"
  if [[ -n "$id" ]]; then
    for key in location opacityMode hybridRole; do
      echo "  $key=$(kreadconfig6 --file plasma-org.kde.plasma.desktop-appletsrc --group Containments --group "$id" --key "$key" 2>/dev/null || true)"
    done
    for key in floating panelVisibility; do
      echo "  $key=$(kreadconfig6 --file plasmashellrc --group PlasmaViews --group "Panel $id" --key "$key" 2>/dev/null || true)"
    done
  fi
  for key in BackgroundOpacity BackgroundStyle Edge HideDelay PinnedLaunchers RevealTriggerLocation ShowDelay VisibilityMode; do
    echo "Krema $key=$(kreadconfig6 --file kremarc --group General --key "$key" 2>/dev/null || true)"
  done
}

aplicar() {
  local id js b
  [[ -f "$PLASMA" ]] || erro "Arquivo de paineis nao encontrado."
  id=$(painel_id)
  [[ -n "$id" ]] || erro "Nenhum painel com bandeja encontrado; nenhuma mudanca aplicada."
  b=$(backup)
  echo "Backup anterior: $b"

  # Altera o painel em tempo real usando a API de scripts do Plasma.
  command -v busctl >/dev/null || erro "busctl nao encontrado."
  js='(function(){var p=null;for(var i=0;i<panelIds.length;i++){var c=panelById(panelIds[i]);if(!c)continue;for(var j=0;j<c.widgetIds.length;j++){var w=c.widgetById(c.widgetIds[j]);if(w&&w.type==="org.kde.plasma.systemtray"){p=c;break;}}if(p)break;}if(!p)throw new Error("painel nao encontrado");p.location="top";p.height=36;p.lengthMode="fill";p.hiding="none";print("painel ajustado: "+p.id);})();'
  busctl --user call org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell evaluateScript s "$js" || erro "Falha ao aplicar posicao do painel (backup: $b)."

  # Aparencia: painel superior solido, nao flutuante, sempre visivel.
  kwriteconfig6 --file plasma-org.kde.plasma.desktop-appletsrc --group Containments --group "$id" --key opacityMode 1
  kwriteconfig6 --file plasmashellrc --group PlasmaViews --group "Panel $id" --key floating 0
  kwriteconfig6 --file plasmashellrc --group PlasmaViews --group "Panel $id" --key panelVisibility 0
  kwriteconfig6 --file plasmashellrc --group PlasmaViews --group "Panel $id" --group Defaults --key thickness 36

  # Estado atual da Krema: dock inferior opaca, zoom controlado pelo app.
  for pair in 'BackgroundOpacity=1' 'BackgroundStyle=2' 'Edge=1' 'HideDelay=1600' 'RevealTriggerLocation=0' 'ShowDelay=100' 'VisibilityMode=2'; do
    kwriteconfig6 --file kremarc --group General --key "${pair%%=*}" "${pair#*=}"
  done
  kwriteconfig6 --file kremarc --group General --key PinnedLaunchers 'applications:org.kde.dolphin.desktop,applications:org.kde.konsole.desktop,applications:systemsettings.desktop'
  echo "Perfil gravado. Faça logout/login para o Plasma e Krema relerem todas as opcoes."
  echo "Nao foram removidos widgets, nem executada reinicializacao automatica."
}

restaurar() {
  local origem="${1:-}"
  [[ -n "$origem" && -d "$origem" ]] || erro "Indique a pasta de backup: restaurar CAMINHO"
  [[ "$origem" == "$BACKUP_ROOT/"* ]] || erro "Aceito apenas backup gerado em $BACKUP_ROOT."
  [[ -f "$origem/plasma-org.kde.plasma.desktop-appletsrc" ]] || erro "Backup sem layout Plasma."
  local b
  b=$(backup); echo "Copia de seguranca antes da restauracao: $b"
  # Evita que o Plasma sobrescreva a configuracao restaurada ao sair.
  systemctl --user stop plasma-plasmashell.service || erro "Nao foi possivel parar o Plasma."
  for name in plasma-org.kde.plasma.desktop-appletsrc plasmashellrc kremarc; do
    [[ ! -f "$origem/$name" ]] || cp -p "$origem/$name" "$CONFIG_HOME/$name"
  done
  systemctl --user start plasma-plasmashell.service || erro "Reabra a sessao para iniciar o Plasma."
  echo "Backup restaurado. Reinicie a Krema ou faca logout/login para aplicar a dock."
}

case "${1:-status}" in
  status) status ;;
  backup) backup ;;
  aplicar) aplicar ;;
  restaurar) restaurar "${2:-}" ;;
  *) erro "Uso: $0 {status|backup|aplicar|restaurar CAMINHO}" ;;
esac
