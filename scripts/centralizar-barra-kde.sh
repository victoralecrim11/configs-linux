#!/usr/bin/env bash
# KDE Plasma 6: menu a esquerda, icontasks ao centro, bandeja a direita.
# Nao altera temas nem aplicativos e exige o painel de fabrica do Kubuntu.
set -Eeuo pipefail
umask 077
fail(){ echo "ERRO: $*" >&2; exit 1; }
usage(){ cat <<'TXT'
Uso: bash scripts/centralizar-barra-kde.sh --status|--aplicar
  --status: informa a ordem dos widgets, sem alterar nada.
  --aplicar: usa dois espacadores nativos e salva a ordem do painel.
Execute no KDE Plasma como usuario normal, sem sudo.
TXT
}
[[ $EUID -ne 0 ]] || fail "Nao execute com sudo."
case "${1:---status}" in
  --help|-h) usage; exit 0 ;;
  --status|--aplicar) MODE="$1" ;;
  *) usage; exit 2 ;;
esac
[[ "${XDG_CURRENT_DESKTOP:-}" == *KDE* || "${XDG_CURRENT_DESKTOP:-}" == *Plasma* ]] ||
  fail "Abra uma sessao KDE Plasma."
for cmd in busctl systemctl kreadconfig6 kwriteconfig6; do
  command -v "$cmd" >/dev/null || fail "Comando ausente: $cmd"
done
CONF="${XDG_CONFIG_HOME:-$HOME/.config}/plasma-org.kde.plasma.desktop-appletsrc"
[[ -s "$CONF" ]] || fail "Arquivo de painel ausente."
if [[ "$MODE" == "--status" ]]; then
  busctl --user call org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell evaluateScript s \
    'var a=[];for(var i=0;i<panelIds.length;i++){var p=panelById(panelIds[i]);if(p)a.push("id="+p.id+" local="+p.location+" widgets="+p.widgetIds.map(function(id){return p.widgetById(id).type}).join("|"));}print(a.join("\n"));'
  exit 0
fi
systemctl --user is-active --quiet plasma-plasmashell.service ||
  fail "Plasma Shell nao esta ativo."
BROOT="${XDG_DATA_HOME:-$HOME/.local/share}/linux-hybrid/backups"
mkdir -p -- "$BROOT"
BACKUP="$(mktemp -d "$BROOT/pre-centralizar-$(date +%Y%m%d-%H%M%S)-XXXXXXXX")"
cp -p -- "$CONF" "$BACKUP/plasma-org.kde.plasma.desktop-appletsrc"
[[ ! -f "${XDG_CONFIG_HOME:-$HOME/.config}/plasmashellrc" ]] ||
  cp -p -- "${XDG_CONFIG_HOME:-$HOME/.config}/plasmashellrc" "$BACKUP/"
echo "Backup: $BACKUP"

# KDE Plasma 6.6 tem index=-1 na API, portanto ordenamos AppletOrder com
# o Plasma parado para ele nao sobrescrever as mudancas ao encerrar.
JS='(function(){
 var p=null;
 for(var i=0;i<panelIds.length;i++){
  var q=panelById(panelIds[i]);
  if(q&&q.widgetIds.some(function(id){return q.widgetById(id).type==="org.kde.plasma.icontasks";})){
   if(p)throw Error("Mais de um painel com gerenciador de tarefas"); p=q;
  }
 }
 if(!p)throw Error("Painel com gerenciador de tarefas nao encontrado");
 if(p.location!=="bottom")throw Error("Este script exige painel inferior");
 var types=["org.kde.plasma.kickoff","org.kde.plasma.pager",
  "org.kde.plasma.icontasks","org.kde.plasma.marginsseparator",
  "org.kde.plasma.systemtray","org.kde.plasma.digitalclock",
  "org.kde.plasma.showdesktop"];
 var ids={}; var spacers=[];
 for(var j=0;j<p.widgetIds.length;j++){
  var w=p.widgetById(p.widgetIds[j]);
  if(w.type==="org.kde.plasma.panelspacer")spacers.push(w.id);
  else if(types.indexOf(w.type)!==-1 && ids[w.type]===undefined)ids[w.type]=w.id;
  else throw Error("Widget extra ou duplicado: "+w.type);
 }
 for(var k=0;k<types.length;k++){if(ids[types[k]]===undefined)throw Error("Widget ausente: "+types[k]);}
 if(spacers.length!==0 && spacers.length!==2)throw Error("Espacadores nao esperados");
 if(spacers.length===0){
   spacers.push(p.addWidget("org.kde.plasma.panelspacer").id);
   spacers.push(p.addWidget("org.kde.plasma.panelspacer").id);
 }
 var order=[
  ids["org.kde.plasma.kickoff"],ids["org.kde.plasma.pager"],spacers[0],
  ids["org.kde.plasma.icontasks"],spacers[1],ids["org.kde.plasma.marginsseparator"],
  ids["org.kde.plasma.systemtray"],ids["org.kde.plasma.digitalclock"],
  ids["org.kde.plasma.showdesktop"]
 ];
 print("CENTER|"+p.id+"|"+order.join(";"));
})();'
result="$(busctl --user call org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell evaluateScript s "$JS")" ||
  fail "Falha na API do Plasma."
line="$(printf '%s\n' "$result" | sed -n 's/^s "CENTER|\([0-9][0-9]*\)|\([0-9;]*\)".*/\1 \2/p')"
[[ -n "$line" ]] || fail "API retornou: $result"
read -r pid order <<< "$line"
[[ "$pid" =~ ^[0-9]+$ && "$order" =~ ^[0-9]+(\;[0-9]+){8}$ ]] ||
  fail "Ordem invalida: $order"
echo "Configurando painel $pid: $order"
systemctl --user stop plasma-plasmashell.service || fail "Nao consegui parar Plasma."
trap 'systemctl --user start plasma-plasmashell.service >/dev/null 2>&1 || true' EXIT
for id in ${order//;/ }; do
  grep -Fq "[Containments][$pid][Applets][$id]" "$CONF" || fail "Widget $id nao persistido."
done
kwriteconfig6 --file plasma-org.kde.plasma.desktop-appletsrc \
  --group Containments --group "$pid" --group General --key AppletOrder "$order"
systemctl --user start plasma-plasmashell.service || fail "Nao consegui reiniciar Plasma."
trap - EXIT
echo "Concluido. Para salvar o perfil sem Krema:"
echo "bash scripts/perfis-kde.sh salvar kde-padrao-centralizado --dock off"
