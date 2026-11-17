#!/usr/bin/env bash
# Testes isolados: nao usa sudo e nao altera o Plasma real.
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT="$ROOT/scripts/perfis-kde.sh"
bash -n "$SCRIPT"
[[ "$EUID" -ne 0 ]] || { echo "Execute como usuario nao-root." >&2; exit 1; }
TMP="$(mktemp -d)"
trap 'rm -rf -- "$TMP"' EXIT
export HOME="$TMP/home"
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_CURRENT_DESKTOP=KDE
export XDG_SESSION_TYPE=wayland
export PATH="$TMP/mock:$PATH"
mkdir -p -- "$XDG_CONFIG_HOME" "$XDG_DATA_HOME" "$TMP/mock"

cat > "$TMP/mock/systemctl" <<'MOCK'
#!/usr/bin/env bash
case "$*" in
  *"is-active"*) exit 0 ;;
  *"stop"*) exit 0 ;;
  *"start"*)
    if [[ -n "${FAIL_FIRST_START:-}" && ! -f "$FAIL_FIRST_START" ]]; then
      touch "$FAIL_FIRST_START"; exit 1
    fi
    exit 0 ;;
esac
MOCK
printf '#!/bin/sh\nexit 1\n' > "$TMP/mock/pgrep"
printf '#!/bin/sh\nexit 0\n' > "$TMP/mock/pkill"
# Jamais execute a Krema real em um teste isolado: mocka o binario tambem.
printf '#!/bin/sh\nexit 0\n' > "$TMP/mock/krema"
# APIs KDE e KConfig falsas: testes nao acessam o painel real nem alteram ~/.config real.
cat > "$TMP/mock/busctl" <<'MOCKBUS'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$HOME/mock-busctl.log"
if [[ "$*" == *"target.location='top'"* ]]; then
  printf 's "KDE_DOCK_PANEL_OK:2:top"\n'
else
  printf 's "KDE_DOCK_PANEL_OK:2:bottom"\n'
fi
MOCKBUS
cat > "$TMP/mock/kwriteconfig6" <<'MOCKWRITE'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$HOME/mock-kwrite.log"
MOCKWRITE
chmod +x "$TMP/mock/"*

CONFIG="$XDG_CONFIG_HOME"
STATE="$XDG_DATA_HOME/linux-hybrid/profiles"

printf 'layout=original\n' > "$CONFIG/plasma-org.kde.plasma.desktop-appletsrc"
printf 'theme=Breeze\n' > "$CONFIG/kdeglobals"
bash "$SCRIPT" salvar original --dock off >/dev/null
[[ -f "$STATE/original/.snapshot" ]]
if bash "$SCRIPT" salvar original >/dev/null 2>&1; then
  echo '[ERRO] Salvou perfil existente sem atualizar' >&2; exit 1
fi
if bash "$SCRIPT" salvar ../escape >/dev/null 2>&1; then
  echo '[ERRO] Aceitou nome invalido' >&2; exit 1
fi

printf 'layout=sweet\n' > "$CONFIG/plasma-org.kde.plasma.desktop-appletsrc"
printf 'theme=Sweet\n' > "$CONFIG/kdeglobals"
printf 'someKWinEffect=true\n' > "$CONFIG/kwinrc"
mkdir -p -- "$XDG_DATA_HOME/color-schemes"
printf 'Sweet Accent\n' > "$XDG_DATA_HOME/color-schemes/sweet.colors"
bash "$SCRIPT" salvar sweet --recursos --dock keep >/dev/null
[[ -f "$STATE/sweet/resources/color-schemes/sweet.colors" ]]
output="$(bash "$SCRIPT" detalhes sweet)"
grep -q 'dock=keep' <<< "$output"
output="$(bash "$SCRIPT" listar)"
grep -q 'sweet' <<< "$output"

printf 'layout=manualmente-alterado\n' > "$CONFIG/plasma-org.kde.plasma.desktop-appletsrc"
output="$(bash "$SCRIPT" aplicar original --dry-run)"
grep -q SIMULACAO <<< "$output"
grep -q manualmente-alterado "$CONFIG/plasma-org.kde.plasma.desktop-appletsrc"

output="$(bash "$SCRIPT" aplicar original --dock off --dry-run)"
grep -q 'dock=off' <<< "$output"
output="$(bash "$SCRIPT" aplicar original --dock on --dry-run)"
grep -q 'dock=on' <<< "$output"
if bash "$SCRIPT" aplicar original --dock invalido --dry-run >/dev/null 2>&1; then
  echo '[ERRO] Aceitou modo de dock invalido.' >&2; exit 1
