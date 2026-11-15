#!/usr/bin/env bash
# Kubuntu Hybrid Setup - Windows 11 + Garuda + macOS-style dock
# Target: Kubuntu 26.04 LTS / KDE Plasma 6 / Wayland
# Review before executing. Run as a regular desktop user (NOT with sudo).
set -Eeuo pipefail

VERSION="1.0.2"
PROFILE="full"       # visual | dev | full
ASSUME_YES=0
DRY_RUN=0
SKIP_PPA=0
SKIP_PANEL=0
SKIP_DOCK=0
SKIP_ZRAM=0
SKIP_NODE=0
SKIP_VSCODE=0
RESTORE_DIR=""

info() { printf '\033[1;36m[INFO]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[AVISO]\033[0m %s\n' "$*" >&2; }
fail() { printf '\033[1;31m[ERRO]\033[0m %s\n' "$*" >&2; exit 1; }

usage() {
cat <<'USAGE'
Kubuntu Hybrid Setup v1.0.2 - Windows 11 + Garuda + dock macOS

Uso:
  bash kubuntu-hybrid-setup.sh [opcoes]

Opcoes:
  --profile visual|dev|full  Visual, desenvolvimento, ou ambos (padrao: full)
  --dry-run                  Lista o plano, sem fazer alteracoes
  --yes                      Aprova automaticamente perguntas opcionais
  --no-ppa                   Nao adiciona PPA do Krema
  --no-dock                  Nao instala/abre Krema
  --no-panel                 Nao altera barra do KDE
  --no-zram                  Nao instala/configura zram
  --no-node                  Nao instala nvm / Node LTS
  --no-vscode                Nao adiciona repositorio do VS Code
  --restore /caminho/backup Restaura configuracoes pessoais do KDE
  -h, --help                 Mostra esta ajuda

Avisos:
  - Execute no Konsole dentro da sessao KDE, sem 'sudo' antes de 'bash'.
  - Krema e VS Code usam repositorios externos: sao opcionais e pedem aceite.
  - O painel original e preservado quando a dock nao esta funcional.
  - O script nao instala kernels alternativos, nao mexe no boot nem desliga
    componentes essenciais de audio, rede, impressao, Bluetooth ou energia.
USAGE
}

