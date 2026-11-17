#!/usr/bin/env bash
# Linux Hybrid KDE Appearance Profiles v2.1
# Salva e aplica perfis nomeados de aparencia. Nao instala pacotes.
set -Eeuo pipefail
umask 077

CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}"
ROOT="$DATA_DIR/linux-hybrid/profiles"
HISTORY="$ROOT/.historico"
ACTIVE="$ROOT/.ativo"
LEGACY="$DATA_DIR/kubuntu-hybrid/perfis-alternancia"
PLASMA="plasma-org.kde.plasma.desktop-appletsrc"
AUTOSTART="autostart/com.bhyoo.krema.autostart.desktop"
FILES=("$PLASMA" plasmashellrc kdeglobals kwinrc ksplashrc kcmfonts kremarc "$AUTOSTART")
RESOURCES=(plasma/look-and-feel plasma/desktoptheme color-schemes aurorae/themes icons wallpapers fonts)

die() { printf 'ERRO: %s\n' "$*" >&2; exit 1; }
msg() { printf '%s\n' "$*"; }
usage() {
cat <<'HELP'
Gerenciador de perfis visuais KDE Plasma 6 (nao instala aplicativos)
Uso:
  bash scripts/perfis-kde.sh salvar NOME [--recursos] [--dock on|off|keep]
  bash scripts/perfis-kde.sh atualizar NOME [--recursos] [--dock on|off|keep]
  bash scripts/perfis-kde.sh listar
  bash scripts/perfis-kde.sh status
  bash scripts/perfis-kde.sh detalhes NOME
  bash scripts/perfis-kde.sh aplicar NOME [--dry-run]
  bash scripts/perfis-kde.sh restaurar-ultimo
  bash scripts/perfis-kde.sh importar-legado original|personalizada

Nomes: letras minusculas, numeros, _ e -; ate 40 caracteres.
Os perfis ficam no HOME do usuario, fora do repositorio publico.
Use --recursos para incluir temas, icones e wallpapers locais (pode ocupar espaco).
A aplicacao nao instala Krema, Sweet, temas, fontes ou widgets ausentes.
HELP
}
valid_name() { [[ "$1" =~ ^[a-z0-9][a-z0-9_-]{0,39}$ ]]; }
check_name() { valid_name "$1" || die "Nome invalido: $1 (use a-z, 0-9, _ e -)."; }
check_user() { [[ "$EUID" -ne 0 ]] || die "Execute como usuario normal, sem sudo."; }
check_kde() {
  [[ "${XDG_CURRENT_DESKTOP:-}" == *KDE* || "${XDG_CURRENT_DESKTOP:-}" == *Plasma* ]] ||
    die "Entre numa sessao KDE Plasma antes de salvar/aplicar."
}
prepare() { mkdir -p -- "$ROOT" "$HISTORY"; }
read_metadata() {
  local file="$1" key="$2"
  [[ -f "$file" ]] || return 0
  sed -n "s/^$key=//p" "$file" | head -n 1
}
dock_detect() {
  if [[ -f "$CONFIG_DIR/$AUTOSTART" ]] &&
    grep -q '^Hidden=true$' "$CONFIG_DIR/$AUTOSTART"; then
    echo off
  elif pgrep -x -u "$(id -u)" krema >/dev/null 2>&1; then
    echo on
  elif command -v krema >/dev/null 2>&1; then
    echo on
  else
    echo keep
  fi
}
capture() {
  local dir="$1" dock="$2" assets="$3" kind="$4" rel
  mkdir -p -- "$dir/config"
  printf '%s\n' "${FILES[@]}" > "$dir/tracked.txt"
  for rel in "${FILES[@]}"; do
    if [[ -L "$CONFIG_DIR/$rel" ]]; then
      printf 'ERRO: arquivo KDE e um symlink: %s\n' "$CONFIG_DIR/$rel" >&2
      return 1
    fi
    if [[ -f "$CONFIG_DIR/$rel" ]]; then
      mkdir -p -- "$(dirname -- "$dir/config/$rel")"
      cp -p -- "$CONFIG_DIR/$rel" "$dir/config/$rel" || return 1
    fi
  done
  if [[ "$assets" == 1 ]]; then
    for rel in "${RESOURCES[@]}"; do
      if [[ -d "$DATA_DIR/$rel" && ! -L "$DATA_DIR/$rel" ]]; then
        mkdir -p -- "$(dirname -- "$dir/resources/$rel")"
        cp -a -- "$DATA_DIR/$rel" "$dir/resources/$rel" || return 1
      fi
    done
  fi
  {
    printf 'format=1\ncreated=%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    printf 'user_home=%s\ndock=%s\nkind=%s\n' "$HOME" "$dock" "$kind"
    printf 'resources=%s\n' "$assets"
  } > "$dir/info"
  : > "$dir/.snapshot"
}
save_profile() {
  local name="$1" update="$2" assets="$3" dock="$4" dir tmp old=""
  check_user; check_kde; check_name "$name"
  [[ -s "$CONFIG_DIR/$PLASMA" ]] ||
    die "O Plasma ainda nao criou o painel; entre no KDE e tente novamente."
  prepare
  dir="$ROOT/$name"
  if [[ -e "$dir" && "$update" == 0 ]]; then
    die "Perfil '$name' ja existe. Use atualizar $name para nova versao com historico."
  fi
  [[ ! -L "$dir" ]] || die "Perfil nao pode ser um link simbolico."
  if [[ "$dock" == auto ]]; then dock="$(dock_detect)"; fi
  tmp="$(mktemp -d "$ROOT/.novo-XXXXXXXX")"
  if ! capture "$tmp" "$dock" "$assets" local; then
    rm -rf -- "$tmp"; die "Falha ao capturar arquivos KDE."
  fi
  if [[ -e "$dir" ]]; then
    old="$HISTORY/$name-$(date +%Y%m%d-%H%M%S)-$$"
    mv -- "$dir" "$old" || { rm -rf -- "$tmp"; die "Nao consegui preservar o perfil anterior."; }
  fi
  if ! mv -- "$tmp" "$dir"; then
    [[ -z "$old" ]] || mv -- "$old" "$dir" || true
    die "Nao foi possivel salvar o perfil '$name'."
  fi
  printf '%s\n' "$name" > "$ACTIVE"
  msg "Perfil '$name' salvo em $dir (dock=$dock; recursos=$assets)."
  [[ -z "$old" ]] || msg "Versao anterior preservada em $old"
}
profile_dir() {
  local name="$1"
  check_name "$name"
  local dir="$ROOT/$name"
  [[ -d "$dir" && ! -L "$dir" && -f "$dir/.snapshot" && -f "$dir/tracked.txt" ]] ||
    die "Perfil '$name' nao existe ou esta incompleto. Execute listar."
  printf '%s\n' "$dir"
}
list_profiles() {
  local dir name
  if [[ ! -d "$ROOT" ]]; then msg "Nenhum perfil visual salvo."; return; fi
  local found=0
  for dir in "$ROOT"/*; do
    [[ -d "$dir" && ! -L "$dir" && -f "$dir/.snapshot" ]] || continue
    name="${dir##*/}"
    valid_name "$name" || continue
    msg "$name (dock=$(read_metadata "$dir/info" dock))"
    found=1
  done
  (( found )) || msg "Nenhum perfil visual salvo."
}
status() {
  local active="nenhum"
  [[ ! -f "$ACTIVE" ]] || active="$(cat "$ACTIVE")"
  msg "Ultimo perfil registrado: $active (alteracoes manuais podem ter ocorrido)"
  msg "Dock Krema atual: $(dock_detect)"
  msg "Diretorio de perfis: $ROOT"
  list_profiles
}
details() {
  local dir
  dir="$(profile_dir "$1")"
  msg "Perfil: $1"
  cat "$dir/info"
  msg "Arquivos: $(find "$dir/config" -type f | wc -l)"
  if [[ -d "$dir/resources" ]]; then
    msg "Recursos locais: $(du -sh "$dir/resources" | cut -f1)"
  else
    msg "Recursos locais: nao incluidos"
  fi
}
copy_resources() {
  local dir="$1" rel
  [[ -d "$dir/resources" ]] || return 0
  for rel in "${RESOURCES[@]}"; do
    if [[ -d "$dir/resources/$rel" ]]; then
      mkdir -p -- "$DATA_DIR/$rel"
      # Nunca apaga, nem sobrescreve recursos ja instalados.
      cp -an -- "$dir/resources/$rel/." "$DATA_DIR/$rel/" ||
        die "Erro ao recuperar recursos de aparencia: $rel"
    fi
  done
}
restore_config() {
  local dir="$1" mode="${2:-restore}" rel
  for rel in "${FILES[@]}"; do
    # Dock keep nao deve modificar nem o estado atual de autostart.
    [[ "$rel" != "$AUTOSTART" || "$mode" != keep ]] || continue
    grep -Fxq -- "$rel" "$dir/tracked.txt" || continue
    mkdir -p -- "$(dirname -- "$CONFIG_DIR/$rel")"
    if [[ -f "$dir/config/$rel" && ! -L "$dir/config/$rel" ]]; then
      cp -p -- "$dir/config/$rel" "$CONFIG_DIR/$rel" || return 1
    else
      rm -f -- "$CONFIG_DIR/$rel" || return 1
    fi
  done
}
dock_switch() {
  local mode="$1" file="$CONFIG_DIR/$AUTOSTART"
  case "$mode" in
    off)
      if [[ -f "$file" ]] && ! grep -q '^X-Linux-Hybrid-Managed=true$' "$file" &&
        ! grep -q '^X-Kubuntu-Hybrid-Managed=true$' "$file"; then
        cp -p -- "$file" "$ROOT/.krema-autostart-user.desktop"
      fi
      mkdir -p -- "$(dirname -- "$file")"
      printf '[Desktop Entry]\nType=Application\nName=Krema\nHidden=true\nX-Linux-Hybrid-Managed=true\n' > "$file"
      pkill -x -u "$(id -u)" krema 2>/dev/null || true
      ;;
    on)
      if [[ -f "$file" ]] &&
        { grep -q '^X-Linux-Hybrid-Managed=true$' "$file" ||
          grep -q '^X-Kubuntu-Hybrid-Managed=true$' "$file"; }; then
        if [[ -f "$ROOT/.krema-autostart-user.desktop" ]]; then
          cp -p -- "$ROOT/.krema-autostart-user.desktop" "$file"
        elif [[ -f "$LEGACY/autostart-anterior.desktop" ]]; then
          cp -p -- "$LEGACY/autostart-anterior.desktop" "$file"
        else
          rm -f -- "$file"
        fi
      fi
      if [[ "${XDG_SESSION_TYPE:-}" == wayland ]] && command -v krema >/dev/null 2>&1; then
        if ! pgrep -x -u "$(id -u)" krema >/dev/null 2>&1; then
          (nohup krema >/dev/null 2>&1 </dev/null &)
        fi
      else
        msg "AVISO: Krema nao iniciada (instale Krema e use uma sessao Wayland)."
      fi
      ;;
    keep) ;;
    *) die "Modo da dock invalido no snapshot: $mode" ;;
  esac
}
apply_profile() {
  local name="$1" dry="$2" custom_dir="${3:-}" dir dock origin backup
  check_user; check_name "$name"
  if [[ -n "$custom_dir" ]]; then
    [[ -d "$custom_dir" && ! -L "$custom_dir" && -f "$custom_dir/.snapshot" ]] ||
      die "Backup de recuperacao invalido."
    dir="$custom_dir"
  else
    dir="$(profile_dir "$name")"
  fi
  dock="$(read_metadata "$dir/info" dock)"
  case "$dock" in on|off|keep) ;; *) die "Snapshot com modo de dock invalido."; esac
  origin="$(read_metadata "$dir/info" user_home)"
  msg "Aplicar '$name': KDE Plasma, cores, efeitos e dock=$dock"
  [[ -z "$origin" || "$origin" == "$HOME" ]] ||
    msg "AVISO: perfil salvo em outro HOME ($origin); revise caminhos de wallpaper/widgets."
  if [[ "$dry" == 1 ]]; then
    msg "SIMULACAO: arquivos gerenciados:"; cat "$dir/tracked.txt"
    msg "SIMULACAO: nenhum arquivo alterado."; return 0
  fi
  check_kde
  command -v systemctl >/dev/null 2>&1 || die "systemctl nao encontrado."
  systemctl --user is-active --quiet plasma-plasmashell.service ||
    die "Plasma Shell nao esta ativo via systemd; nenhuma alteracao realizada."
  prepare
  local rel
  for rel in "${FILES[@]}"; do
    [[ ! -L "$CONFIG_DIR/$rel" ]] ||
      die "Arquivo de configuracao e um symlink ($CONFIG_DIR/$rel). Nao alterarei atalhos externos."
  done
  backup="$HISTORY/antes-$name-$(date +%Y%m%d-%H%M%S)-$"
  capture "$backup" "$(dock_detect)" 0 rollback
  msg "Backup automatico: $backup"
  copy_resources "$dir"
  systemctl --user stop plasma-plasmashell.service ||
    die "Falha ao parar o Plasma; configuracoes originais preservadas."
  if ! restore_config "$dir" "$dock"; then
    msg "Falha ao restaurar; tentando reverter..."
    restore_config "$backup" || true
    systemctl --user start plasma-plasmashell.service || true
    die "Restauracao interrompida; veja backup: $backup"
  fi
  if ! systemctl --user start plasma-plasmashell.service; then
    msg "Plasma nao iniciou; tentando reverter..."
    restore_config "$backup" || true
    systemctl --user start plasma-plasmashell.service || true
    die "Nao foi possivel ativar o perfil; backup: $backup"
  fi
  dock_switch "$dock"
  printf '%s\n' "$name" > "$ACTIVE"
  msg "Perfil '$name' aplicado. Saia e entre na sessao caso temas/efeitos nao atualizem."
}
restore_latest() {
  local folder last=""
  [[ -d "$HISTORY" ]] || die "Nenhum backup de seguranca existe."
  for folder in "$HISTORY"/antes-*; do
    [[ -d "$folder" && ! -L "$folder" && -f "$folder/.snapshot" ]] || continue
    if [[ -z "$last" || "$folder" -nt "$last" ]]; then last="$folder"; fi
  done
  [[ -n "$last" ]] || die "Nenhum backup automatico encontrado."
  msg "Restaurando configuracoes de: $last"
  apply_profile recuperado 0 "$last"
}
import_legacy() {
  local name="$1" source_dir dst tmp rel dock
  check_user; check_name "$name"
  case "$name" in original) dock=off ;; personalizada) dock=on ;; *)
    die "Importacao legada disponivel apenas para original ou personalizada." ;;
  esac
  source_dir="$LEGACY/$name"
  [[ -f "$source_dir/.snapshot" ]] ||
    die "Snapshot legado nao encontrado: $source_dir"
  prepare
  dst="$ROOT/$name"
  [[ ! -e "$dst" ]] ||
    die "O perfil '$name' ja existe; importacao nao ira sobrescreve-lo."
  tmp="$(mktemp -d "$ROOT/.import-XXXXXXXX")"
  mkdir -p -- "$tmp/config"
  : > "$tmp/tracked.txt"
  for rel in "$PLASMA" plasmashellrc kremarc; do
    printf '%s\n' "$rel" >> "$tmp/tracked.txt"
    [[ ! -f "$source_dir/$rel" ]] ||
      cp -p -- "$source_dir/$rel" "$tmp/config/$rel"
  done
  printf 'format=1\ncreated=%s\nuser_home=%s\ndock=%s\nkind=legacy\nresources=0\n' \
    "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$HOME" "$dock" > "$tmp/info"
  : > "$tmp/.snapshot"
  mv -- "$tmp" "$dst"
  msg "Perfil legado '$name' importado. Arquivos de tema extras nao estavam no backup antigo."
}