fi
bash "$SCRIPT" aplicar original >/dev/null
# Cada backup novo inclui data, horario e PID no nome.
backup_count=$(find "$STATE/.historico" -mindepth 1 -maxdepth 1 -type d -name 'antes-original-*' -printf '%f\n' | grep -Ec 'antes-original-[0-9]{8}-[0-9]{6}-[0-9]+' || true)
[[ "$backup_count" -gt 0 ]] || { echo '[ERRO] Backup com PID nao encontrado' >&2; exit 1; }
grep -q 'layout=original' "$CONFIG/plasma-org.kde.plasma.desktop-appletsrc"
[[ ! -e "$CONFIG/kwinrc" ]]
grep -q '^Hidden=true$' "$CONFIG/autostart/com.bhyoo.krema.autostart.desktop"

bash "$SCRIPT" aplicar sweet >/dev/null
# dock=keep precisa conservar o override de autostart existente.
grep -q '^Hidden=true$' "$CONFIG/autostart/com.bhyoo.krema.autostart.desktop"
grep -q 'theme=Sweet' "$CONFIG/kdeglobals"
grep -q 'layout=sweet' "$CONFIG/plasma-org.kde.plasma.desktop-appletsrc"
grep -q 'someKWinEffect=true' "$CONFIG/kwinrc"
[[ -f "$XDG_DATA_HOME/color-schemes/sweet.colors" ]]
output="$(bash "$SCRIPT" status)"
grep -q 'sweet' <<< "$output"

printf 'layout=sweet-atualizado\n' > "$CONFIG/plasma-org.kde.plasma.desktop-appletsrc"
bash "$SCRIPT" atualizar sweet --dock keep >/dev/null
grep -q 'layout=sweet-atualizado' "$STATE/sweet/config/plasma-org.kde.plasma.desktop-appletsrc"
find "$STATE/.historico" -maxdepth 1 -type d -name 'sweet-*' | grep -q sweet

printf 'layout=antes-da-falha\n' > "$CONFIG/plasma-org.kde.plasma.desktop-appletsrc"
export FAIL_FIRST_START="$TMP/falha"
if bash "$SCRIPT" aplicar original > "$TMP/falha.log" 2>&1; then
  echo '[ERRO] Deveria falhar quando Plasma nao reinicia' >&2; exit 1
fi
unset FAIL_FIRST_START
grep -q 'layout=antes-da-falha' "$CONFIG/plasma-org.kde.plasma.desktop-appletsrc"
printf 'layout=temporario\n' > "$CONFIG/plasma-org.kde.plasma.desktop-appletsrc"
bash "$SCRIPT" restaurar-ultimo >/dev/null
grep -q 'layout=antes-da-falha' "$CONFIG/plasma-org.kde.plasma.desktop-appletsrc"

mkdir -p -- "$XDG_DATA_HOME/kubuntu-hybrid/perfis-alternancia/personalizada"
printf 'layout=legado\n' > "$XDG_DATA_HOME/kubuntu-hybrid/perfis-alternancia/personalizada/plasma-org.kde.plasma.desktop-appletsrc"
touch "$XDG_DATA_HOME/kubuntu-hybrid/perfis-alternancia/personalizada/.snapshot"
bash "$SCRIPT" importar-legado personalizada >/dev/null
output="$(bash "$SCRIPT" detalhes personalizada)"
grep -q 'kind=legacy' <<< "$output"

# CRUD independente da sessao grafica real.
bash "$SCRIPT" criar novo --dock off >/dev/null
[[ -f "$STATE/novo/.snapshot" ]]
bash "$SCRIPT" duplicar novo nova-copia >/dev/null
[[ -f "$STATE/nova-copia/.snapshot" ]]
bash "$SCRIPT" renomear nova-copia tema-renomeado >/dev/null
[[ ! -e "$STATE/nova-copia" && -f "$STATE/tema-renomeado/.snapshot" ]]
output="$(bash "$SCRIPT" status)"
grep -q tema-renomeado <<< "$output"
if bash "$SCRIPT" excluir tema-renomeado </dev/null >/dev/null 2>&1; then
  echo '[ERRO] Exclusao sem confirmacao foi permitida.' >&2; exit 1