while (($#)); do
  case "$1" in
    --profile) (($# >= 2)) || fail "Falta valor para --profile"; PROFILE="$2"; shift 2 ;;
    --dry-run) DRY_RUN=1; shift ;;
    --yes) ASSUME_YES=1; shift ;;
    --no-ppa) SKIP_PPA=1; shift ;;
    --no-panel) SKIP_PANEL=1; shift ;;
    --no-dock) SKIP_DOCK=1; shift ;;
    --no-zram) SKIP_ZRAM=1; shift ;;
    --no-node) SKIP_NODE=1; shift ;;
    --no-vscode) SKIP_VSCODE=1; shift ;;
    --restore) (($# >= 2)) || fail "Falta caminho para --restore"; RESTORE_DIR="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) fail "Opcao desconhecida: $1" ;;
  esac
done
[[ "$PROFILE" =~ ^(full|visual|dev)$ ]] || fail "Perfil invalido: $PROFILE"

# Execucao de leitura funciona sem Kubuntu (util para revisar o plano).
if ((DRY_RUN)); then
  cat <<EOF
[SIMULACAO] Nenhuma alteracao sera realizada.
Perfil: $PROFILE
Base: Kubuntu 26.04 LTS / Plasma 6 / Wayland
Visual: backup + Breeze Dark + Papirus + destaque roxo + wallpaper PNG
Dock: Krema (PPA externo sujeito a aceite; default = zoom Natural)
Painel: move painel existente para cima preservando widgets essenciais;
        so remove gerenciador de tarefas se Krema estiver funcionando
Performance: sessao vazia; opt-in Baloo; zram opcional sem destruir swap
Dev: JDK 21, Maven, Python, PHP, .NET 10, Compose;
     preserves Podman CLI if present, installs Docker Engine only without a conflict;
     nvm Node LTS e VS Code opcionais
Modo nao destrutivo: sem remocao de kernel, particoes, pacotes ou servicos vitais
Flags: no-ppa=$SKIP_PPA no-panel=$SKIP_PANEL no-dock=$SKIP_DOCK no-zram=$SKIP_ZRAM
EOF
  exit 0
fi

if ((EUID == 0)); then
  fail "Nao execute este arquivo com sudo. Use: bash kubuntu-hybrid-setup.sh"
fi

# --restore: restaura somente arquivos de usuario salvos por esta ferramenta.
if [[ -n "$RESTORE_DIR" ]]; then
  [[ -f "$RESTORE_DIR/.kubuntu-hybrid-backup" ]] || fail "Backup nao reconhecido: $RESTORE_DIR"
  info "Restaurando configuracoes do backup: $RESTORE_DIR"
  if command -v systemctl >/dev/null && systemctl --user is-active --quiet plasma-plasmashell.service; then
    systemctl --user stop plasma-plasmashell.service || warn "Nao foi possivel parar o Plasma"
  fi
  for name in kdeglobals kwinrc plasmashellrc plasma-org.kde.plasma.desktop-appletsrc \
              ksmserverrc baloofilerc kremarc; do
    if [[ -f "$RESTORE_DIR/config/$name" ]]; then
      mkdir -p "$HOME/.config"
      cp -a "$RESTORE_DIR/config/$name" "$HOME/.config/$name"
    fi
  done
  if command -v systemctl >/dev/null; then
    systemctl --user start plasma-plasmashell.service || warn "Faca logout e login para aplicar o backup"
  fi
  info "Configuracoes de usuario restauradas. Pacotes, repositorios e zram nao sao removidos."
  exit 0
fi

[[ -r /etc/os-release ]] || fail "Nao foi possivel detectar o sistema."
# shellcheck disable=SC1091
source /etc/os-release
[[ "${ID:-}" == "ubuntu" && "${VERSION_ID:-}" == "26.04" ]] || \
  fail "Este script foi criado para Kubuntu/Ubuntu 26.04. Detectado: ${PRETTY_NAME:-desconhecido}"
command -v plasmashell >/dev/null || fail "KDE Plasma nao encontrado."
if [[ "$PROFILE" != "dev" ]]; then
  [[ "${XDG_CURRENT_DESKTOP:-}" == *KDE* || "${XDG_CURRENT_DESKTOP:-}" == *Plasma* ]] || \
    fail "Execute na sessao grafica KDE (no Konsole)."
fi
SESSION="${XDG_SESSION_TYPE:-unknown}"
if [[ "$SESSION" != "wayland" ]]; then
  warn "Sessao $SESSION detectada. Krema requer Wayland; instalacao/abertura da dock sera ignorada."
  SKIP_DOCK=1
  SKIP_PANEL=1
fi

STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/kubuntu-hybrid-setup"
BACKUP="$HOME/kde-backup-hybrid-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$STATE_DIR" "$BACKUP/config"
touch "$BACKUP/.kubuntu-hybrid-backup"
LOG_FILE="$STATE_DIR/setup-$(date +%Y%m%d-%H%M%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1

info "Kubuntu Hybrid Setup $VERSION | perfil $PROFILE | sessao $SESSION"
info "Log: $LOG_FILE"
info "Backup: $BACKUP"

for f in kdeglobals kwinrc plasmashellrc plasma-org.kde.plasma.desktop-appletsrc \
         ksmserverrc baloofilerc kremarc; do
  if [[ -e "$HOME/.config/$f" ]]; then
    cp -a "$HOME/.config/$f" "$BACKUP/config/$f"
  fi
done
if [[ -e /etc/systemd/zram-generator.conf ]]; then
  sudo cp -a /etc/systemd/zram-generator.conf "$BACKUP/zram-generator.conf" \
    || warn "Nao foi possivel salvar configuracao anterior de zram"
fi

ask() {
  local question="$1" default="${2:-n}" reply=""
  if ((ASSUME_YES)); then info "$question -> sim (--yes)"; return 0; fi
  if [[ ! -t 0 ]]; then warn "$question -> nao (sem terminal interativo)"; return 1; fi
  if [[ "$default" == "s" ]]; then
    read -r -p "$question [S/n] " reply
    [[ -z "$reply" || "$reply" =~ ^[sSyY]$ ]]
  else
    read -r -p "$question [s/N] " reply
    [[ "$reply" =~ ^[sSyY]$ ]]
  fi
}

sudo -v || fail "Autenticacao sudo necessaria para instalar pacotes"

apt_install_available() {
  local packages=() missing=() p candidate
  for p in "$@"; do
    candidate="$(LC_ALL=C apt-cache policy "$p" 2>/dev/null | awk '/Candidate:/{print $2;exit}')"
    if [[ -n "$candidate" && "$candidate" != "(none)" ]]; then
      packages+=("$p")
    else
      missing+=("$p")
    fi
  done
  ((${#missing[@]} == 0)) || warn "Pacotes indisponiveis nos repositorios atuais: ${missing[*]}"
  if ((${#packages[@]})); then
    # Safety check: do not silently remove existing packages to satisfy dependencies.
    local simulation
    if ! simulation="$(LC_ALL=C apt-get --simulate install "${packages[@]}" 2>&1)"; then
      warn "APT simulation failed, skipping this group: $simulation"
      return 1
    fi
    if grep -Eq '^Remv ' <<< "$simulation"; then
      warn "Installation would remove existing packages. Skipping to protect the environment:"
      grep '^Remv ' <<< "$simulation" >&2
      return 1
    fi
    sudo apt-get install -y "${packages[@]}"
  fi
}

# Compatibilidade com VS Code ja instalado por pacote .deb/DEB822.
# Versao anterior (1.0.0) adicionava vscode.list mesmo com vscode.sources
# existente; APT rejeita duas entradas do mesmo repositorio com Signed-By diferente.
# So retira a entrada reconhecivel da versao anterior quando ha outra entrada.
VSCODE_LIST=/etc/apt/sources.list.d/vscode.list
if [[ -f "$VSCODE_LIST" ]] && \
   sudo grep -Fq 'signed-by=/etc/apt/keyrings/packages.microsoft.gpg' "$VSCODE_LIST"; then
  OTHER_CODE_SOURCE=0
  while IFS= read -r src; do
    if [[ "$src" != "$VSCODE_LIST" ]]; then OTHER_CODE_SOURCE=1; break; fi
  done < <(sudo grep -RIl 'packages.microsoft.com/repos/code' \
            /etc/apt/sources.list /etc/apt/sources.list.d/ 2>/dev/null || true)
  if ((OTHER_CODE_SOURCE)); then
    info "Repositorio VS Code duplicado da versao 1.0.0 detectado; corrigindo..."
    sudo cp -a "$VSCODE_LIST" "$BACKUP/vscode.list.pre-correction"
    sudo rm -- "$VSCODE_LIST"
    info "Entrada duplicada removida. Copia salva em: $BACKUP/vscode.list.pre-correction"
  fi
fi

info "Atualizando indice APT (sem full-upgrade automatico)..."
sudo apt-get update

if [[ "$PROFILE" == "visual" || "$PROFILE" == "full" ]]; then
  info "Instalando componentes visuais oficiais"
  apt_install_available papirus-icon-theme fonts-firacode fastfetch btop git curl wget \
                        ca-certificates python3 librsvg2-bin

  if command -v plasma-apply-colorscheme >/dev/null; then
    plasma-apply-colorscheme BreezeDark || warn "Aplique Breeze Dark pela interface do KDE"
  fi
  if command -v plasma-apply-icons >/dev/null; then
    plasma-apply-icons Papirus-Dark || warn "Aplique Papirus-Dark manualmente"
  elif command -v kwriteconfig6 >/dev/null; then
    kwriteconfig6 --file kdeglobals --group Icons --key Theme Papirus-Dark
  fi

  if command -v kwriteconfig6 >/dev/null; then
    # O KDE aceita cor de destaque no formato R,G,B; nao substitui o tema todo.
    kwriteconfig6 --file kdeglobals --group General --key AccentColor "139,92,246"
    kwriteconfig6 --file kdeglobals --group General --key AccentColorFromWallpaper false
    kwriteconfig6 --file kdeglobals --group KDE --key AnimationDurationFactor 0.75
    kwriteconfig6 --file kwinrc --group Plugins --key blurEnabled false
    kwriteconfig6 --file ksmserverrc --group General --key loginMode emptySession
  fi

  # Wallpaper original gerado localmente (nao baixa fotos de terceiros).
  WALL_DIR="$HOME/.local/share/wallpapers/Kubuntu-Hybrid"
  mkdir -p "$WALL_DIR"
  cat > "$WALL_DIR/hybrid.svg" <<'SVG'
<svg xmlns="http://www.w3.org/2000/svg" width="2560" height="1440" viewBox="0 0 2560 1440">
<defs>
  <linearGradient id="bg" x2="1" y2="1"><stop stop-color="#0a0d1b"/><stop offset="0.56" stop-color="#18132f"/><stop offset="1" stop-color="#090f1d"/></linearGradient>
  <radialGradient id="p"><stop stop-color="#8b5cf6" stop-opacity=".54"/><stop offset="1" stop-color="#8b5cf6" stop-opacity="0"/></radialGradient>
  <radialGradient id="b"><stop stop-color="#38bdf8" stop-opacity=".27"/><stop offset="1" stop-color="#38bdf8" stop-opacity="0"/></radialGradient>
  <linearGradient id="arc"><stop stop-color="#a78bfa" stop-opacity=".28"/><stop offset="1" stop-color="#38bdf8" stop-opacity=".06"/></linearGradient>
</defs>
<rect width="2560" height="1440" fill="url(#bg)"/>
<ellipse cx="1750" cy="550" rx="900" ry="780" fill="url(#p)"/>
<ellipse cx="730" cy="1100" rx="800" ry="800" fill="url(#b)"/>
<path d="M-350 1270 C450 630 970 1310 1810 660 S2670 90 3070 460" fill="none" stroke="url(#arc)" stroke-width="200" opacity=".8"/>
<path d="M-100 1350 C570 800 1100 1350 1920 740 S2840 270 3040 500" fill="none" stroke="#a78bfa" stroke-opacity=".21" stroke-width="3"/>
<path d="M-150 1250 C570 700 1050 1240 1840 620 S2620 100 3000 380" fill="none" stroke="#38bdf8" stroke-opacity=".16" stroke-width="3"/>
</svg>
SVG
  if command -v rsvg-convert >/dev/null; then
    rsvg-convert -w 2560 -h 1440 -o "$WALL_DIR/hybrid.png" "$WALL_DIR/hybrid.svg" \
      || warn "Falha ao converter wallpaper. SVG preservado."
  fi
  info "Wallpaper em $WALL_DIR"
fi

# Executa JS com busctl, que existe em systemd; nao depende de qdbus6.
plasma_js() {
  local js="$1" result
  if ! command -v busctl >/dev/null; then
    warn "busctl nao encontrado; layout do Plasma nao sera alterado automaticamente."
    return 1
  fi
  if ! result=$(busctl --user call org.kde.plasmashell /PlasmaShell \
         org.kde.PlasmaShell evaluateScript s "$js" 2>&1); then
    warn "Erro ao executar script no Plasma: $result"
    return 1
  fi
  info "Plasma: $result"
  return 0
}

if [[ "$PROFILE" == "visual" || "$PROFILE" == "full" ]]; then
  if [[ -f "$HOME/.local/share/wallpapers/Kubuntu-Hybrid/hybrid.png" ]]; then
    if ask "Aplicar o wallpaper roxo/azul gerado pelo script?" s; then
      WALL_URI="file://$HOME/.local/share/wallpapers/Kubuntu-Hybrid/hybrid.png"
      # json.dumps garante escaping correto de aspas/backslashes.
      WALL_JS=$(python3 -c 'import json,sys;print(json.dumps(sys.argv[1]))' "$WALL_URI")
      plasma_js "var ds=desktops(); for(var i=0;i<ds.length;i++){var d=ds[i];d.wallpaperPlugin='org.kde.image';d.currentConfigGroup=['Wallpaper','org.kde.image','General'];d.writeConfig('Image',$WALL_JS);}" \
        || warn "Wallpaper precisa ser aplicado manualmente em Configuracoes do Desktop"
    fi
  fi

  DOCK_WORKING=0
  if ((SKIP_DOCK == 0)); then
    if command -v krema >/dev/null; then
      info "Krema ja instalado."
    elif ((SKIP_PPA == 0)) && ask "Adicionar PPA externo ppa:isac322/krema e instalar dock animada?" n; then
      apt_install_available software-properties-common
      sudo add-apt-repository -y ppa:isac322/krema
      sudo apt-get update
      if [[ "$(LC_ALL=C apt-cache policy krema | awk '/Candidate:/{print $2;exit}')" != "(none)" ]]; then
        sudo apt-get install -y krema || warn "Falha ao instalar Krema; painel original preservado"
      else
        warn "Nao ha candidato de Krema para este ambiente. Painel original preservado."
      fi
    else
      warn "Krema nao instalado; pode instalar depois pelo PPA oficial do projeto."
    fi
    if command -v krema >/dev/null; then
      if ! pgrep -x krema >/dev/null; then
        info "Abrindo Krema com zoom Natural padrao..."
        (nohup krema >"$STATE_DIR/krema.log" 2>&1 < /dev/null &)
        sleep 3
      fi
      if pgrep -x krema >/dev/null; then
        DOCK_WORKING=1
        info "Krema em execucao. Zoom Natural/parabolico disponivel."
      else
        warn "Krema nao iniciou. Nao removeremos as tarefas do painel KDE."
      fi
    fi
  fi

  if ((SKIP_PANEL == 0)) && ask "Mover painel KDE para cima (tarefas removidas somente com Krema ativo)?" s; then
    # Identifica painel com systray; preserva menu, relogio, rede e outros widgets.
    # Remove gerenciadores de tarefas APENAS se Krema estiver rodando.
    PANEL_JS=$(cat <<'JS'
(function(){
  var target=null;
  for (var i=0;i<panelIds.length;i++) {
    var p=panelById(panelIds[i]);
    if (!p) continue;
    for (var j=0;j<p.widgetIds.length;j++) {
      var w=p.widgetById(p.widgetIds[j]);
      if (w && w.type === 'org.kde.plasma.systemtray') {target=p;break;}
    }
    if (target) break;
  }
  if (!target) { print('AVISO: painel com bandeja nao encontrado');return; }
  target.location='top';
  target.height=36;
  target.lengthMode='fill';
  target.hiding='none';
  if (__REMOVE_TASKS__) {
    var ids=target.widgetIds.slice();
    for (var k=0;k<ids.length;k++) {
      var a=target.widgetById(ids[k]);
      if (a && (a.type==='org.kde.plasma.icontasks' ||
                a.type==='org.kde.plasma.taskmanager')) a.remove();
    }
  }
  print('OK: painel superior ajustado; id='+target.id);
})();
JS
)
    if ((DOCK_WORKING)); then
      PANEL_JS="${PANEL_JS//__REMOVE_TASKS__/true}"
    else
      PANEL_JS="${PANEL_JS//__REMOVE_TASKS__/false}"
      warn "Dock ausente: mantido gerenciador de tarefas do Plasma."
    fi
    plasma_js "$PANEL_JS" || warn "Ajuste manual do painel necessario."
  fi
fi

if [[ "$PROFILE" == "dev" || "$PROFILE" == "full" ]]; then
  info "Instalando ambiente de desenvolvimento usando pacotes oficiais do Ubuntu (APT locale corrigido)"
  DEV_PKGS=(build-essential git curl wget ca-certificates unzip
      python3 python3-pip python3-venv pipx openjdk-21-jdk maven
      php-cli php-mbstring php-xml php-curl composer dotnet-sdk-10.0
      docker-compose-v2)
  if dpkg-query -W -f='${Status}' podman-docker 2>/dev/null | grep -q '^install ok installed$'; then
    warn "Podman Docker-compatible CLI is installed; Docker Engine will NOT be installed automatically (avoids conflicts)."
    warn "You can continue using Podman or explicitly migrate to Docker Engine later."
  else
    DEV_PKGS+=(docker.io)
  fi
  apt_install_available "${DEV_PKGS[@]}"

  if ((SKIP_NODE == 0)) && ask "Instalar NVM v0.41.0 e Node.js LTS?" s; then
    if [[ -f "$HOME/.nvm/nvm.sh" ]]; then
      info "NVM existente; nao sera sobrescrito."
    elif [[ -e "$HOME/.nvm" ]]; then
      warn "~/.nvm existe sem nvm.sh; revise manualmente, nada sera apagado."
    else
      git clone -q --depth 1 --branch v0.41.0 https://github.com/nvm-sh/nvm.git "$HOME/.nvm"
    fi
    if [[ -f "$HOME/.nvm/nvm.sh" ]]; then
      if ! grep -Fq '### kubuntu-hybrid nvm ###' "$HOME/.bashrc" 2>/dev/null; then
        cat >> "$HOME/.bashrc" <<'NVM'

### kubuntu-hybrid nvm ###
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
NVM
      fi
      export NVM_DIR="$HOME/.nvm"
      # shellcheck disable=SC1091
      source "$NVM_DIR/nvm.sh"
      nvm install --lts || warn "Node.js LTS nao foi instalado; verifique sua conexao"
      if nvm ls --no-colors | grep -q 'lts/'; then
        nvm alias default 'lts/*' || true
      fi
    fi
  fi

  if ((SKIP_VSCODE == 0)) && ask "Instalar VS Code (usando repositorio existente, se houver)?" n; then
    # Respeita o repositorio criado pelo instalador .deb oficial (vscode.sources).
    # Nunca cria uma segunda entrada para a mesma URL com outro Signed-By.
    if sudo grep -RIl 'packages.microsoft.com/repos/code' \
         /etc/apt/sources.list /etc/apt/sources.list.d/ 2>/dev/null | grep -q .; then
      info "Repositorio VS Code existente detectado; nao sera adicionado novamente."
    else
      info "Configurando repositorio oficial VS Code (formato DEB822)."
      apt_install_available gnupg
      sudo install -d -m 0755 /usr/share/keyrings
      TMP_KEY="$(mktemp)"
      if curl --fail --silent --show-error --location \
         https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > "$TMP_KEY"; then
        sudo install -m 0644 "$TMP_KEY" /usr/share/keyrings/microsoft.gpg
        ARCH="$(dpkg --print-architecture)"
        printf 'Types: deb\nURIs: https://packages.microsoft.com/repos/code\nSuites: stable\nComponents: main\nArchitectures: %s\nSigned-By: /usr/share/keyrings/microsoft.gpg\n' \
          "$ARCH" | sudo tee /etc/apt/sources.list.d/vscode.sources >/dev/null
      else
        warn "Falha ao baixar chave Microsoft; repositorio VS Code nao configurado."
      fi
      rm -f "$TMP_KEY"
    fi
    if sudo apt-get update; then
      sudo apt-get install -y code || warn "Nao foi possivel instalar VS Code"
    else
      warn "APT apresentou erro; VS Code nao foi instalado. Confira entradas duplicadas."
    fi
  fi

  if systemctl list-unit-files docker.service 2>/dev/null | grep -q '^docker.service' && \
       ask "Parar e desabilitar Docker na inicializacao (inicie sob demanda com sudo systemctl start docker)?" s; then
    sudo systemctl disable --now docker.service docker.socket || \
      warn "Nao foi possivel desabilitar servicos Docker"
  fi
fi

if ((SKIP_ZRAM == 0)) && ask "Configurar zram se nao houver dispositivo zram ativo? (requer reiniciar)" n; then
  if zramctl 2>/dev/null | grep -q '/dev/zram'; then
    info "zram existente detectado; nenhuma configuracao sera sobrescrita."
  elif [[ -e /etc/systemd/zram-generator.conf ]]; then
    warn "Arquivo zram-generator.conf existente; preservado sem sobrescrever."
  else
    apt_install_available systemd-zram-generator
    if dpkg-query -W -f='${Status}' systemd-zram-generator 2>/dev/null | grep -q 'install ok installed'; then
      printf '[zram0]\nzram-size = min(ram / 2, 4096)\n' | \
        sudo tee /etc/systemd/zram-generator.conf >/dev/null
      info "zram configurado com limite logico de 4 GiB; reinicie para ativar."
    fi
  fi
fi

if [[ "$PROFILE" == "visual" || "$PROFILE" == "full" ]] && command -v balooctl6 >/dev/null; then
  if ask "Desativar indexacao Baloo? (opcional, pode reduzir atividade em projetos grandes)" n; then
    balooctl6 disable || warn "Nao foi possivel desabilitar Baloo"
  fi
fi

info "------------------------------------------------------------"
info "Setup concluido. Backup: $BACKUP"
info "Log: $LOG_FILE"
info "Estado: $(free -h | awk '/Mem:/{print "RAM " $3 " usada; " $7 " disponivel"}')"
info "Verifique a dock em suas configuracoes (Natural, ~48px, zoom ~150%)."
info "Atalhos, widgets extras e preferencia exata do Krema podem variar por versao."
info "Faca logout/login para aplicar totalmente icones, cores e sessao vazia."
info "Para restaurar configs KDE: bash $(basename "$0") --restore '$BACKUP'"
if systemctl list-unit-files docker.service 2>/dev/null | grep -q '^docker.service'; then
  info "Para Docker Engine sob demanda: sudo systemctl start docker"
else
  info "Docker Engine nao instalado; verifique Podman com: podman --version"
fi
info "Nenhuma reinicializacao sera executada automaticamente."
