# Solução de problemas

Diagnóstico de privilégios, Wayland, repositórios APT, Krema e recuperação de painéis. Faça backup antes de qualquer mudança.

## Erros de permissão administrativa (\`sudo\` / \`sudoers\`)

### Sintomas e diagnóstico inicial

Estes procedimentos são para Debian 13 e Ubuntu/Kubuntu com \`sudo\`. O instalador \`install.sh\` deve ser executado como **usuário normal**; não use \`sudo bash install.sh\`.

| Mensagem ou situação | Causa provável | Verificação |
| --- | --- | --- |
| \`victor is not in the sudoers file\` | Grupo \`sudo\` ausente **na sessão atual** ou regra do \`sudoers\` desabilitada | \`id -nG\`, \`id victor\`, \`visudo -c\` |
| \`groups victor\` mostra \`sudo\`, mas \`groups\` não | Associação ao grupo atualizada no sistema, porém processos antigos mantêm a lista anterior | Compare \`id -nG\` e \`id victor\` |
| \`su -\` funciona, mas \`sudo su\` falha | \`su -\` autentica como root; \`sudo\` exige autorização do usuário atual | \`sudo whoami\` |
| \`sudo\` pede senha e retorna \`Sorry, try again\` | Senha do usuário incorreta, diferente da senha do root | Digite a senha de login do próprio usuário |
| \`sudo whoami\` funciona, mas o Premium acusa Wayland | Contexto gráfico não disponível naquele terminal, por exemplo após \`su - victor\` | \`bash install.sh --check-session\` |

Primeiro, **sem usar root**, execute no Konsole:

\`\`\`bash
whoami
id -nG                    # Grupos efetivos deste terminal
id "$USER"                # Grupos cadastrados para o usuario
getent group sudo         # Membros cadastrados do grupo sudo
sudo -k
sudo whoami
\`\`\`

O resultado esperado do último comando é \`root\`. O \`sudo\` normalmente solicita **a senha de login do usuário**, não a senha do root.

### Caso 1 — Usuário não cadastrado no grupo sudo

Se \`id "$USER"\` **não** mostrar \`sudo\`, e você souber a senha do administrador root, entre como root:

\`\`\`bash
su -
\`\`\`

Já no prompt \`root@...\`, execute (substitua \`victor\` pelo usuário correto, se necessário):

\`\`\`bash
apt update
apt install -y sudo
usermod -aG sudo victor
id victor
exit
\`\`\`

**Não use \`usermod -G sudo victor\` sem \`-a\`**: isso pode remover outras associações de grupo. Reinicie o computador completamente depois de alterar os grupos e abra um Konsole normal pelo KDE.

Se você não sabe a senha do root e não tem outra conta administradora, esses passos não poderão ser executados por um usuário sem privilégios. Use os meios autorizados de recuperação administrativa do Debian ou peça acesso ao responsável pelo computador.

### Caso 2 — Grupo sudo cadastrado, mas não ativo na sessão

Se \`id victor\` inclui \`sudo\`, porém \`id -nG\` **não**, as credenciais do terminal ou do \`systemd --user\` podem ter sido iniciadas antes da mudança de grupo. **Editar \`/etc/sudoers\` não corrige esse problema.**

A correção definitiva é **reiniciar o Debian**, não apenas encerrar a sessão gráfica. Depois do reinício, abra o Konsole pelo menu do Plasma e execute:

\`\`\`bash
id -nG
sudo whoami
\`\`\`

Como solução temporária, no Konsole de uma sessão já aberta:

\`\`\`bash
newgrp sudo
id -nG
sudo -k
sudo whoami
\`\`\`

\`newgrp sudo\` cria um novo shell com o grupo atualizado; os comandos seguintes precisam ser executados **nesse mesmo shell**. Ele não atualiza os processos KDE que já estavam em execução. Se solicitar senha do grupo ou falhar, use a reinicialização completa.

### Caso 3 — Verificar o arquivo sudoers (somente se necessário)

Se **tanto** \`id -nG\` quanto \`id victor\` incluem \`sudo\`, mas \`sudo whoami\` ainda informa que o usuário não está no sudoers, entre como root com \`su -\` e execute:

\`\`\`bash
visudo -c
visudo
\`\`\`

Dentro do \`visudo\`, procure esta regra:

\`\`\`text
%sudo ALL=(ALL:ALL) ALL
\`\`\`

Ela deve existir **sem \`#\` no início**. Se já estiver correta, não a duplique. No editor Nano, use \`Ctrl+W\` para procurar, \`Ctrl+O\` e Enter para salvar, e \`Ctrl+X\` para sair. O \`visudo\` valida a sintaxe e evita edições simultâneas. Confira novamente com \`visudo -c\`; não edite \`/etc/sudoers\` diretamente com um editor comum.

Se a regra está correta e o problema persiste, verifique se há outras regras ou restrições específicas antes de adicionar permissões extras. **Não use \`NOPASSWD: ALL\`, \`chmod 777\` nem regras irrestritas adicionais** como tentativa de resolver a falha.

### Caso 4 — sudo funciona, mas o instalador diz que falta Wayland

Um shell criado por \`su - victor\` pode ter o grupo \`sudo\` correto, porém perder as variáveis da sessão gráfica. Para o Premium/Full, use um **Konsole aberto diretamente pelo KDE**; nunca execute a instalação visual como root ou defina \`XDG_SESSION_TYPE=wayland\` manualmente.

\`\`\`bash
cd ~/configs-linux
bash install.sh --check-session
sudo whoami
bash install.sh --profile premium --dry-run
\`\`\`

Se o diagnóstico reconhecer KDE/Wayland e \`sudo whoami\` retornar \`root\`, execute o perfil desejado normalmente:

\`\`\`bash
bash install.sh --profile premium
# ou: bash install.sh --profile full
\`\`\`

**Os dois diagnósticos são independentes:** autorização administrativa do processo e acesso real à sessão KDE Wayland. Para outras causas, consulte as seções seguintes.


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
