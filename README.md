# Configurações Linux — KDE Plasma multidistro

Scripts de personalização do **KDE Plasma 6** com perfis de instalação para **Kubuntu 26.04 LTS e Debian 13**, visual inspirado em Windows 11/Garuda/macOS e perfis visuais nomeados (v2.1). O projeto começou na VM `kubuntu-vm`.

## Comece aqui: instalador universal v2

O instalador `install.sh` **detecta automaticamente a distribuição** usando `/etc/os-release`. Na versão 2, a instalação é habilitada apenas no **Kubuntu/Ubuntu 26.04** e no **Debian 13 com KDE Plasma 6**. Fedora, CachyOS, Arch e openSUSE podem ser identificados, mas **não recebem instalações automáticas ainda**.

### Instalação do zero

Após instalar a distro e fazer o primeiro login no KDE Plasma, abra o Konsole:

```bash
sudo apt update
sudo apt install -y git
cd "$HOME"
git clone https://github.com/victoralecrim11/configs-linux.git
cd configs-linux
```

Se você já clonou o projeto, **não clone novamente**: use `cd ~/configs-linux`. Se seu clone antigo ainda está em `~/configs-linux-kubunutu`, pode continuar usando essa pasta; o nome local não precisa mudar.

### Diagnóstico, simulação e backup inicial

```bash
bash install.sh --detect
bash install.sh --profile full --dry-run
bash scripts/alternar-barra-kde.sh salvar-original
```

O último comando deve ser executado **antes de personalizar**, quando o painel padrão já existir. Isso preserva seu layout KDE original para alternância posterior. O `--dry-run` não modifica arquivos, não utiliza `sudo` e não adiciona repositórios.

### Escolha um dos perfis

| Perfil | Comando | O que instala |
|---|---|---|
| **Premium** (`visual`) | `bash install.sh --profile premium` | Breeze Dark, Papirus, wallpaper e painel superior com dock Krema |
| **Developer** | `bash install.sh --profile dev` | Git, compiladores, Python, Java 21, Maven, PHP, Composer e utilitários |
| **Full** | `bash install.sh --profile full` | Premium + Developer |

Sem `--profile`, o instalador exibe uma seleção interativa no Konsole. Para automações não interativas, informe o perfil e `--yes` explicitamente (inclusive quando autorizar repositórios de terceiros). **Nunca execute `sudo bash install.sh`.** O script solicita `sudo` somente quando necessário.

### Extras do perfil Developer (opcionais)

```bash
bash install.sh --profile full --with-node --with-docker --with-dotnet --with-vscode
```

- `--with-node`: instala Node.js e npm da distribuição.
- `--with-docker`: tenta Docker do repositório da distro, sem remover Podman automaticamente.
- `--with-dotnet`: instala SDK .NET 10; no Debian, usa o feed oficial Microsoft com confirmação.
- `--with-vscode`: usa o repositório oficial Microsoft para VS Code após confirmação.

Os extras **não** são instalados implicitamente no perfil Dev ou Full. Isso evita adicionar serviços e repositórios que você talvez não queira. Pacotes indisponíveis são informados e instalações APT com remoção de dependências são bloqueadas.

### Alternar KDE original ↔ Premium

```bash
bash scripts/alternar-barra-kde.sh status
bash scripts/alternar-barra-kde.sh original
bash scripts/alternar-barra-kde.sh personalizada
bash scripts/alternar-barra-kde.sh backup
```

A alternância controla o painel e a dock Krema, mas **não desinstala ferramentas Developer**. A reinstalação do Krema usa PPA no Ubuntu 26.04 e OBS assinado por chave dedicada no Debian 13. Em uma instalação nova, faça logout/login caso os efeitos ainda não estejam visíveis.

### Atualizar os scripts

```bash
cd "$HOME/configs-linux"
git pull --ff-only
```

Se aparecerem conflitos, verifique `git status` antes de atualizar. Os backups pessoais são armazenados no seu computador, fora do repositório público.

### Testes e segurança

```bash
bash tests/smoke.sh
bash install.sh --profile premium --dry-run
bash install.sh --profile dev --dry-run
```

