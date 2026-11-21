#!/usr/bin/env bash
# Linux Hybrid Installer 2.0: detecao automatica e perfis modulares.
# Suporte de instalacao: Ubuntu/Kubuntu 26.04 e Debian 13 com KDE Plasma.
set -Eeuo pipefail

PROJECT_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/platform.sh
source "$PROJECT_ROOT/lib/platform.sh"
# shellcheck source=lib/core.sh
source "$PROJECT_ROOT/lib/core.sh"
# shellcheck source=lib/install-status.sh
source "$PROJECT_ROOT/lib/install-status.sh"
# shellcheck source=lib/krema.sh
source "$PROJECT_ROOT/lib/krema.sh"
# shellcheck source=lib/premium.sh
source "$PROJECT_ROOT/lib/premium.sh"
# shellcheck source=lib/full-visual.sh
source "$PROJECT_ROOT/lib/full-visual.sh"
# shellcheck source=lib/dev.sh
source "$PROJECT_ROOT/lib/dev.sh"
# shellcheck source=lib/flatpak-discover.sh
source "$PROJECT_ROOT/lib/flatpak-discover.sh"
# shellcheck source=lib/common-desktop.sh
source "$PROJECT_ROOT/lib/common-desktop.sh"

DRY_RUN=0
YES=0
PROFILE=""
WITH_NODE=0
WITH_DOCKER=0
WITH_DOTNET=0
WITH_VSCODE=0
WITH_VISUAL_PRESETS=0
DETECT_ONLY=0
CHECK_SESSION=0
LIST_PROFILES=0
VERIFY_PROFILE=""
OS_RELEASE_FILE="/etc/os-release"

help_text() {
  cat <<'HELP'
Linux Hybrid Setup 2.0
Uso: bash install.sh [--profile premium|dev-fullstack|full] [opcoes]
  --profile premium   KDE visual + Krema (alias: visual)
  --profile dev-fullstack  Java, Python, PHP e ferramentas de desenvolvimento (alias: dev)
  --profile full      Premium + Dev Fullstack
  --dry-run           Mostrar plano SEM modificar arquivos ou usar sudo
  --detect            Detectar a distro sem instalar
  --check-session     Diagnosticar acesso a KDE Wayland e sudo sem instalar
  --status            Listar perfis de instalacao registrados e pacotes atuais
  --list-profiles     Alias de --status (nao lista perfis visuais KDE)
  --verify-profile N  Conferir pacotes de premium, dev-fullstack ou full
  --yes               Confirmar etapas de instalacao explicitamente
  --with-node         Incluir Node.js e npm dos repositorios da distro
  --with-docker       Incluir Docker (se nao houver podman-docker)
  --with-dotnet       Incluir .NET SDK 10 e feed Microsoft se necessario
  --with-vscode       Incluir VS Code e feed Microsoft se necessario
  --with-visual-presets  Registrar os 4 presets KDE (Premium/Full; nao ativa)
  --os-release FILE   Apenas com --dry-run: testar a deteccao com fixture
  -h, --help          Ajuda

Suportadas: Kubuntu/Ubuntu 26.04 e Debian 13 (KDE Plasma 6 / Wayland para Premium).
Outras distros: diagnosticadas, mas a instalacao fica BLOQUEADA.
Os extras dev sao opcionais para evitar adicionar repositorios sem necessidade.
Sem --profile, escolha interativa quando executado no terminal.
HELP
}

while (($#)); do
  case "$1" in
    --profile) (($#>=2)) || die "Falta perfil."; PROFILE="$2"; shift 2 ;;
    --dry-run) DRY_RUN=1; shift ;;
    --detect) DETECT_ONLY=1; shift ;;
    --check-session) CHECK_SESSION=1; shift ;;
    --status|--list-profiles) LIST_PROFILES=1; shift ;;
    --verify-profile)
      (($#>=2)) || die "Falta perfil para --verify-profile."
      VERIFY_PROFILE="$2"; shift 2 ;;
    --yes) YES=1; shift ;;
    --with-node) WITH_NODE=1; shift ;;
    --with-docker) WITH_DOCKER=1; shift ;;
    --with-dotnet) WITH_DOTNET=1; shift ;;
    --with-vscode) WITH_VSCODE=1; shift ;;
    --with-visual-presets) WITH_VISUAL_PRESETS=1; shift ;;
    --os-release) (($#>=2)) || die "Falta caminho."; OS_RELEASE_FILE="$2"; shift 2 ;;
    -h|--help) help_text; exit 0 ;;
    *) die "Argumento desconhecido: $1. Execute --help." ;;
  esac
done

if [[ "$OS_RELEASE_FILE" != "/etc/os-release" && "$DRY_RUN" -ne 1 ]]; then
  die "--os-release e exclusivo de --dry-run (na instalacao real usamos /etc/os-release)."
