#!/usr/bin/env bash
# Dependencias e preferencias comuns a todos os perfis.
setup_common_desktop() {
  apt_install_safe "Fontes comuns" fonts-firacode fonts-jetbrains-mono fonts-inter
  if command -v fc-cache >/dev/null 2>&1; then fc-cache -f >/dev/null 2>&1 || warn "fc-cache falhou"; fi
  # Preferencias KDE sao por usuario e nao exigem root.
  if [[ "${XDG_CURRENT_DESKTOP:-}" == *KDE* || "${XDG_CURRENT_DESKTOP:-}" == *Plasma* ]]; then
    if command -v kwriteconfig6 >/dev/null 2>&1; then
      kwriteconfig6 --file kdeglobals --group General --key font 'Inter,10,-1,5,50,0,0,0,0,0'
      kwriteconfig6 --file kdeglobals --group General --key menuFont 'Inter,10,-1,5,50,0,0,0,0,0'
      kwriteconfig6 --file kdeglobals --group General --key toolBarFont 'Inter,10,-1,5,50,0,0,0,0,0'
      kwriteconfig6 --file kdeglobals --group General --key smallestReadableFont 'Inter,9,-1,5,50,0,0,0,0,0'
      kwriteconfig6 --file kdeglobals --group General --key fixed 'JetBrains Mono,10,-1,5,50,0,0,0,0,0'
      kwriteconfig6 --file kdeglobals --group WM --key activeFont 'Inter,10,-1,5,75,0,0,0,0,0'
      info "Fontes KDE: Inter (interface) e JetBrains Mono (monoespacada); Fira Code instalada para editores."
    fi
    # Comportamento da Krema independente do tema visual.
    bash "$PROJECT_ROOT/scripts/configurar-clique-krema.sh" --apply ||
      warn "Nao foi possivel configurar clique para minimizar na Krema."
    bash "$PROJECT_ROOT/scripts/atalhos-windows-kde.sh" --apply ||
      warn "Atalhos nao foram aplicados integralmente; veja Configuracoes > Atalhos."
  else
    warn "Sessao KDE ausente: fontes instaladas, atalhos KDE devem ser aplicados no login KDE."
  fi
}