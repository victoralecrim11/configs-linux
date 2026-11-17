#!/usr/bin/env bash
# Linux Hybrid KDE Appearance Profiles v2.1
# Salva e aplica perfis nomeados de aparencia. Nao instala pacotes.
set -Eeuo pipefail
umask 077

CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}"
ROOT="$DATA_DIR/linux-hybrid/profiles"
HISTORY="$ROOT/.historico"
TRASH="$ROOT/.lixeira"
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
  bash scripts/perfis-kde.sh criar NOME [--recursos] [--dock on|off|keep]
  bash scripts/perfis-kde.sh editar NOME [--recursos] [--dock on|off|keep]
  bash scripts/perfis-kde.sh duplicar ORIGEM DESTINO
  bash scripts/perfis-kde.sh renomear ANTIGO NOVO
  bash scripts/perfis-kde.sh excluir NOME [--yes]
  bash scripts/perfis-kde.sh lixeira
  bash scripts/perfis-kde.sh restaurar-excluido NOME
  bash scripts/perfis-kde.sh historico NOME
  bash scripts/perfis-kde.sh restaurar-versao NOME ID_VERSAO
  bash scripts/perfis-kde.sh comparar NOME
  bash scripts/perfis-kde.sh listar|status|detalhes NOME
  bash scripts/perfis-kde.sh aplicar NOME [--dry-run]
  bash scripts/perfis-kde.sh restaurar-ultimo
  bash scripts/perfis-kde.sh importar-legado original|personalizada