fi

# A deteccao pode mostrar distros ainda nao suportadas; instalar nao.
PLATFORM_OK=0
detect_platform "$OS_RELEASE_FILE" && PLATFORM_OK=1 || true
info "Sistema: ${DISTRO_NAME:-desconhecido}"
info "ID/versao: ${DISTRO_ID:-?} / ${DISTRO_VERSION:-?}"
info "Familia: ${DISTRO_FAMILY:-desconhecida}"
info "Backend: ${DISTRO_BACKEND:-nao homologado}"
if (( DETECT_ONLY )); then exit 0; fi
if (( LIST_PROFILES )); then
  install_status_display
  exit 0
fi
if [[ -n "$VERIFY_PROFILE" ]]; then
  case "$VERIFY_PROFILE" in premium|dev|dev-fullstack|full) ;; *) die "Perfil invalido em --verify-profile." ;; esac
  [[ "$VERIFY_PROFILE" != dev-fullstack ]] || VERIFY_PROFILE=dev
  record_file="$(install_status_root)/$VERIFY_PROFILE.state"
  prior_extras="$(install_status_read "$record_file" extras)"
  install_status_verify "$VERIFY_PROFILE" "${prior_extras:-none}"
  exit $?
fi
if (( CHECK_SESSION )); then
  print_graphical_diagnostics
  if kde_wayland_session_ok; then
    info "Sessao KDE Plasma Wayland acessivel para o instalador."
    exit 0
  fi
  warn "A instalacao Premium nao deve continuar neste shell."
  exit 1
fi
(( PLATFORM_OK )) ||
  die "Distribuicao/versao nao homologada. Apenas Ubuntu 26.04 e Debian 13 sao permitidos na v2."

if [[ -z "$PROFILE" ]]; then
  if (( DRY_RUN )); then
    PROFILE="full"
  else
    [[ -t 0 ]] || die "Informe --profile premium|dev-fullstack|full em execucao nao interativa."
    printf '\nEscolha o perfil:\n  1) Premium (visual KDE + Krema)\n  2) Dev Fullstack\n  3) Full (ambos)\n'
    read -r -p 'Opcao [1/2/3]: ' escolha
    case "$escolha" in 1) PROFILE=premium ;; 2) PROFILE=dev-fullstack ;; 3) PROFILE=full ;; *) die "Opcao invalida." ;; esac
  fi
fi
[[ "$PROFILE" != "visual" ]] || PROFILE="premium"
# Mantem "dev" como identificador interno para preservar registros dev.state antigos.
[[ "$PROFILE" != "dev-fullstack" ]] || PROFILE="dev"
case "$PROFILE" in premium|dev|full) ;; *) die "Perfil invalido: $PROFILE" ;; esac

if [[ "$PROFILE" == premium ]] && (( WITH_NODE || WITH_DOCKER || WITH_DOTNET || WITH_VSCODE )); then
  die "Extras de desenvolvimento exigem --profile dev-fullstack ou --profile full."
fi
if [[ "$PROFILE" == dev ]] && (( WITH_VISUAL_PRESETS )); then
  die "--with-visual-presets exige --profile premium ou --profile full."
fi

info "Perfil: $([[ "$PROFILE" == dev ]] && printf dev-fullstack || printf %s "$PROFILE")"
if (( DRY_RUN )); then
  info "SIMULACAO: nenhuma alteracao sera aplicada."
  if [[ "$PROFILE" != dev ]]; then
    info "Premium: Papirus, Breeze Dark, wallpaper, painel superior, Krema"
    info "Repositorio Krema: $([[ "$DISTRO_BACKEND" == debian ]] && echo 'OBS Debian_13' || echo 'PPA isac322/krema')"
  fi
  if [[ "$PROFILE" != premium ]]; then
    info "Dev Fullstack: Git, build-essential, Python 3, Java 21, Maven, PHP/Composer, ferramentas CLI"
    info "Extras: node=$WITH_NODE docker=$WITH_DOCKER dotnet=$WITH_DOTNET vscode=$WITH_VSCODE"
    [[ "$WITH_DOTNET" -eq 0 || "$DISTRO_BACKEND" != debian ]] ||
      info "Dotnet no Debian: pacote oficial packages-microsoft-prod.deb"
  fi
  info "Comum a todos: fontes Fira Code, JetBrains Mono e Inter; Flatpak, Discover e Flathub; atalhos Windows KDE."
  if (( WITH_VISUAL_PRESETS )); then
    info "Presets opcionais: Sweet, Layan e dois Breeze (somente registra, nao aplica; baixa temas de terceiros)."
  else
    info "Presets visuais nao sao registrados por padrao; use --with-visual-presets no Premium/Full."
  fi
  info "Durante instalacao real: confirmacao, backup local, simulacao APT e bloqueio de remocoes."
  exit 0
