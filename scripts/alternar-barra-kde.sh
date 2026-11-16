#!/usr/bin/env bash
# Alterna KDE original e visual personalizado (painel superior + Krema).
# Kubuntu 26.04 / Plasma 6. Executar na sessao KDE, sem sudo.
set -Eeuo pipefail

CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}"
STATE_DIR="$DATA_DIR/kubuntu-hybrid/perfis-alternancia"
PLASMA="$CONFIG_DIR/plasma-org.kde.plasma.desktop-appletsrc"
SHELLRC="$CONFIG_DIR/plasmashellrc"
AUTOSTART="$CONFIG_DIR/autostart/com.bhyoo.krema.autostart.desktop"
ORIGINAL="$STATE_DIR/original"
PERSONAL="$STATE_DIR/personalizada"
ACTIVE="$STATE_DIR/perfil-ativo"
PERFIL_SCRIPT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/perfil-barra-atual-kde.sh"
FILES=(plasma-org.kde.plasma.desktop-appletsrc plasmashellrc kremarc)
MARKER="X-Kubuntu-Hybrid-Managed=true"

erro() { printf 'ERRO: %s\n' "$*" >&2; exit 1; }
ajuda() {
  cat <<'TXT'
Uso: bash scripts/alternar-barra-kde.sh COMANDO
  status           Exibe o perfil ativo e backups disponiveis
  salvar-original  Salva o painel KDE original ANTES de personalizar
  backup           Salva o layout personalizado atual
  original         Recupera o KDE tradicional e desliga Krema
  personalizada    Recupera o personalizado ou configura na primeira vez

No Kubuntu novo, rode salvar-original antes de personalizada.
Se nao existir copia do original, original recria os paineis do KDE
(removendo layouts/widgets atuais, previamente copiados como backup).
Trocar de perfil pode exigir logout/login.
TXT
}

[[ "$EUID" -ne 0 ]] || erro "Execute como usuario normal, sem sudo."
case "${1:-ajuda}" in ajuda|--help|-h) ajuda; exit 0;; esac
[[ "${XDG_CURRENT_DESKTOP:-}" == *KDE* || "${XDG_CURRENT_DESKTOP:-}" == *Plasma* ]] ||
  erro "Inicie a sessao KDE Plasma para alternar perfis."
command -v systemctl >/dev/null || erro "systemctl nao encontrado."