Os testes verificam sintaxe e seleção de distro/perfil **sem instalar pacotes**. A primeira instalação real da v2 no Debian 13 e em Kubuntu 26.04 deve ser validada em VM ou ambiente descartável antes de usar na máquina principal. A lógica de pacotes é baseada em listas revisadas e fontes oficiais do projeto; o instalador **não pesquisa e executa comandos arbitrários da internet**.

### Projetos de suporte futuro

Fedora (DNF), CachyOS/Arch (Pacman/AUR) e openSUSE (Zypper/OBS) possuem detecção de família no módulo `lib/platform.sh`, mas **não possuem backend de instalação homologado**. O instalador interrompe a instalação nesses sistemas para proteger o ambiente.

---

## Gerenciador de perfis visuais KDE v2.1 — Original, Hybrid Premium, Sweet e outros

### Validação em ambiente real (17/11/2026)

Testado no **Kubuntu 26.04.1 LTS**, sessão **KDE Plasma/Wayland** com **Krema** ativa. Foi constatado que o ambiente corresponde ao **Hybrid Premium**: Kubuntu Dark, Papirus-Dark, destaque roxo, painel Plasma com configuração superior e dock Krema. O snapshot anterior existia somente no gerenciador legado como `personalizada`; **não existia nenhum perfil salvo no gerenciador KDE v2.1**.

Após revisar e executar os testes, foi criado localmente o perfil nomeado:

```bash
bash scripts/perfis-kde.sh salvar hybrid-premium --recursos --dock on
bash scripts/perfis-kde.sh detalhes hybrid-premium
bash scripts/perfis-kde.sh status
```

O snapshot guardou configurações e aproximadamente **183 MB de recursos locais de usuário**. Uma reaplicação real desse mesmo perfil também funcionou: Plasma Shell retornou a `active`, Krema permaneceu em execução, o conteúdo do arquivo de painel antes/depois continuou idêntico e foi criado um backup automático no histórico. Isso **não demonstra** compatibilidade integral de restauração entre distros ou monitores diferentes.

