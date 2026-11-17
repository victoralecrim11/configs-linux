#!/usr/bin/env bash
# Sweet KDE: painel nativo inferior + dock Krema centralizada, sem sobrepor janelas maximizadas.
# KDE Plasma 6 / Wayland. Nao cria paineis extras; conserva os widgets e lancadores.
set -Eeuo pipefail
umask 077

CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}"
BACKUPS="$DATA_DIR/linux-hybrid/backups/sweet-barra"
REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
MODE="${1:-status}"
SAVE=0

usage() {
  cat <<'HELP'
Uso: bash scripts/corrigir-sweet-barra.sh [status|aplicar|testar] [--salvar]
  status           Mostra o painel e a configuracao da Krema (nao altera nada).
  aplicar          Painel KDE inferior (sempre visivel) + Krema centralizada.
  aplicar --salvar  Aplica e atualiza o perfil nomeado sweet com backup/versionamento.
  testar           Confirma layout e processo Krema sem alterar nada.

Requisitos: KDE Plasma 6 em Wayland, Krema instalada, perfil Sweet selecionado.
Execute sem sudo. O script NAO apaga aplicativos/atalhos do painel nem da dock.
HELP
}
fail() { printf 'ERRO: %s\n' "$*" >&2; exit 1; }
msg() { printf '%s\n' "$*"; }
if [[ "$MODE" == "--help" || "$MODE" == "-h" ]]; then usage; exit 0; fi
case "$MODE" in status|aplicar|testar) ;; *) usage; fail "Comando invalido: $MODE";; esac
shift || true
while (($#)); do
  case "$1" in
    --salvar) SAVE=1; shift ;;
    *) fail "Parametro desconhecido: $1" ;;
  esac
done
[[ "$MODE" == aplicar || "$SAVE" == 0 ]] || fail "--salvar so pode ser usado com aplicar."
[[ "$EUID" -ne 0 ]] || fail "Nao execute com sudo."
[[ "${XDG_CURRENT_DESKTOP:-}" == *KDE* || "${XDG_CURRENT_DESKTOP:-}" == *Plasma* ]] ||
  fail "Este script precisa de uma sessao KDE Plasma."
command -v busctl >/dev/null || fail "busctl ausente."
command -v kreadconfig6 >/dev/null || fail "kreadconfig6 ausente."

panel_script='
var chosen=null;
for (var i=0; i<panelIds.length; i++) {
  var p=panelById(panelIds[i]);
  if (p && p.readConfig("hybridRole")==="toolbar") { chosen=p; break; }
}
if (!chosen) {
  for (var i=0; i<panelIds.length; i++) {
    var p=panelById(panelIds[i]);
    if (!p) continue;
    var widgets=p.widgets(), found=false;
    for (var j=0; j<widgets.length; j++) {
      if (widgets[j].type==="org.kde.plasma.systemtray") { found=true; break; }
    }
    if (found) {chosen=p;break;}
  }
}
if (!chosen) {print("SWEET_ERROR_NO_MAIN_PANEL");}
else {
  var aux=null;
  for (var k=0;k<panelIds.length;k++) {
    var p=panelById(panelIds[k]);
    if(p && p.readConfig("hybridRole")==="sweet-krema-reservation"){aux=p;break;}
  }
  if(aux)aux.remove();
  chosen.location="bottom";
  chosen.hiding="none";
  chosen.height=36;
  chosen.lengthMode="fill";
  chosen.floating=false;
  print("SWEET_PANEL_OK id="+chosen.id+" location="+chosen.location+
        " hiding="+chosen.hiding+" height="+chosen.height+
        " widgets="+chosen.widgets().length);
}'
check_script='
var x=[];
for (var i=0;i<panelIds.length;i++){
  var p=panelById(panelIds[i]);
  x.push("id="+p.id+",location="+p.location+",height="+p.height+
   ",hiding="+p.hiding+",widgets="+p.widgets().length+
   ",role="+p.readConfig("hybridRole"));
}
print(x.join("|"));'