case "${1:---help}" in
  --help|-h|ajuda) usage ;;
  listar) list_profiles ;;
  status) status ;;
  detalhes)
    [[ "$#" == 2 ]] || die "Uso: detalhes NOME"
    details "$2" ;;
  salvar|atualizar)
    (( $# >= 2 )) || die "Informe o nome do perfil."
    operation="$1"; name="$2"; assets=0; dock=auto; shift 2
    while (($#)); do
      case "$1" in
        --recursos) assets=1; shift ;;
        --dock)
          (( $# >= 2 )) || die "--dock exige on|off|keep."
          dock="$2"; shift 2 ;;
        *) die "Opcao nao reconhecida: $1" ;;
      esac
    done
    case "$dock" in auto|on|off|keep) ;; *) die "--dock deve ser on|off|keep." ;; esac
    if [[ "$assets" == 1 ]]; then
      msg "AVISO: --recursos copia temas, icones e wallpapers de usuario. Pode consumir bastante espaco."
    fi
    if [[ "$operation" == atualizar ]]; then
      save_profile "$name" 1 "$assets" "$dock"
    else
      save_profile "$name" 0 "$assets" "$dock"
    fi
    ;;
  aplicar)
    [[ "$#" == 2 || ( "$#" == 3 && "$3" == --dry-run ) ]] ||
      die "Uso: aplicar NOME [--dry-run]"
    apply_profile "$2" "$([[ "${3:-}" == --dry-run ]] && echo 1 || echo 0)" ;;
  restaurar-ultimo)
    [[ "$#" == 1 ]] || die "Uso: restaurar-ultimo"
    restore_latest ;;
  importar-legado)
    [[ "$#" == 2 ]] || die "Uso: importar-legado original|personalizada"
    import_legacy "$2" ;;
  *) die "Comando desconhecido. Use --help." ;;
esac
