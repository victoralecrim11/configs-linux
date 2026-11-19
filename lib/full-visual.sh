#!/usr/bin/env bash
# Ajustes exclusivos do perfil de instalacao full.
setup_full_visual() {
  local wallpaper="" candidate result
  require_cmd kwriteconfig6
  # KWin: Plastik (o esquema de cores escuro e preservado).
  if [[ -d /usr/share/kwin/decorations/kwin4_decoration_qml_plastik ]]; then
    kwriteconfig6 --file kwinrc --group org.kde.kdecoration2 --key library org.kde.kwin.aurorae
    kwriteconfig6 --file kwinrc --group org.kde.kdecoration2 --key theme kwin4_decoration_qml_plastik
  else
    warn "Decoracao Plastik nao instalada; mantendo a decoracao atual."
  fi

  # KDE instala Nuvole em /usr/share/wallpapers/Next: o nome visivel
  # aparece no metadata.json, nao necessariamente no nome da pasta.
  # Usar o pacote completo permite ao Plasma selecionar a resolucao adequada.
  for candidate in "$HOME/.local/share/wallpapers/Nuvole" /usr/share/wallpapers/Nuvole \
                   "$HOME/.local/share/wallpapers/Next" /usr/share/wallpapers/Next; do
    if [[ -f "$candidate/metadata.json" ]] &&
       grep -Eq '"Name"[[:space:]]*:[[:space:]]*"Nuvole"' "$candidate/metadata.json"; then
      wallpaper="$candidate"
      break
    fi
  done
  if [[ -n "$wallpaper" ]]; then
    # Plasma scripting API aceita a pasta do wallpaper (Image=.../Next/).
    local wallpaper_json js_wallpaper
    wallpaper_json="$(python3 -c 'import json,sys; print(json.dumps(sys.argv[1]))' "$wallpaper/")"
    js_wallpaper="var ds=desktops(); for(var i=0;i<ds.length;i++){var d=ds[i];d.wallpaperPlugin='org.kde.image';d.currentConfigGroup=['Wallpaper','org.kde.image','General'];d.writeConfig('Image',$wallpaper_json);}"
    if command -v busctl >/dev/null 2>&1; then
      busctl --user call org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell evaluateScript s "$js_wallpaper" >/dev/null ||
        warn "Nao foi possivel aplicar o wallpaper Nuvole."
    else
      warn "busctl ausente: wallpaper nao foi aplicado."
    fi
  else
    warn "Wallpaper Nuvole nao encontrado. O wallpaper atual foi preservado."
  fi

  # Painel nativo KDE: auto-hide na borda atual, sem apagar widgets.
  local js='(function(){var p=null;for(var i=0;i<panelIds.length;i++){var x=panelById(panelIds[i]);if(!x)continue;var t=x.widgetIds.map(function(id){return x.widgetById(id).type;});if(t.indexOf("org.kde.plasma.icontasks")>=0||t.indexOf("org.kde.plasma.taskmanager")>=0){p=x;break;}if(!p&&t.indexOf("org.kde.plasma.systemtray")>=0)p=x;}if(!p)throw Error("Painel nao encontrado");p.hiding="autohide";print("FULL_PANEL_AUTOHIDE_OK");})();'
  if command -v busctl >/dev/null 2>&1; then
    result="$(busctl --user call org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell evaluateScript s "$js" 2>&1)" ||
      { warn "Nao foi possivel configurar ocultacao automatica: $result"; return 0; }
    [[ "$result" == *FULL_PANEL_AUTOHIDE_OK* ]] ||
      warn "Ocultacao automatica nao confirmada: $result"
  fi
  if command -v qdbus6 >/dev/null 2>&1; then
    qdbus6 org.kde.KWin /KWin reconfigure >/dev/null 2>&1 || true
  fi
  info "Preferencias visuais do Full processadas."
}