fi

[[ "$EUID" -ne 0 ]] || die "Nao execute com sudo bash. Use bash install.sh."
require_cmd sudo
require_cmd apt-get
require_cmd dpkg-query
require_cmd apt-cache
require_cmd tee
if [[ "$PROFILE" != dev ]]; then
  require_kde_wayland_session
fi
confirm "Instalar o perfil $PROFILE no sistema $DISTRO_NAME?" ||
  die "Instalacao cancelada pelo usuario."
sudo -v || die "Nao foi possivel obter permissao administrativa."

umask 077
prepare_state
backup_kde

# Registra etapas separadamente. Um "full" so e concluido quando os dois
# componentes (dev e premium) foram realmente executados e verificados.
REQUESTED_INSTALL="$PROFILE"
ACTIVE_STEP=""
REQUESTED_EXTRAS="$(install_status_requested_extras)"
install_failure_record() {
  local code="$1"
  if (( code != 0 )) && [[ -n "$ACTIVE_STEP" ]]; then
    install_status_write "$ACTIVE_STEP" falhou \
      "$([[ "$ACTIVE_STEP" == dev ]] && printf '%s' "$REQUESTED_EXTRAS" || printf '%s' none)" \
      instalador "Etapa interrompida; consulte o log $LOG_FILE" ||
      warn "Nao foi possivel registrar falha da etapa $ACTIVE_STEP."
    if [[ "$REQUESTED_INSTALL" == full ]]; then
      install_status_write full falhou "$REQUESTED_EXTRAS" instalador \
        "Instalacao interrompida; consulte o log $LOG_FILE" ||
        warn "Nao foi possivel registrar a falha do Full."
    fi
  fi
}
trap 'install_failure_record "$?"' EXIT

record_install_step() {
  local step="$1" extras="none" status
  [[ "$step" != dev ]] || extras="$REQUESTED_EXTRAS"
  if install_status_check "$step" "$extras"; then
    status=concluido
    info "Verificacao $step: $INSTALL_STATUS_PRESENT/$INSTALL_STATUS_TOTAL pacotes presentes."
  else
    status=parcial
    warn "Verificacao $step: ausentes $INSTALL_STATUS_MISSING."
  fi
  install_status_write "$step" "$status" "$extras" instalador "$INSTALL_STATUS_MISSING" ||
    die "Nao foi possivel registrar o status de $step."
  info "Status registrado: $step=$status."
}
run_install_step() {
  local step="$1"
  ACTIVE_STEP="$step"
  if [[ "$step" == dev ]]; then
    setup_developer
  else
    setup_premium
  fi
  # Registro inicial: os pacotes comuns serao conferidos novamente ao final.
  record_install_step "$step"
  ACTIVE_STEP=""
}
if [[ "$PROFILE" == dev || "$PROFILE" == full ]]; then
  run_install_step dev
fi
if [[ "$PROFILE" == premium || "$PROFILE" == full ]]; then
  run_install_step premium
fi
# Esta etapa instala fontes e Flatpak; os registros sao atualizados ao final.
ACTIVE_STEP="$REQUESTED_INSTALL"
setup_common_desktop
if [[ "$PROFILE" == full ]]; then
  setup_full_visual
fi
if (( WITH_VISUAL_PRESETS )); then
  confirm "Baixar e registrar Sweet, Layan e Breeze? O Layan executa o instalador do projeto terceiro como usuario normal." ||
    die "Instalacao de presets cancelada."
  bash "$PROJECT_ROOT/scripts/catalogo-visual-kde.sh" instalar-todos ||
    die "Falha ao registrar um ou mais presets visuais; consulte o log."
fi
if [[ "$PROFILE" == dev || "$PROFILE" == full ]]; then
  record_install_step dev
fi
if [[ "$PROFILE" == premium || "$PROFILE" == full ]]; then
  record_install_step premium
fi
if [[ "$PROFILE" == full ]]; then
  if install_status_check full "$REQUESTED_EXTRAS"; then
    full_status=concluido
  else
    full_status=parcial
  fi
  install_status_write full "$full_status" "$REQUESTED_EXTRAS" instalador \
    "$INSTALL_STATUS_MISSING" ||
    die "Falha ao registrar Full."
  info "Status registrado: full=$full_status."
fi
ACTIVE_STEP=""
trap - EXIT
info "Etapas finalizadas. Consulte: bash install.sh --status"
info "Para alternar a barra: bash scripts/perfis-kde.sh listar"
info "Faca logout/login caso o Plasma ou a Krema ainda nao reflitam as novas configuracoes."