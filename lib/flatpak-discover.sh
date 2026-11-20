#!/usr/bin/env bash
# Integracao idempotente do Flatpak/Flathub com o KDE Discover.
# O remoto e configurado para o usuario atual, sem sudo e sem alterar remotos existentes.
flatpak_flathub_exists() {
  local scope="$1"
  flatpak remotes "$scope" --columns=name 2>/dev/null | grep -Fxq flathub
}
setup_flatpak_discover() {
  local pkg
  apt_install_safe "Flatpak e Discover (APT)" \
    flatpak plasma-discover plasma-discover-backend-flatpak kde-config-flatpak
  for pkg in flatpak plasma-discover plasma-discover-backend-flatpak kde-config-flatpak; do
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
  info "Flatpak integrado ao Discover. Reinicie o Discover e faca logout/login para concluir a integracao da sessao."
}
