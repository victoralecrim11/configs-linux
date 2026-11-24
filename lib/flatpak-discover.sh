#!/usr/bin/env bash
# Integracao idempotente do Flatpak/Flathub com a loja da distro.
# O remoto e configurado para o usuario atual, sem sudo e sem alterar remotos existentes.
flatpak_flathub_exists() {
  local scope="$1"
  flatpak remotes "$scope" --columns=name 2>/dev/null | grep -Fxq flathub
}
flatpak_store_packages() {
  if [[ "${DISTRO_BACKEND:-}" == cachyos ]]; then
    printf '%s\n' flatpak cachyos-packageinstaller
  else
    printf '%s\n' flatpak plasma-discover plasma-discover-backend-flatpak kde-config-flatpak
  fi
}
setup_flatpak_discover() {
  local pkg store="Discover"
  local -a packages
  mapfile -t packages < <(flatpak_store_packages)
  [[ "${DISTRO_BACKEND:-}" != cachyos ]] || store="CachyOS Package Installer"
  package_install_safe "Flatpak e $store" "${packages[@]}"
  for pkg in "${packages[@]}"; do
    has_package "$pkg" || die "Integracao Flatpak incompleta: pacote ausente: $pkg"
  done
  require_cmd flatpak
  if flatpak_flathub_exists --user; then
    info "Flathub ja configurado para este usuario; preservado."
  elif flatpak_flathub_exists --system; then
    info "Flathub ja configurado no sistema; preservado, sem duplicar remoto."
  else
    info "Adicionando Flathub para o usuario atual."
    flatpak remote-add --user --if-not-exists flathub \
      https://dl.flathub.org/repo/flathub.flatpakrepo ||
      die "Nao foi possivel adicionar Flathub ao Flatpak do usuario."
    flatpak_flathub_exists --user ||
      die "Flathub nao apareceu na lista de remotos do usuario apos a configuracao."
  fi
  info "Flatpak e Flathub configurados. Reabra $store; faca logout/login se necessario."
  if [[ "${DISTRO_BACKEND:-}" == cachyos ]]; then
    info "Package Installer: atualize para uma versao com suporte Flatpak e habilite a opcao nas configuracoes, se necessario."
    info "A disponibilidade da aba Flatpak nao foi verificada automaticamente."
  fi
}