Os testes isolados `tests/smoke.sh` e `tests/perfis-kde-smoke.sh` foram executados na VM e passaram. A execução do GitHub Actions **[#28](https://github.com/victoralecrim11/configs-linux/actions/runs/44087441728)** também terminou com sucesso após corrigir erros no teste de perfis (duplicações/saída em pipe) e o identificador dos backups.

**Privacidade e portabilidade:** o diretório `~/.local/share/linux-hybrid/profiles/hybrid-premium/` permanece **somente no computador em que o perfil foi salvo**; o GitHub guarda o código que cria/aplica o perfil, **não** o snapshot real de configurações e arquivos pessoais. Faça uma cópia privada dele se quiser migrar para outra máquina, com os temas/widgets instalados no destino. Em outra máquina, `listar` não mostrará este perfil até que seja criado ou copiado.


O **`scripts/perfis-kde.sh`** permite salvar, listar, inspecionar e aplicar **vários perfis de aparência com nomes diferentes**, sem sobrescrever a configuração anterior. É independente dos perfis de **instalação** do `install.sh`:

- **Premium / Dev / Full:** instalam programas e preparam o sistema.
- **Original / hybrid-premium / sweet / outros:** são **fotografias locais da aparência do KDE**. Alternar entre elas **não** reinstala programas.

Os perfis ficam **somente no computador**, em `${XDG_DATA_HOME:-$HOME/.local/share}/linux-hybrid/profiles/`. Não são adicionados ao Git automaticamente e podem conter preferências pessoais, wallpapers ou fontes que você não deve publicar.

### Passo 1 — Preparar a distribuição, clonar o repositório e validar

Entre na sessão gráfica **KDE Plasma 6** e abra o Konsole. No Kubuntu 26.04 ou Debian 13:

```bash
sudo apt update
sudo apt install -y git

cd "$HOME"
git clone https://github.com/victoralecrim11/configs-linux.git
cd configs-linux
```

Se já existir um clone, use `cd ~/configs-linux && git pull --ff-only` (ou o nome da pasta local antiga, se não a renomeou). **Não execute o clone duas vezes**.

Confira o script sem modificar o sistema:

```bash
bash -n scripts/perfis-kde.sh
bash scripts/perfis-kde.sh --help
bash scripts/perfis-kde.sh listar
bash tests/perfis-kde-smoke.sh
```

O último comando executa testes **isolados**, com diretórios temporários e simulação de `systemctl`, sem alterar sua sessão KDE real.

### Passo 2 — Salvar o KDE original ANTES de personalizar

Em um KDE recém-instalado, antes de instalar temas, docks e widgets:

```bash
bash scripts/perfis-kde.sh salvar original --dock off
```

Isso guarda os painéis, widgets, preferências visuais e a indicação de dock desligada. **Não chame de `original` uma personalização já modificada**: se você fez alterações antes de capturar o padrão, elas serão consideradas parte desse perfil.

### Passo 3 — Configurar e salvar o Hybrid Premium

No Kubuntu 26.04 ou Debian 13, instale os componentes do nosso visual usando o instalador principal (preferencialmente teste primeiro numa VM):

```bash
bash install.sh --profile premium --dry-run
bash install.sh --profile premium
```

Depois que terminar, faça logout/login se necessário, confirme que o painel superior e o Krema estão como deseja e **salve um perfil separado**:

```bash
bash scripts/perfis-kde.sh salvar hybrid-premium --recursos --dock on
```

O nome pode ser diferente. `--dock on` faz o gerenciador solicitar a ativação da dock Krema sempre que o perfil for aplicado. `--recursos` inclui cópias dos recursos **locais do usuário** (temas, ícones, wallpapers e fontes), se existirem.

### Passo 4 — Montar o visual Sweet do vídeo e salvar como outro perfil

1. **Mantenha o perfil `hybrid-premium` salvo** antes de qualquer mudança.
2. Abra **Configurações do Sistema → Cores e temas → Tema global** (o nome pode variar conforme a versão do Plasma).
3. Escolha **Obter novos temas globais**, procure **Sweet** e confira a autoria, os requisitos e a compatibilidade com **Plasma 6** antes de instalar/aplicar. O nome exato e os componentes disponíveis no KDE Store podem mudar.
4. Ajuste estilo Plasma, decoração de janelas, ícones, fontes, papel de parede, transparência/desfoque, efeitos e disposição dos painéis, seguindo o vídeo. Verifique se os efeitos funcionam corretamente no seu hardware e sessão gráfica.
5. Salve os wallpapers que deseja transportar em `~/.local/share/wallpapers/`; arquivos que ficaram em `~/Downloads` ou em outros diretórios **não são incluídos** em `--recursos`.
6. Após concluir as mudanças, salve o novo visual:

```bash
bash scripts/perfis-kde.sh salvar sweet --recursos --dock keep
```

Use `--dock on` em vez de `keep` caso queira **ativar** o Krema com o Sweet; use `--dock off` se quiser **ocultá-lo** nesse perfil. `keep` mantém o estado atual da dock ao aplicar o perfil.

**Importante:** o script **não baixa nem instala automaticamente o tema Sweet**. Ele registra o estado **depois** que você configurá-lo no KDE. Também não captura pacotes de sistema, applets não instalados ou temas disponíveis somente em `/usr/share`. Para reproduzir em outra distro, instale os componentes faltantes antes de aplicar o snapshot.

### Ajuste validado: Sweet com dock centralizada e sempre visível

Em **17/11/2026**, a configuração foi aplicada e testada na VM **Kubuntu 26.04.1 / Plasma 6.6.6 / Wayland / Krema 0.13.0**. O tema global **Sweet já estava selecionado** (`kdeglobals → KDE → LookAndFeelPackage=Sweet`). O comportamento que fazia a dock desaparecer era `kremarc → General → VisibilityMode=2` (**Dodge windows**), e não a ocultação do painel superior do Plasma.

**Ajustes realizados apenas no Sweet:**

- **Krema inferior e centralizada**, com os aplicativos existentes preservados (`Edge=1`). O layout centralizado é nativo do Krema.
- **`VisibilityMode=0`**, que significa **Always visible** segundo o `krema.kcfg` do projeto oficial. O modo anterior `2` significa **Dodge windows**.
- **`ReserveScreenSpace=true`** salvo na configuração. **Atenção:** a funcionalidade de reserva de espaço aparece como *trabalho ainda não lançado* no README do Krema; não há garantia de que **Krema 0.13.0** respeite essa preferência quando uma janela maximizada encostar na dock.
- **Painel Plasma superior mantido**, com 36 px, visibilidade permanente, sem alterar os widgets. Não deslocar esse painel não compromete a centralização da Krema.
- O perfil anterior **`hybrid-premium`** foi preservado com **Kubuntu Dark + `VisibilityMode=2`**.

**Como preparar isso manualmente em outra instalação (após instalar Sweet e Krema):**

1. Faça login no Plasma 6 com **Wayland**, abra Configurações do Sistema → **Cores e temas → Tema global** e aplique o Sweet de preferência **sem importar o layout de painéis**. Se precisar, instale o tema Sweet adequado para Plasma 6 em *Obter novos temas globais*.
2. Na **Krema**, abra **Configurações → Comportamento / Visibilidade**, escolha **Sempre visível / Always visible** e mantenha a dock na **borda inferior**. Ela já usa centralização por padrão; deixe o alinhamento e a ordem dos apps como preferir.
3. Confira via Konsole (sem `sudo`):

```bash
kreadconfig6 --file kdeglobals --group KDE --key LookAndFeelPackage
kreadconfig6 --file kremarc --group General --key VisibilityMode
kreadconfig6 --file kremarc --group General --key Edge
```

O resultado esperado é `Sweet`, `0` e `1`, respectivamente. Se a interface do Krema não aplicar a opção, ajuste a preferência **com o Krema fechado**, depois abra-o novamente (não é necessário reiniciar toda a sessão):

```bash
pkill -x -u "$(id -u)" krema || true
kwriteconfig6 --file kremarc --group General --key VisibilityMode --type int 0
kwriteconfig6 --file kremarc --group General --key Edge --type int 1
nohup krema >/dev/null 2>&1 &
```

4. Depois de confirmar visualmente a aparência, registre um **perfil nomeado independente**, mantendo o Hybrid Premium:

```bash
cd ~/configs-linux
bash scripts/perfis-kde.sh salvar sweet --recursos --dock on
bash scripts/perfis-kde.sh detalhes sweet
```

Se o perfil Sweet já existir, **não use `salvar` novamente**; execute `atualizar sweet --recursos --dock on` para arquivar a versão anterior.

5. Para aplicar ou voltar aos estilos quando quiser:

```bash
bash scripts/perfis-kde.sh listar
bash scripts/perfis-kde.sh aplicar sweet --dry-run
bash scripts/perfis-kde.sh aplicar sweet
bash scripts/perfis-kde.sh aplicar hybrid-premium
```

O gerenciador **agora reinicia Krema automaticamente ao aplicar um perfil com `dock=on`**, para carregar o arquivo `kremarc` correspondente, inclusive ao alternar de um dock ligado para outro. Não sobrescreva os arquivos de backup em `~/.local/share/linux-hybrid/profiles/`. Uma troca completa de tema pode exigir logout/login para efeitos do KWin.

**Resultado na VM:** os perfis `hybrid-premium` e `sweet` coexistem. O Sweet foi salvo com os recursos locais (~203 MB) e reaplicado em sessão real; o Plasma continuou ativo e o processo Krema foi reiniciado, mantendo `VisibilityMode=0`. Os backups locais não foram publicados no GitHub. A combinação do modo "Always visible" com janelas maximizadas precisa de inspeção visual para confirmar se a versão instalada da Krema evita sobreposição.

### Passo 5 — Listar e alternar os perfis

```bash
# Ver nomes e opcoes
bash scripts/perfis-kde.sh listar
bash scripts/perfis-kde.sh status
bash scripts/perfis-kde.sh detalhes sweet

# Simular uma troca sem tocar no Plasma
bash scripts/perfis-kde.sh aplicar sweet --dry-run

# Alternar efetivamente
bash scripts/perfis-kde.sh aplicar original
bash scripts/perfis-kde.sh aplicar hybrid-premium
bash scripts/perfis-kde.sh aplicar sweet
```

Ao aplicar um perfil, o programa salva automaticamente o estado anterior, interrompe e reinicia **apenas o Plasma Shell** para recuperar seus arquivos de configuração e ajusta o estado da dock conforme o snapshot. **Pode ser necessário fazer logout/login** para que temas e efeitos de janela sejam atualizados. Faça a troca dentro do KDE, como usuário comum, **sem `sudo bash`**.

### Passo 6 — Atualizar um perfil existente sem perder a versão anterior

O comando `salvar` **recusa sobrescrever** um perfil que já existe. Se você melhorar seu tema Sweet e quiser registrá-lo novamente:

```bash
bash scripts/perfis-kde.sh atualizar sweet --recursos --dock keep
```

A versão antiga vai para `~/.local/share/linux-hybrid/profiles/.historico/`. Para criar outro estilo, use outro nome:

```bash
bash scripts/perfis-kde.sh salvar sweet-v2 --recursos --dock on
```

### Passo 7 — Recuperação se uma troca causar problemas

**Antes de cada aplicação**, o script cria um backup da configuração que estava ativa. Para restaurar o backup automático mais recente:

```bash
bash scripts/perfis-kde.sh restaurar-ultimo
```

Os backups ficam em `~/.local/share/linux-hybrid/profiles/.historico/`. A restauração é um novo processo de troca e gera outro backup; ela **não desinstala temas nem pacotes**. Se o Plasma não abrir, encerre a sessão e volte a entrar; em casos extremos, use um terminal TTY e restaure manualmente os arquivos respaldados. Não exclua o diretório de backups antes de confirmar o funcionamento.

### Passo 8 — Aproveitar backups da versão anterior

Se você já usava `alternar-barra-kde.sh`, o gerenciador novo pode importar snapshots locais antigos quando existirem:

```bash
bash scripts/perfis-kde.sh importar-legado personalizada
bash scripts/perfis-kde.sh importar-legado original
```

**Execute somente para os snapshots que existirem.** A importação não sobrescreve perfis com o mesmo nome. Os backups legados guardavam apenas o painel, `plasmashellrc` e `kremarc`: cores, fontes, recursos e temas adicionais **não estavam completos**, portanto é melhor criar um novo perfil com `salvar hybrid-premium --recursos --dock on` no ambiente já personalizado.

O script anterior `alternar-barra-kde.sh` continua disponível para compatibilidade, mas **prefira `perfis-kde.sh` para os novos perfis**. Não alterne entre os dois gerenciadores durante a mesma sessão, pois eles mantêm históricos e indicadores de perfil independentes.

### Quais arquivos e recursos entram no perfil?

- **Configuração KDE:** `plasma-org.kde.plasma.desktop-appletsrc`, `plasmashellrc`, `kdeglobals`, `kwinrc`, `ksplashrc`, `kcmfonts`, `kremarc` e override de autostart do Krema (se existir).
- **Com `--recursos`:** dados de usuário em `~/.local/share/plasma/look-and-feel`, `plasma/desktoptheme`, `color-schemes`, `aurorae/themes`, `icons`, `wallpapers` e `fonts`.
- **Não entra automaticamente:** pacotes instalados por APT, plugins externos do KWin, widgets ausentes, conteúdo de `/usr/share`, wallpapers fora dos diretórios listados ou fontes instaladas em outros caminhos.

Recursos incluídos são **recuperados somente quando faltam**: o gerenciador não sobrescreve nem apaga temas e ícones que já existem na máquina de destino. O backup pode ocupar bastante espaço dependendo dos pacotes de ícones/fontes. Perfis gravados com outro nome de usuário ou monitor podem conter caminhos absolutos e disposições de tela diferentes; revise antes de aplicar em outra máquina.

### Referência de comandos v2.1

| Comando | Ação |
| --- | --- |
| `salvar NOME [--recursos] [--dock on\|off\|keep]` | Cria perfil sem substituir outro |
| `atualizar NOME [--recursos] [--dock on\|off\|keep]` | Nova versão, arquivando a anterior |
| `listar` / `status` | Lista perfis / estado registrado |
| `detalhes NOME` | Exibe metadados e tamanho dos recursos |
| `aplicar NOME --dry-run` | Simula sem alterar |
| `aplicar NOME` | Aplica configurações e dock |
| `restaurar-ultimo` | Recupera o último backup automático |
| `importar-legado original\|personalizada` | Importa snapshot do gerenciador antigo |

Em todos os casos, prefixe os comandos com `bash scripts/perfis-kde.sh`, na raiz do repositório.

---

## Estrutura

```text
install.sh                       # Entrada unica v2; detecta a distro e o perfil
lib/
├── platform.sh                 # Deteccao de distro/versao/familia
├── core.sh                     # Backups, confirmacoes e seguranca APT
├── krema.sh                    # Krema: PPA Ubuntu 26.04 / OBS Debian 13
├── premium.sh                  # Tema KDE + wallpaper + dock
└── dev.sh                      # Pacotes Developer e extras opt-in
scripts/
├── kubuntu-hybrid-setup-v1.0.2.sh  # Instalador anterior para Kubuntu
├── perfil-barra-atual-kde.sh       # Configura painel + dock (KDE)
├── alternar-barra-kde.sh           # KDE original ↔ personalizado (legado)
└── perfis-kde.sh                  # Gestao de multiplos perfis visuais KDE
tests/
├── fixtures/                   # Exemplos de /etc/os-release
├── smoke.sh                    # Testes do instalador universal
└── perfis-kde-smoke.sh          # Testes isolados de perfis KDE
.github/workflows/smoke.yml     # Testes automaticos no GitHub
```

## Requisitos

- Kubuntu/Ubuntu 26.04 com KDE Plasma 6.
- Sessão KDE Wayland para recursos da dock.
- Bash, systemd e acesso administrativo **apenas quando solicitado pelo instalador**.
- Revise os scripts e seus repositórios externos antes da execução.

## Instalação manual antiga (script v1.0.2, legado)

No diretório raiz do repositório:

```bash
bash -n scripts/kubuntu-hybrid-setup-v1.0.2.sh
bash scripts/kubuntu-hybrid-setup-v1.0.2.sh --dry-run
bash scripts/kubuntu-hybrid-setup-v1.0.2.sh --profile visual
```

Outras opções úteis: `--profile dev`, `--profile full`, `--no-panel`, `--no-dock`, `--no-ppa`, `--no-zram` e `--help`. O perfil `full` é o padrão. **Não execute o instalador com `sudo bash`**: ele solicita `sudo` somente nas operações que precisam de privilégios.

O instalador cria automaticamente um backup `~/kde-backup-hybrid-AAAAMMDD-HHMMSS`. Para recuperar as configurações KDE de um backup:

```bash
bash scripts/kubuntu-hybrid-setup-v1.0.2.sh --restore "$HOME/kde-backup-hybrid-AAAAMMDD-HHMMSS"
```

Substitua o nome pelo diretório real de backup. Essa restauração não desinstala pacotes nem reverte todas as mudanças de sistema.

## Alternar perfis: KDE original ↔ personalizado

Use **um único script** para alternar os dois perfis (painel + dock), sempre no Konsole, **sem sudo**.

| Comando | Resultado |
| --- | --- |
| `bash scripts/alternar-barra-kde.sh status` | Exibe o perfil atual, a dock e os snapshots |
| `bash scripts/alternar-barra-kde.sh salvar-original` | Salva o KDE original antes da primeira personalização |
| `bash scripts/alternar-barra-kde.sh backup` | Salva seu visual personalizado atual |
| `bash scripts/alternar-barra-kde.sh original` | Retorna ao KDE tradicional e desativa a Krema, inclusive no próximo login |
| `bash scripts/alternar-barra-kde.sh personalizada` | Retorna ao painel superior com Krema e instala a dock caso necessário |

### Primeira configuração em um Kubuntu recém-instalado

Após iniciar o KDE Plasma pela primeira vez:

```bash
bash scripts/alternar-barra-kde.sh salvar-original
bash scripts/alternar-barra-kde.sh personalizada
```

Para alternar quantas vezes quiser:

```bash
bash scripts/alternar-barra-kde.sh original
bash scripts/alternar-barra-kde.sh personalizada
```

O script guarda snapshots em `${XDG_DATA_HOME:-$HOME/.local/share}/kubuntu-hybrid/perfis-alternancia/`, fora do repositório. Ele **não publica configurações pessoais no GitHub**.

### Se você já personalizou o KDE na VM

Faça primeiro:

```bash
bash scripts/alternar-barra-kde.sh backup
```

Como não foi preservado um snapshot do KDE original **antes** da personalização da VM, a primeira execução de `original` precisará **recriar os painéis padrão**, o que redefine os widgets e a disposição do Plasma. O backup personalizado continua recuperável. Trocar de perfil pode exigir logout/login, e o pacote Krema permanece instalado ao usar `original`.

O mecanismo também guarda backups de segurança a cada transição e desabilita a inicialização automática da Krema somente no perfil original, preservando a configuração de autostart existente do usuário, quando houver.

## Validação

```bash
for arquivo in scripts/*.sh; do bash -n "$arquivo" || exit 1; done
bash scripts/kubuntu-hybrid-setup-v1.0.2.sh --dry-run
```

A validação sintática e a simulação do instalador passaram na VM. **Não executei a restauração nem reinstalei o ambiente durante a preparação do repositório.**

## Observações

- Mudanças visuais podem exigir sair da sessão e entrar novamente.
- Recursos extras, incluindo o Krema e repositórios externos, dependem de disponibilidade e compatibilidade.
- Guarde backups fora do Git antes de experimentar novas alterações.

## Perfil da barra atualmente em uso (capturado em 16/11/2026)

O script `scripts/perfil-barra-atual-kde.sh` reflete a configuração verificada na VM: painel Plasma **superior**, 36 px, não flutuante, sempre visível; dock **Krema** com fundo opaco, atraso de ocultação de 1600 ms, exibição de 100 ms e lançadores Dolphin/Konsole/Configurações do Sistema.

```bash
bash scripts/perfil-barra-atual-kde.sh status     # apenas leitura
bash scripts/perfil-barra-atual-kde.sh backup     # salva copia local
bash scripts/perfil-barra-atual-kde.sh aplicar    # reaplica perfil visual
bash scripts/perfil-barra-atual-kde.sh restaurar "$HOME/.local/share/kubuntu-hybrid/perfis-barra/NOME-DO-BACKUP"
```

O comando `aplicar` preserva os widgets existentes e instala o Krema pelo PPA quando necessário no Kubuntu 26.04; ele não recria integralmente todos os arquivos de ícones e componentes visuais de terceiros.

**Segurança:** backups reais da sessão permanecem no computador, fora do repositório público, pois podem conter preferências e identificadores locais. Faça logout/login após aplicar o perfil para garantir que painel e Krema releiam as opções.

### Primeira execução em outro computador

O script `perfil-barra-atual-kde.sh` agora cria automaticamente `~/.config` e `${XDG_DATA_HOME:-$HOME/.local/share}/kubuntu-hybrid/perfis-barra` quando precisam ser utilizados. Os nomes são relativos ao usuário ativo, não à VM. **Não é necessário criar pastas manualmente.**

Após instalar Kubuntu, faça login no KDE Plasma para que ele crie `plasma-org.kde.plasma.desktop-appletsrc` e o painel padrão. Esse arquivo **não** deve ser criado vazio pelo script. Para confirmar, execute `bash scripts/perfil-barra-atual-kde.sh status`. Depois, `bash scripts/perfil-barra-atual-kde.sh aplicar` ajusta o painel existente e grava as preferências da dock. O comando `aplicar` verifica e, quando necessário, instala o Krema via PPA do projeto no Kubuntu 26.04, grava as preferências da dock e solicita sua inicialização. A instalação exige `sudo` e conexão com a internet. Não copie backups com IDs específicos da VM para o GitHub público.

Validação: sintaxe Bash e simulação de diretórios ausentes testadas com êxito em 16/11/2026, sem aplicar alterações na barra real.

### Instalação automática da dock Krema

No **Kubuntu 26.04 com Plasma 6 e Wayland**, executar:

```bash
bash scripts/perfil-barra-atual-kde.sh aplicar
```

Agora faz backup do perfil, instala a dock **Krema** se ainda não estiver instalada, configura painel e Krema, e inicia a dock caso esteja parada. Fonte de pacotes: PPA `ppa:isac322/krema`, conforme instruções do projeto `isac322/krema`.

Se quiser instalar/iniciar **somente** a dock, sem modificar o painel:

```bash
bash scripts/perfil-barra-atual-kde.sh instalar-dock
```

Requisitos de instalação: internet, `sudo`, `apt-get` e Kubuntu/Ubuntu 26.04 em sessão Wayland. A instalação não é executada quando `krema` já está disponível. Antes de instalar, o script simula o APT e bloqueia qualquer plano que remova pacotes. **Não instala versões para outras distribuições**. Preferências do Krema são aplicadas quando `aplicar` é executado; alterações podem exigir logout/login. O programa cria sua própria entrada de inicialização automática (autostart) quando instalado via pacote.

Na VM existente, foi validada a sintaxe e a detecção de instalação já presente (`Krema 0.13.0`), sem reinstalação; **o fluxo de instalação num Kubuntu novo ainda não foi executado**.
