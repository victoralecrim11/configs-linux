# Solução de problemas

Diagnóstico de privilégios, Wayland, repositórios APT, Krema e recuperação de painéis. Faça backup antes de qualquer mudança.

### Verificar sessão gráfica e permissões antes de instalar

O perfil Premium precisa rodar **diretamente no Konsole aberto pela sessão KDE Plasma/Wayland**, como usuário comum. Abrir `su - victor` dentro do terminal pode atualizar os grupos (inclusive `sudo`), mas não cria uma sessão gráfica e pode eliminar variáveis como `XDG_SESSION_TYPE` e `WAYLAND_DISPLAY`.

```bash
cd ~/configs-linux

# Leitura de dados, sem sudo e sem instalar nada
bash ./install.sh --check-session

# Comandos de apoio
id -nG
sudo whoami
echo "$XDG_SESSION_TYPE"
echo "$XDG_CURRENT_DESKTOP"
echo "$WAYLAND_DISPLAY"
```

O diagnóstico deve reconhecer KDE, `wayland` e um socket Wayland acessível. Se `sudo whoami` retornar `root`, a permissão já funciona; não é preciso continuar modificando `/etc/sudoers`. Se o diagnóstico apontar variáveis ausentes ou sessão `tty`, feche o Konsole e abra um terminal **diretamente pelo menu do Plasma**, em uma sessão iniciada pelo SDDM. Se necessário, reinicie e escolha **Plasma (Wayland)** na tela de login.

Não contorne a checagem com `export XDG_SESSION_TYPE=wayland`: definir a variável não cria o socket nem oferece acesso ao Plasma. Nunca execute a configuração visual com `sudo bash install.sh`, `su -` ou `sudo su`.


### Solução para Krema ausente no Debian 13 (OBS)

O instalador Premium adiciona um repositório de terceiros (openSUSE Build Service) para instalar o Krema. Em versões anteriores, a fonte `/etc/apt/sources.list.d/krema-obs.list` podia ser criada com permissão `0600` devido ao `umask 077` do instalador. Isso impedia que o APT consultado pelo usuário normal encontrasse o pacote, embora o índice já tivesse sido baixado.

O instalador atualizado **corrige automaticamente a permissão para `0644` ao detectar a fonte existente** e cria novas fontes usando `install -m 0644`.

Para reparar sem repetir toda a instalação visual, em um Konsole aberto como usuário normal, após atualizar o clone:

```bash
cd ~/configs-linux
git pull --ff-only

# Corrige apenas a legibilidade da fonte OBS já existente
sudo chmod 0644 /etc/apt/sources.list.d/krema-obs.list

# Atualiza os índices e confirma a versão disponível
sudo apt-get update
apt-cache policy krema

# Instala apenas a dock (não reaplica wallpaper nem painel)
sudo apt-get install krema
command -v krema
```

Confirme que `apt-cache policy krema` mostra uma versão candidata antes de instalar. Se a fonte ainda não existir ou o APT relatar erro de assinatura/chave, **não crie outra fonte manualmente**: use `bash ./install.sh --profile premium` ou consulte os logs em `~/.local/state/linux-hybrid-v2/install-*.log`. Para aplicar também as configurações do Premium, rode novamente o instalador depois que a Krema estiver instalada; ele preserva backups, mas **pode alterar painel, tema e wallpaper**.


### Correção da sobreposição no Sweet: barra inferior + dock animada

**Validado na VM Kubuntu 26.04.1, KDE Plasma 6.6.6, Wayland e Krema 0.13.0 (17/11/2026).**

Na versão anterior do Sweet, o painel principal estava no topo, e a Krema inferior não tinha um painel Plasma adequado na posição tradicional. O novo layout utiliza **o painel nativo já existente** (com seus 7 widgets) no **rodapé, sempre visível**, e a **Krema centralizada na parte inferior** com modo **Always visible**. O instalador **não cria uma segunda barra vazia** e conserva os ícones/atalhos da dock.

A sobreposição foi verificada objetivamente pelo **KWin** após maximizar o Firefox: monitor **1920 × 1080**, área maximizada **1920 × 972** (108 px reservados na parte inferior pelos elementos da interface), sem a janela cobrir a área da barra/dock. Também foi realizada captura real da VM. A posição e aparência exatas podem variar conforme resolução, escala, plugins e versão do Krema; **janelas em fullscreen exclusivo** podem cobrir painéis intencionalmente.

**Em uma instalação já configurada com Sweet e Krema:**

```bash
cd ~/configs-linux
git pull --ff-only
bash scripts/corrigir-sweet-barra.sh status
bash scripts/corrigir-sweet-barra.sh aplicar --salvar
bash scripts/corrigir-sweet-barra.sh testar
```

O comando `aplicar --salvar` executa as seguintes ações:

1. Salva um **backup local** dos arquivos de painel, Plasma Shell, tema e Krema em `~/.local/share/linux-hybrid/backups/sweet-barra/`.
2. Localiza o painel KDE principal dinamicamente pela marca `hybridRole=toolbar` ou widget de bandeja (não depende do número de ID). Ajusta-o para **inferior, 36 px, largura total, sempre visível**, mantendo seus widgets.
3. Remove **apenas** um painel auxiliar eventualmente criado pelo script de testes, caso esteja marcado `hybridRole=sweet-krema-reservation`. Não remove painéis do usuário.
4. Reabre a Krema em `VisibilityMode=0` (sempre visível), `Edge=1` (inferior) e `FloatingMarginReference=0`, preservando seus apps fixados e a animação de ampliação.
5. Atualiza o snapshot `sweet` com `--recursos --dock on`. A versão anterior do Sweet fica arquivada em `~/.local/share/linux-hybrid/profiles/.historico/`; **`hybrid-premium` permanece intacto**.

Os comandos `status` e `testar` são apenas de leitura; o script não deve ser executado com `sudo`. Execute somente em **KDE Plasma/Wayland**, com o **tema Sweet ativo** e o pacote Krema instalado. Ele **não instala** o Sweet, não altera pacotes do sistema e não substitui o instalador `install.sh`.

**Alternar/recuperar os perfis visuais:**

```bash
bash scripts/perfis-kde.sh listar
bash scripts/perfis-kde.sh aplicar sweet
bash scripts/perfis-kde.sh aplicar hybrid-premium
bash scripts/perfis-kde.sh restaurar-ultimo
```

Para aproveitar o layout em **outro computador**, primeiro instale o tema e a Krema, copie o snapshot local privadamente ou refaça a personalização e execute `aplicar --salvar`. Os snapshots não são publicados no GitHub.

> **Observação técnica:** a opção `ReserveScreenSpace` do Krema tem alterações ainda não lançadas no projeto. Por isso, não se baseie apenas nessa preferência para prever o comportamento. Verifique a **área útil real do KWin** quando houver problemas de sobreposição. A solução testada foi manter o painel KDE nativo inferior, com a dock configurada separadamente.


### Passo 7 — Recuperação se uma troca causar problemas

**Antes de cada aplicação**, o script cria um backup da configuração que estava ativa. Para restaurar o backup automático mais recente:

```bash
bash scripts/perfis-kde.sh restaurar-ultimo
```

Os backups ficam em `~/.local/share/linux-hybrid/profiles/.historico/`. A restauração é um novo processo de troca e gera outro backup; ela **não desinstala temas nem pacotes**. Se o Plasma não abrir, encerre a sessão e volte a entrar; em casos extremos, use um terminal TTY e restaure manualmente os arquivos respaldados. Não exclua o diretório de backups antes de confirmar o funcionamento.
