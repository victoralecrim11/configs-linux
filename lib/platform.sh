#!/usr/bin/env bash
# Identifica distro e familia. O caminho customizado e usado apenas no dry-run.
detect_platform() {
  local release_file="${1:-/etc/os-release}"
  [[ -r "$release_file" ]] || { echo "Nao foi possivel ler $release_file" >&2; return 1; }
  local ID="" ID_LIKE="" VERSION_ID="" PRETTY_NAME="" chave valor
  # /etc/os-release e um arquivo de dados, nunca o execute com "source".
  # Evita executar codigo presente em fixtures fornecidas ao --dry-run.
  while IFS='=' read -r chave valor || [[ -n "$chave" ]]; do
    case "$chave" in
      ID|ID_LIKE|VERSION_ID|PRETTY_NAME)
        valor="${valor#\"}"; valor="${valor%\"}"
        valor="${valor#\'}"; valor="${valor%\'}"
        case "$chave" in
          ID) ID="$valor" ;;
          ID_LIKE) ID_LIKE="$valor" ;;
          VERSION_ID) VERSION_ID="$valor" ;;
          PRETTY_NAME) PRETTY_NAME="$valor" ;;
        esac
        ;;
    esac
  done < "$release_file"
  DISTRO_ID="${ID,,}"
  DISTRO_VERSION="$VERSION_ID"
  DISTRO_NAME="${PRETTY_NAME:-$DISTRO_ID $DISTRO_VERSION}"
  DISTRO_FAMILY="desconhecida"
  DISTRO_BACKEND=""
  case "$DISTRO_ID" in
    ubuntu)
      DISTRO_FAMILY="apt"
      [[ "$DISTRO_VERSION" == 26.04 || "$DISTRO_VERSION" == 26.04.* ]] && DISTRO_BACKEND="ubuntu"
      ;;
    debian)
      DISTRO_FAMILY="apt"
      [[ "$DISTRO_VERSION" == 13 || "$DISTRO_VERSION" == 13.* ]] && DISTRO_BACKEND="debian"
      ;;
    fedora) DISTRO_FAMILY="dnf" ;;
    arch|cachyos|manjaro|endeavouros) DISTRO_FAMILY="pacman" ;;
    opensuse*|sles) DISTRO_FAMILY="zypper" ;;
    *)
      case " $ID_LIKE " in
        *" debian "*|*" ubuntu "*) DISTRO_FAMILY="apt" ;;
        *" fedora "*|*" rhel "*) DISTRO_FAMILY="dnf" ;;
        *" arch "*) DISTRO_FAMILY="pacman" ;;
        *" suse "*) DISTRO_FAMILY="zypper" ;;
      esac
      ;;
  esac
  [[ -n "$DISTRO_BACKEND" ]]
}