preparar() { mkdir -p -- "$STATE_DIR" "$CONFIG_DIR/autostart"; }
snapshot() {
  local dir="$1" nome
  mkdir -p -- "$dir"
  for nome in "${FILES[@]}"; do
    if [[ -f "$CONFIG_DIR/$nome" ]]; then
      cp -p -- "$CONFIG_DIR/$nome" "$dir/$nome"
    else
      rm -f -- "$dir/$nome"
    fi
  done
  : > "$dir/.snapshot"
}
estado() {
  if [[ -f "$ACTIVE" ]]; then
    local salvo
    salvo="$(cat "$ACTIVE")"
    if [[ "$salvo" == original || "$salvo" == personalizada ]]; then
      echo "$salvo"; return
    fi
  fi
  if { [[ -f "$PLASMA" ]] && grep -q '^hybridRole=toolbar$' "$PLASMA"; } ||
     pgrep -x krema >/dev/null 2>&1; then
    echo personalizada
  else
    echo original
  fi
}
historico() {
  local p="$STATE_DIR/historico/$(date +%Y%m%d-%H%M%S)-$$"
  snapshot "$p"
  echo "Copia de seguranca: $p"
}
desligar_dock() {
  if [[ -f "$AUTOSTART" ]] && ! grep -Fq "$MARKER" "$AUTOSTART"; then
    cp -p -- "$AUTOSTART" "$STATE_DIR/autostart-anterior.desktop"
  fi
  cat > "$AUTOSTART" <<'TXT'
[Desktop Entry]
Type=Application
Name=Krema
Hidden=true
X-Kubuntu-Hybrid-Managed=true
TXT
  command -v pkill >/dev/null && pkill -x -u "$(id -u)" krema 2>/dev/null || true
}
ligar_dock() {
  if [[ -f "$STATE_DIR/autostart-anterior.desktop" ]]; then
    cp -p -- "$STATE_DIR/autostart-anterior.desktop" "$AUTOSTART"
  elif [[ -f "$AUTOSTART" ]] && grep -Fq "$MARKER" "$AUTOSTART"; then
    rm -f -- "$AUTOSTART"
  fi
}
trocar_plasma() {
  local modo="$1" dir="${2:-}" nome
  systemctl --user stop plasma-plasmashell.service ||
    erro "Nao foi possivel parar o Plasma; configuracoes preservadas."
  if [[ "$modo" == restaurar ]]; then
    for nome in "${FILES[@]}"; do
      if [[ -f "$dir/$nome" ]]; then
        cp -p -- "$dir/$nome" "$CONFIG_DIR/$nome"
      else
        rm -f -- "$CONFIG_DIR/$nome"
      fi
    done
  else
    rm -f -- "$PLASMA" "$SHELLRC"
  fi
  systemctl --user start plasma-plasmashell.service ||
    erro "Plasma nao reiniciou; faca logout/login. Os backups permanecem salvos."
}
mostrar_status() {
  echo "Perfil detectado: $(estado)"
  for par in "Original:$ORIGINAL" "Personalizada:$PERSONAL"; do
    local nome="${par%%:*}" dir="${par#*:}"
    if [[ -f "$dir/.snapshot" ]]; then echo "$nome: salvo"; else echo "$nome: nao salvo"; fi
  done
  if pgrep -x krema >/dev/null 2>&1; then echo 'Krema: ativa'; else echo 'Krema: inativa'; fi
  echo "Backups: $STATE_DIR"
}
salvar_original() {
  [[ "$(estado)" == original ]] ||
    erro "Visual atual parece personalizado. Salve o original em uma instalacao KDE limpa."
  [[ -s "$PLASMA" ]] || erro "O Plasma ainda nao criou um painel. Inicie a sessao KDE."
  snapshot "$ORIGINAL"
  echo original > "$ACTIVE"
  echo "KDE original salvo em $ORIGINAL"
}
salvar_personal() {
  [[ -s "$PLASMA" ]] || erro "Configuracao Plasma ausente."
  snapshot "$PERSONAL"
  echo personalizada > "$ACTIVE"
  echo "Personalizacao salva em $PERSONAL"
}
ativar_original() {
  local atual
  preparar
  atual="$(estado)"
  if [[ "$atual" == original ]]; then
    [[ -f "$ORIGINAL/.snapshot" || ! -s "$PLASMA" ]] || snapshot "$ORIGINAL"
    desligar_dock
    echo original > "$ACTIVE"
    echo "Perfil original ja ativo; Krema desativada."
    return
  fi
  [[ -s "$PLASMA" ]] || erro "Arquivo Plasma ausente."
  snapshot "$PERSONAL"
  historico
  desligar_dock
  if [[ -f "$ORIGINAL/.snapshot" ]]; then
    trocar_plasma restaurar "$ORIGINAL"
  else
    echo "Sem copia do original: solicitando layout padrao KDE."
    trocar_plasma resetar
  fi
  echo original > "$ACTIVE"
  echo "Perfil KDE original selecionado."
}
ativar_personal() {
  local atual
  preparar
  atual="$(estado)"
  [[ -f "$PERFIL_SCRIPT" ]] ||
    erro "Arquivo complementar nao encontrado: $PERFIL_SCRIPT (baixe o repo completo)."
  if [[ "$atual" == personalizada ]]; then
    echo "Perfil personalizado ja ativo."
    bash "$PERFIL_SCRIPT" instalar-dock
    return
  fi
  [[ -s "$PLASMA" || -f "$PERSONAL/.snapshot" ]] ||
    erro "Entre no KDE e aguarde a criacao do painel, ou restaure um backup salvo."
  if [[ ! -f "$ORIGINAL/.snapshot" && -s "$PLASMA" ]]; then
    snapshot "$ORIGINAL"
    echo "Snapshot original salvo automaticamente."
  fi
  historico
  if [[ -f "$PERSONAL/.snapshot" ]]; then
    trocar_plasma restaurar "$PERSONAL"
    ligar_dock
    bash "$PERFIL_SCRIPT" instalar-dock
    echo "Personalizacao salva restaurada."
  else
    ligar_dock
    bash "$PERFIL_SCRIPT" aplicar
    snapshot "$PERSONAL"
    echo "Primeira personalizacao criada e salva."
  fi
  echo personalizada > "$ACTIVE"
  echo "Perfil personalizado selecionado. Faca logout/login se necessario."
}

case "${1:-}" in
  status) mostrar_status ;;
  salvar-original) preparar; salvar_original ;;
  backup) preparar; salvar_personal ;;
  original) ativar_original ;;
  personalizada) ativar_personal ;;
  *) erro "Comando desconhecido: $1. Use --help." ;;
esac