Aliases antigos: salvar=criar; atualizar=editar.
Editar significa capturar o visual KDE atual, NAO editar texto no terminal.
Excluir move o snapshot para uma lixeira local, sem mexer no visual ativo.
Nomes: letras minusculas, numeros, _ e -; ate 40 caracteres.
Use --recursos para copiar temas, icones e wallpapers locais (pode ocupar espaco).
O script nao instala programas nem fontes de terceiros; snapshots sao privados.
HELP
}
valid_name() { [[ "$1" =~ ^[a-z0-9][a-z0-9_-]{0,39}$ ]]; }
check_name() { valid_name "$1" || die "Nome invalido: $1 (use a-z, 0-9, _ e -)."; }
check_user() { [[ "$EUID" -ne 0 ]] || die "Execute como usuario normal, sem sudo."; }
check_kde() {
  [[ "${XDG_CURRENT_DESKTOP:-}" == *KDE* || "${XDG_CURRENT_DESKTOP:-}" == *Plasma* ]] ||
    die "Entre numa sessao KDE Plasma antes de salvar/aplicar."
}
prepare() { mkdir -p -- "$ROOT" "$HISTORY" "$TRASH"; }
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
  # O tema global pode definir os icones implicitamente (KConfig defaults),
  # mesmo sem [Icons] Theme em ~/.config/kdeglobals. Registra o tema efetivo
  # DENTRO do snapshot para restauracao fiel em outra instalacao.
  if command -v kreadconfig6 >/dev/null 2>&1 &&
     command -v kwriteconfig6 >/dev/null 2>&1; then
    local effective_icons
    effective_icons="$(kreadconfig6 --file kdeglobals --group Icons --key Theme 2>/dev/null || true)"
    if [[ -n "$effective_icons" && -f "$dir/config/kdeglobals" ]]; then
      kwriteconfig6 --file "$dir/config/kdeglobals" --group Icons --key Theme "$effective_icons" ||
        return 1
    fi
  fi
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
    old="$(unique_archive "$HISTORY" "$name" anterior)"
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
# IDs de historico incluem o nome e um sufixo exclusivo.
unique_archive() {
  local bucket="$1" name="$2" tag="$3" tmp
  tmp="$(mktemp -d "$bucket/$name--$tag-$(date +%Y%m%d-%H%M%S)-XXXXXXXX")" ||
    die "Nao foi possivel reservar diretorio para o historico."
  rmdir -- "$tmp" || die "Nao foi possivel preparar destino do historico."
  printf '%s\n' "$tmp"
}
# Confirmacao obrigatoria para excluir snapshot, inclusive em sessao nao interativa.
confirm_delete() {
  local name="$1" auto="$2" answer=""
  if [[ "$auto" == 1 ]]; then return 0; fi
  [[ -t 0 ]] || die "Exclusao cancelada: requer terminal para confirmar ou --yes."
  printf "Mover o perfil '%s' para a lixeira local? [s/N] " "$name" >&2
  read -r answer || die "Operacao cancelada."
  [[ "$answer" =~ ^[sSyY]$ ]] || die "Operacao cancelada."
}
clone_profile() {
  local source="$1" name="$2" dir temp
  check_user; check_name "$source"; check_name "$name"
  [[ "$source" != "$name" ]] || die "Origem e destino devem ser diferentes."
  dir="$(profile_dir "$source")"
  prepare
  [[ ! -e "$ROOT/$name" && ! -L "$ROOT/$name" ]] ||
    die "Perfil de destino '$name' ja existe."
  temp="$(mktemp -d "$ROOT/.duplicar-XXXXXXXX")"
  if ! cp -a -- "$dir/." "$temp/"; then
    rm -rf -- "$temp"; die "Nao consegui duplicar o perfil."
  fi
  # Historico e estado ativo permanecem inalterados.
  if ! mv -- "$temp" "$ROOT/$name"; then
    rm -rf -- "$temp"; die "Nao consegui finalizar a duplicacao."
  fi
  msg "Copia criada: '$source' -> '$name'. Visual atual inalterado."
}
rename_profile() {
  local source="$1" name="$2" from
  check_user; check_name "$source"; check_name "$name"
  [[ "$source" != "$name" ]] || die "Origem e destino devem ser diferentes."
  from="$(profile_dir "$source")"
  prepare
  [[ ! -e "$ROOT/$name" && ! -L "$ROOT/$name" ]] ||
    die "Perfil de destino '$name' ja existe."
  mv -- "$from" "$ROOT/$name" || die "Nao foi possivel renomear."
  if [[ -f "$ACTIVE" && "$(cat "$ACTIVE")" == "$source" ]]; then
    printf '%s\n' "$name" > "$ACTIVE"
  fi
  msg "Renomeado: '$source' -> '$name'. Visual atual inalterado."
}
delete_profile() {
  local name="$1" yes="$2" dir moved
  check_user; check_name "$name"
  dir="$(profile_dir "$name")"
  confirm_delete "$name" "$yes"
  prepare
  moved="$(unique_archive "$TRASH" "$name" excluido)"
  mv -- "$dir" "$moved" || die "Nao foi possivel mover para a lixeira."
  if [[ -f "$ACTIVE" && "$(cat "$ACTIVE")" == "$name" ]]; then
    rm -f -- "$ACTIVE"
  fi
  msg "Perfil '$name' movido para a lixeira: $moved"
  msg "Nenhum tema, janela, painel ou aplicativo foi alterado."
}
show_trash() {
  local folder found=0
  [[ -d "$TRASH" ]] || { msg "Lixeira vazia."; return; }
  for folder in "$TRASH"/*; do
    [[ -d "$folder" && ! -L "$folder" && -f "$folder/.snapshot" ]] || continue
    msg "${folder##*/}"
    found=1
  done
  (( found )) || msg "Lixeira vazia."
}
restore_deleted() {
  local name="$1" folder best="" candidate
  check_user; check_name "$name"
  prepare
  [[ ! -e "$ROOT/$name" && ! -L "$ROOT/$name" ]] ||
    die "Ja existe perfil ativo chamado '$name'. Renomeie-o antes de recuperar."
  for folder in "$TRASH/$name"--excluido-*; do
    [[ -d "$folder" && ! -L "$folder" && -f "$folder/.snapshot" ]] || continue
    if [[ -z "$best" || "$folder" -nt "$best" ]]; then best="$folder"; fi
  done
  [[ -n "$best" ]] || die "Nao foi encontrada uma copia excluida de '$name'."
  mv -- "$best" "$ROOT/$name" || die "Falha ao restaurar perfil excluido."
  msg "Perfil '$name' recuperado da lixeira. Para ativa-lo: aplicar $name"
}
show_history() {
  local name="$1" folder found=0
  check_name "$name"
  [[ -d "$HISTORY" ]] || { msg "Nenhuma versao arquivada de '$name'."; return; }
  for folder in "$HISTORY/$name"--* "$HISTORY/$name"-[0-9]*; do
    [[ -d "$folder" && ! -L "$folder" && -f "$folder/.snapshot" ]] || continue
    msg "${folder##*/}"
    found=1
  done
  (( found )) || msg "Nenhuma versao arquivada de '$name'."
}
restore_version() {
  local name="$1" version="$2" old temp current archived
  check_user; check_name "$name"
  # Aceita apenas um identificador de versao devolvido por "historico".
  [[ "$version" =~ ^[a-zA-Z0-9_-]+$ ]] ||
    die "Identificador invalido. Use historico NOME."
  if [[ "$version" != "$name--anterior-"* && ! "$version" =~ ^$name-[0-9]{8}-[0-9]{6}- ]]; then
    die "A versao nao pertence ao perfil '$name'."
  fi
  old="$HISTORY/$version"
  [[ -d "$old" && ! -L "$old" && -f "$old/.snapshot" && -f "$old/tracked.txt" ]] ||
    die "Versao historica nao encontrada: $version"
  current="$(profile_dir "$name")"
  prepare
  temp="$(mktemp -d "$ROOT/.restaurar-versao-XXXXXXXX")"
  if ! cp -a -- "$old/." "$temp/"; then
    rm -rf -- "$temp"; die "Falha ao preparar a versao historica."
  fi
  archived="$(unique_archive "$HISTORY" "$name" anterior)"
  mv -- "$current" "$archived" ||
    { rm -rf -- "$temp"; die "Nao foi possivel arquivar a versao atual."; }
  if ! mv -- "$temp" "$current"; then
    mv -- "$archived" "$current" || true
    rm -rf -- "$temp"
    die "Falha na restauracao. Tentativa de reversao concluida."
  fi
  msg "Snapshot do perfil '$name' restaurado para $version."
  msg "Versao substituida preservada em: $archived"
  msg "O KDE em execucao NAO foi modificado. Para ativar: aplicar $name"
}

