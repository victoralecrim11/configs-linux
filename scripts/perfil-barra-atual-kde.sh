#!/usr/bin/env bash
# Perfil da barra observado em 16/11/2026 na kubuntu-vm.
# KDE Plasma 6: painel superior + dock Krema inferior.
# Uso: bash perfil-barra-atual-kde.sh {status|backup|instalar-dock|aplicar|restaurar CAMINHO}
# Pastas sao criadas sob demanda; o layout Plasma deve existir apos o primeiro login.
set -Eeuo pipefail

CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
PLASMA="$CONFIG_HOME/plasma-org.kde.plasma.desktop-appletsrc"
SHELLRC="$CONFIG_HOME/plasmashellrc"
KREMA="$CONFIG_HOME/kremarc"
BACKUP_ROOT="${XDG_DATA_HOME:-$HOME/.local/share}/kubuntu-hybrid/perfis-barra"

erro() { printf 'ERRO: %s\n' "$*" >&2; exit 1; }
[[ "$EUID" -ne 0 ]] || erro "Execute como usuario comum, sem sudo."
command -v kwriteconfig6 >/dev/null || erro "kwriteconfig6 nao encontrado."
[[ "${XDG_CURRENT_DESKTOP:-}" == *KDE* || "${XDG_CURRENT_DESKTOP:-}" == *Plasma* ]] || erro "Abra uma sessao KDE Plasma."

preparar_diretorios() {
  # Em uma instalacao limpa, os diretórios podem não existir.
  # Criar pastas e seguro; gerar um arquivo Plasma vazio nao e seguro.
  mkdir -p -- "$CONFIG_HOME" "$BACKUP_ROOT" || erro "Nao foi possivel criar diretorios de configuracao e backup."
}

instalar_krema() {
  # A Krema e distribuida oficialmente em ppa:isac322/krema.
  # Evita downloads executaveis arbitrarios e alteracoes desnecessarias.
  if command -v krema >/dev/null 2>&1; then
    echo "Dock Krema ja instalada: $(command -v krema)"
    return 0
  fi

  [[ "${XDG_SESSION_TYPE:-}" == "wayland" ]] || erro "A Krema requer sessao Wayland."
  [[ -r /etc/os-release ]] || erro "Nao foi possivel identificar a distribuicao."
  local os_id version
  os_id=$(sed -n 's/^ID=//p' /etc/os-release | head -1 | tr -d '"')
  version=$(sed -n 's/^VERSION_ID=//p' /etc/os-release | head -1 | tr -d '"')
  [[ "$os_id" == "ubuntu" && "$version" == "26.04" ]] ||
    erro "Instalacao automatica homologada apenas para Kubuntu/Ubuntu 26.04; sistema: $os_id $version."

  command -v sudo >/dev/null || erro "sudo nao encontrado."
  command -v apt-get >/dev/null || erro "apt-get nao encontrado."
  echo "Instalando Krema pelo PPA oficial do projeto (ppa:isac322/krema)."

  if ! command -v add-apt-repository >/dev/null; then
    sudo apt-get update || erro "Falha ao atualizar indice APT."
    sudo apt-get install -y software-properties-common ||
      erro "Falha ao instalar software-properties-common."
  fi

  if ! grep -RqsE 'isac322/krema|isac322-ubuntu-krema' /etc/apt/sources.list.d/ 2>/dev/null; then
    sudo add-apt-repository -y ppa:isac322/krema ||
      erro "Nao foi possivel adicionar o PPA do Krema."
  fi
  sudo apt-get update || erro "Falha no apt-get update."
  local candidate simulation
  candidate=$(LC_ALL=C apt-cache policy krema | awk '/Candidate:/{print $2;exit}')
  [[ -n "$candidate" && "$candidate" != "(none)" ]] ||
    erro "Pacote Krema indisponivel para esta versao do Kubuntu."
  simulation=$(LC_ALL=C apt-get --simulate install krema 2>&1) ||
    erro "Dependencias da Krema nao puderam ser resolvidas: $simulation"
  if grep -q '^Remv ' <<< "$simulation"; then
    echo "$simulation" >&2
    erro "Instalacao cancelada: o APT removeria pacotes existentes."
  fi
  sudo apt-get install -y krema || erro "Falha ao instalar Krema."
  command -v krema >/dev/null || erro "Krema nao encontrado apos a instalacao."
  echo "Krema instalado com sucesso."
}

iniciar_krema() {
  [[ "${XDG_SESSION_TYPE:-}" == "wayland" ]] ||
    { echo "AVISO: Krema exige Wayland; inicie uma sessao Wayland." >&2; return 0; }
  if pgrep -x krema >/dev/null; then
    echo "Krema ja esta em execucao; para atualizar a aparencia, faca logout/login."
    return 0
  fi
  mkdir -p -- "${XDG_STATE_HOME:-$HOME/.local/state}/kubuntu-hybrid"
  (nohup krema >"${XDG_STATE_HOME:-$HOME/.local/state}/kubuntu-hybrid/krema.log" 2>&1 </dev/null &)
  echo "Inicializacao da Krema solicitada. O pacote inclui autostart na sessao KDE."
}

verificar_layout() {
  [[ -s "$PLASMA" ]] || erro "O Plasma ainda nao criou $PLASMA. Inicie o KDE, faca login e confira se existe um painel. Nao criaremos um layout vazio."
}


painel_id() {
  [[ -s "$PLASMA" ]] || return 0
  # Procura o painel que contem a bandeja do sistema; sem IDs fixos da VM.
  awk '
    /^\[Containments\]\[[0-9]+\]$/ { id=$0; sub(/^\[Containments\]\[/,"",id);sub(/\]$/,"",id); next }
    /^\[Containments\]\[[0-9]+\]\[Applets\]/ { id=$0;sub(/^\[Containments\]\[/,"",id);sub(/\].*/,"",id) }
    /^plugin=org.kde.plasma.systemtray$/ { print id; exit }
  ' "$PLASMA"
}

backup() {
  preparar_diretorios
  local dest="$BACKUP_ROOT/$(date +%Y%m%d-%H%M%S)-$$"
  mkdir -p -- "$dest"
  for name in plasma-org.kde.plasma.desktop-appletsrc plasmashellrc kremarc; do
    [[ ! -f "$CONFIG_HOME/$name" ]] || cp -p "$CONFIG_HOME/$name" "$dest/$name"
  done
  printf '%s\n' "$dest"
}

status() {
  if [[ ! -s "$PLASMA" ]]; then
    echo "Painel KDE: configuracao ainda nao criada. Entre no Plasma e configure um painel antes de aplicar."
    return 0
  fi
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
  preparar_diretorios
  verificar_layout
  id=$(painel_id)
  [[ -n "$id" ]] || erro "Nenhum painel com bandeja encontrado; nenhuma mudanca aplicada."
  b=$(backup)
  echo "Backup anterior: $b"
  instalar_krema

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
  iniciar_krema
  echo "Perfil gravado. Faca logout/login para Plasma e Krema relerem todas as opcoes."
  echo "Nao foram removidos widgets, nem executada reinicializacao automatica."
}

restaurar() {
  local origem="${1:-}"
  preparar_diretorios
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
  instalar-dock) preparar_diretorios; instalar_krema; iniciar_krema ;;
  aplicar) aplicar ;;
  restaurar) restaurar "${2:-}" ;;
  *) erro "Uso: $0 {status|backup|instalar-dock|aplicar|restaurar CAMINHO}" ;;
esac