panel_eval() {
  busctl --user call org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell evaluateScript s "$1"
}
status() {
  msg "=== PAINEIS KDE ==="
  panel_eval "$check_script"
  msg "=== KREMA ==="
  for key in VisibilityMode Edge FloatingMarginReference ReserveScreenSpace PinnedLaunchers; do
    printf '%s=' "$key"
    kreadconfig6 --file kremarc --group General --key "$key"
  done
  if pgrep -x -u "$(id -u)" krema >/dev/null 2>&1; then msg "krema=ativa"; else msg "krema=inativa"; fi
}
testar() {
  local result
  result="$(panel_eval "$check_script")" || fail "Plasma Shell nao respondeu."
  [[ "$result" == *'location=bottom'* && "$result" == *'hiding=none'* ]] ||
    fail "Painel principal nao esta embaixo com visibilidade permanente."
  [[ "$result" != *'sweet-krema-reservation'* ]] ||
    fail "Existe um painel auxiliar redundante, que deve ser removido."
  [[ "$(kreadconfig6 --file kremarc --group General --key VisibilityMode)" == 0 ]] ||
    fail "Krema ainda pode ocultar/desviar de janelas."
  [[ "$(kreadconfig6 --file kremarc --group General --key Edge)" == 1 ]] ||
    fail "Krema nao esta na borda inferior."
  [[ "${XDG_SESSION_TYPE:-}" == wayland ]] || fail "Krema exige Wayland."
  pgrep -x -u "$(id -u)" krema >/dev/null 2>&1 || fail "Krema nao esta executando."
  msg "OK: painel inferior, visibilidade permanente, Krema inferior e em execucao."
}
case "$MODE" in
  status) status; exit 0 ;;
  testar) testar; exit 0 ;;
esac

[[ "${XDG_SESSION_TYPE:-}" == wayland ]] || fail "Use uma sessao KDE Wayland."
command -v kwriteconfig6 >/dev/null || fail "kwriteconfig6 ausente."
command -v krema >/dev/null || fail "Instale a Krema antes."
[[ "$(kreadconfig6 --file kdeglobals --group KDE --key LookAndFeelPackage)" == Sweet ]] ||
  fail "Ative o tema Sweet antes de aplicar o perfil."
[[ -s "$CONFIG_DIR/plasma-org.kde.plasma.desktop-appletsrc" ]] ||
  fail "Configuracao do painel KDE nao encontrada."

mkdir -p -- "$BACKUPS"
BACKUP="$(mktemp -d "$BACKUPS/antes-XXXXXXXX")"
for name in plasma-org.kde.plasma.desktop-appletsrc plasmashellrc kremarc kdeglobals; do
  [[ ! -f "$CONFIG_DIR/$name" ]] || cp -p -- "$CONFIG_DIR/$name" "$BACKUP/$name"
done
msg "Backup: $BACKUP"

result="$(panel_eval "$panel_script")" || fail "Nao foi possivel ajustar o painel KDE."
msg "$result"
[[ "$result" == *SWEET_PANEL_OK* ]] || fail "O Plasma nao identificou um painel principal."

# O Krema guarda preferencias em memoria: fecha-lo antes de regravar as opcoes.
pkill -x -u "$(id -u)" krema 2>/dev/null || true
for _ in 1 2 3 4 5 6 7 8 9 10; do
  pgrep -x -u "$(id -u)" krema >/dev/null 2>&1 || break
  sleep 0.2
done
pgrep -x -u "$(id -u)" krema >/dev/null 2>&1 &&
  fail "Krema nao encerrou; backup em $BACKUP"
kwriteconfig6 --file kremarc --group General --key VisibilityMode --type int 0
kwriteconfig6 --file kremarc --group General --key Edge --type int 1
kwriteconfig6 --file kremarc --group General --key FloatingMarginReference --type int 0
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/linux-hybrid"
mkdir -p -- "$STATE_DIR"
(nohup krema > "$STATE_DIR/krema-sweet.log" 2>&1 </dev/null &)
sleep 1
testar

if (( SAVE )); then
  MANAGER="$REPO_ROOT/scripts/perfis-kde.sh"
  [[ -f "$MANAGER" ]] || fail "Gerenciador de perfis nao encontrado."
  if [[ -f "$DATA_DIR/linux-hybrid/profiles/sweet/.snapshot" ]]; then
    bash "$MANAGER" atualizar sweet --recursos --dock on
  else
    bash "$MANAGER" salvar sweet --recursos --dock on
  fi
  msg "Perfil sweet atualizado com o painel inferior e Krema."
fi
msg "Pronto. Painel KDE e dock foram mantidos, sem painel inferior duplicado."
