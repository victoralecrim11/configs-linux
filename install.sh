#!/usr/bin/env bash
# Linux Hybrid Installer 2.0: detecao automatica e perfis modulares.
# Suporte de instalacao: Ubuntu/Kubuntu 26.04 e Debian 13 com KDE Plasma.
set -Eeuo pipefail

PROJECT_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/platform.sh
source "$PROJECT_ROOT/lib/platform.sh"
# shellcheck source=lib/core.sh
source "$PROJECT_ROOT/lib/core.sh"
# shellcheck source=lib/krema.sh
source "$PROJECT_ROOT/lib/krema.sh"
# shellcheck source=lib/premium.sh
source "$PROJECT_ROOT/lib/premium.sh"
# shellcheck source=lib/dev.sh
source "$PROJECT_ROOT/lib/dev.sh"

DRY_RUN=0
YES=0
PROFILE=""
WITH_NODE=0
WITH_DOCKER=0
WITH_DOTNET=0
WITH_VSCODE=0
DETECT_ONLY=0
OS_RELEASE_FILE="/etc/os-release"

help_text() {
  cat <<'HELP'
Linux Hybrid Setup 2.0
Uso: bash install.sh [--profile premium|dev|full] [opcoes]
  --profile premium   KDE visual + Krema (alias: visual)
  --profile dev       Java, Python, PHP e ferramentas basicas de desenvolvimento
  --profile full      Premium + Dev
  --dry-run           Mostrar plano SEM modificar arquivos ou usar sudo
  --detect            Detectar a distro sem instalar
  --yes               Confirmar etapas de instalacao explicitamente
  --with-node         Incluir Node.js e npm dos repositorios da distro
  --with-docker       Incluir Docker (se nao houver podman-docker)
  --with-dotnet       Incluir .NET SDK 10 e feed Microsoft se necessario
  --with-vscode       Incluir VS Code e feed Microsoft se necessario
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
    --yes) YES=1; shift ;;
    --with-node) WITH_NODE=1; shift ;;
    --with-docker) WITH_DOCKER=1; shift ;;
    --with-dotnet) WITH_DOTNET=1; shift ;;
    --with-vscode) WITH_VSCODE=1; shift ;;
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
(( PLATFORM_OK )) ||
  die "Distribuicao/versao nao homologada. Apenas Ubuntu 26.04 e Debian 13 sao permitidos na v2."

if [[ -z "$PROFILE" ]]; then
  if (( DRY_RUN )); then
    PROFILE="full"
  else
    [[ -t 0 ]] || die "Informe --profile premium|dev|full em execucao nao interativa."
    printf '\nEscolha o perfil:\n  1) Premium (visual KDE + Krema)\n  2) Developer\n  3) Full (ambos)\n'
    read -r -p 'Opcao [1/2/3]: ' escolha
    case "$escolha" in 1) PROFILE=premium ;; 2) PROFILE=dev ;; 3) PROFILE=full ;; *) die "Opcao invalida." ;; esac
  fi
fi
[[ "$PROFILE" != "visual" ]] || PROFILE="premium"
case "$PROFILE" in premium|dev|full) ;; *) die "Perfil invalido: $PROFILE" ;; esac

if [[ "$PROFILE" == premium ]] && (( WITH_NODE || WITH_DOCKER || WITH_DOTNET || WITH_VSCODE )); then
  die "Extras dev exigem --profile dev ou --profile full."
fi

info "Perfil: $PROFILE"
if (( DRY_RUN )); then
  info "SIMULACAO: nenhuma alteracao sera aplicada."
  if [[ "$PROFILE" != dev ]]; then
    info "Premium: Papirus, Breeze Dark, wallpaper, painel superior, Krema"
    info "Repositorio Krema: $([[ "$DISTRO_BACKEND" == debian ]] && echo 'OBS Debian_13' || echo 'PPA isac322/krema')"
  fi
  if [[ "$PROFILE" != premium ]]; then
    info "Dev: Git, build-essential, Python 3, Java 21, Maven, PHP/Composer, ferramentas CLI"
    info "Extras: node=$WITH_NODE docker=$WITH_DOCKER dotnet=$WITH_DOTNET vscode=$WITH_VSCODE"
    [[ "$WITH_DOTNET" -eq 0 || "$DISTRO_BACKEND" != debian ]] ||
      info "Dotnet no Debian: pacote oficial packages-microsoft-prod.deb"
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
  [[ "${XDG_SESSION_TYPE:-}" == "wayland" ]] ||
    die "O perfil Premium requer sessao KDE Plasma Wayland."
fi
confirm "Instalar o perfil $PROFILE no sistema $DISTRO_NAME?" ||
  die "Instalacao cancelada pelo usuario."
sudo -v || die "Nao foi possivel obter permissao administrativa."

umask 077
prepare_state
backup_kde
if [[ "$PROFILE" == dev || "$PROFILE" == full ]]; then
  setup_developer
fi
if [[ "$PROFILE" == premium || "$PROFILE" == full ]]; then
  setup_premium
fi
info "Instalacao 2.0 concluida. Para alternar a barra: bash scripts/alternar-barra-kde.sh original|personalizada"
info "Faca logout/login caso o Plasma ou a Krema ainda nao reflitam as novas configuracoes."