fi
bash "$SCRIPT" excluir tema-renomeado --yes >/dev/null
[[ ! -e "$STATE/tema-renomeado" ]]
output="$(bash "$SCRIPT" lixeira)"
grep -q 'tema-renomeado--excluido-' <<< "$output"
bash "$SCRIPT" restaurar-excluido tema-renomeado >/dev/null
[[ -f "$STATE/tema-renomeado/.snapshot" ]]
bash "$SCRIPT" renomear novo mais-novo >/dev/null
grep -qx mais-novo "$STATE/.ativo"
printf 'layout=novo-visual\n' > "$CONFIG/plasma-org.kde.plasma.desktop-appletsrc"
bash "$SCRIPT" editar mais-novo --dock off >/dev/null
grep -q '^layout=novo-visual$' "$STATE/mais-novo/config/plasma-org.kde.plasma.desktop-appletsrc"
output="$(bash "$SCRIPT" historico mais-novo)"
grep -q 'mais-novo--anterior-' <<< "$output"
version="$(printf '%s\n' "$output" | sed -n '1p')"
bash "$SCRIPT" restaurar-versao mais-novo "$version" >/dev/null
grep -q '^layout=antes-da-falha$' "$STATE/mais-novo/config/plasma-org.kde.plasma.desktop-appletsrc"
# Restaurar uma versao nao deve alterar arquivos do KDE em execucao.
grep -q '^layout=novo-visual$' "$CONFIG/plasma-org.kde.plasma.desktop-appletsrc"
if bash "$SCRIPT" restaurar-versao mais-novo '../etc/passwd' >/dev/null 2>&1; then
  echo '[ERRO] Identificador de versao inseguro aceito.' >&2; exit 1
fi
bash "$SCRIPT" excluir mais-novo --yes >/dev/null
[[ ! -e "$STATE/.ativo" ]]
grep -q '^layout=novo-visual$' "$CONFIG/plasma-org.kde.plasma.desktop-appletsrc"
bash "$SCRIPT" restaurar-excluido mais-novo >/dev/null
[[ -f "$STATE/mais-novo/.snapshot" ]]

# Um painel REAL sem gerenciador de tarefas nao pode desligar a unica dock.
printf '[Containments][9]\nplugin=org.kde.plasma.kickoff\n' > "$CONFIG/plasma-org.kde.plasma.desktop-appletsrc"
bash "$SCRIPT" salvar painel-sem-tarefas --dock on >/dev/null
if bash "$SCRIPT" aplicar painel-sem-tarefas --dock off --dry-run > /dev/null 2>&1; then
  echo '[ERRO] Aceitou dock off sem icontasks no painel.' >&2; exit 1
fi
output="$(bash "$SCRIPT" aplicar painel-sem-tarefas --dock on --dry-run)"
grep -q 'dock=on' <<< "$output"

# Toggle de dock respeita painel top/bottom e Krema auto-hide no mock.
bash "$SCRIPT" aplicar sweet --dock on >/dev/null
grep -q "target.location='top'" "$HOME/mock-busctl.log"
grep -q 'VisibilityMode --type int 1' "$HOME/mock-kwrite.log"
grep -q 'RevealTriggerLocation --type int 0' "$HOME/mock-kwrite.log"
grep -q 'HideDelay --type int 700' "$HOME/mock-kwrite.log"
bash "$SCRIPT" aplicar original --dock off >/dev/null
grep -q "target.location='bottom'" "$HOME/mock-busctl.log"
bash "$SCRIPT" dock on >/dev/null
bash "$SCRIPT" dock off >/dev/null
[[ -f "$STATE/.historico" ]] || [[ -d "$STATE/.historico" ]]
grep -q '^Hidden=true$' "$CONFIG/autostart/com.bhyoo.krema.autostart.desktop"

printf 'conteudo-externo\n' > "$TMP/externo"
rm -f -- "$CONFIG/kwinrc"
ln -s -- "$TMP/externo" "$CONFIG/kwinrc"
if bash "$SCRIPT" salvar symlink-test >/dev/null 2>&1; then
  echo '[ERRO] Capturou arquivo de configuracao simbolico' >&2; exit 1
fi
if bash "$SCRIPT" aplicar original >/dev/null 2>&1; then
  echo '[ERRO] Aplicou sobre arquivo de configuracao simbolico' >&2; exit 1
fi
grep -q conteudo-externo "$TMP/externo"
echo '[OK] Perfis KDE: salvar, listar, simular, alternar, rollback, atualizar, recursos, legado e symlinks.'