compare_profile() {
  local name="$1" dir file key group actual stored value state
  check_name "$name"; dir="$(profile_dir "$name")"
  msg "Perfil: $name | Comparacao com o KDE atual"
  if ! command -v kreadconfig6 >/dev/null 2>&1; then
    die "kreadconfig6 e necessario para comparar temas e icones."
  fi
  for state in "Tema global|kdeglobals|KDE|LookAndFeelPackage" "Icones|kdeglobals|Icons|Theme" "Esquema de cores|kdeglobals|General|ColorScheme" "Krema visibilidade|kremarc|General|VisibilityMode"; do
    IFS='|' read -r value file group key <<< "$state"
    actual="$(kreadconfig6 --file "$CONFIG_DIR/$file" --group "$group" --key "$key" 2>/dev/null || true)"
    if [[ -f "$dir/config/$file" ]]; then
      stored="$(kreadconfig6 --file "$dir/config/$file" --group "$group" --key "$key" 2>/dev/null || true)"
    else stored="(arquivo ausente)"; fi
    printf '%s: ativo=[%s] salvo=[%s]\n' "$value" "$actual" "$stored"
  done
  if [[ -f "$dir/config/$PLASMA" ]] && cmp -s -- "$CONFIG_DIR/$PLASMA" "$dir/config/$PLASMA"; then
    msg "Painel: conteudo de arquivo identico ao snapshot."
  else
    msg "Painel: arquivo diferente (o Plasma pode reordenar metadados)."
  fi
  msg "Comparar nao altera nada. Use editar NOME para capturar a aparencia atual."
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
      cp -a --update=none -- "$dir/resources/$rel/." "$DATA_DIR/$rel/" ||
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
  local mode="$1" source_dir="${2:-}" file="$CONFIG_DIR/$AUTOSTART"
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
        # O Krema pode manter uma copia do KConfig em memoria. Reinicie o processo
        # em toda troca on->on para nao deixar o modo antigo da dock em uso.
        if pgrep -x -u "$(id -u)" krema >/dev/null 2>&1; then
          pkill -x -u "$(id -u)" krema 2>/dev/null || true
          local tentativa
          for tentativa in 1 2 3 4 5 6 7 8 9 10; do
            pgrep -x -u "$(id -u)" krema >/dev/null 2>&1 || break
            sleep 0.2
          done
          if pgrep -x -u "$(id -u)" krema >/dev/null 2>&1; then
            msg "AVISO: nao foi possivel encerrar Krema; faca logout/login para recarregar o perfil."
            return 0
          fi
          # A instancia anterior pode ter gravado preferencias ao encerrar.
          # Reaplicar o arquivo do perfil DEPOIS do encerramento.
          if [[ -n "$source_dir" ]]; then
            if [[ -f "$source_dir/config/kremarc" && ! -L "$source_dir/config/kremarc" ]]; then
              cp -p -- "$source_dir/config/kremarc" "$CONFIG_DIR/kremarc" ||
                die "Falha ao recarregar as preferencias da dock."
            else
              rm -f -- "$CONFIG_DIR/kremarc"
            fi
          fi
        fi
        (nohup krema >/dev/null 2>&1 </dev/null &)
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
  backup="$HISTORY/antes-$name-$(date +%Y%m%d-%H%M%S)-${BASHPID}"
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
  dock_switch "$dock" "$dir"
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
  salvar|atualizar|criar|editar)
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
    if [[ "$operation" == atualizar || "$operation" == editar ]]; then
      save_profile "$name" 1 "$assets" "$dock"
    else
      save_profile "$name" 0 "$assets" "$dock"
    fi
    ;;
  duplicar)
    [[ "$#" == 3 ]] || die "Uso: duplicar ORIGEM DESTINO"
    clone_profile "$2" "$3" ;;
  renomear)
    [[ "$#" == 3 ]] || die "Uso: renomear ANTIGO NOVO"
    rename_profile "$2" "$3" ;;
  excluir)
    [[ "$#" == 2 || ( "$#" == 3 && "$3" == --yes ) ]] ||
      die "Uso: excluir NOME [--yes]"
    delete_profile "$2" "$([[ "${3:-}" == --yes ]] && echo 1 || echo 0)" ;;
  lixeira)
    [[ "$#" == 1 ]] || die "Uso: lixeira"
    show_trash ;;
  restaurar-excluido)
    [[ "$#" == 2 ]] || die "Uso: restaurar-excluido NOME"
    restore_deleted "$2" ;;
  historico)
    [[ "$#" == 2 ]] || die "Uso: historico NOME"
    show_history "$2" ;;
  restaurar-versao)
    [[ "$#" == 3 ]] || die "Uso: restaurar-versao NOME ID_VERSAO"
    restore_version "$2" "$3" ;;
  comparar)
    [[ "$#" == 2 ]] || die "Uso: comparar NOME"
    compare_profile "$2" ;;
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
