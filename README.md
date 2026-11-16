# Configurações Linux — Kubuntu 26.04 LTS

Scripts de personalização do **Kubuntu 26.04 LTS / KDE Plasma 6**, com visual inspirado em Windows 11, Garuda e dock no estilo macOS. Desenvolvidos e testados inicialmente na VM `kubuntu-vm`.

## Comece aqui: instalador universal v2

O instalador `install.sh` **detecta automaticamente a distribuição** usando `/etc/os-release`. Na versão 2, a instalação é habilitada apenas no **Kubuntu/Ubuntu 26.04** e no **Debian 13 com KDE Plasma 6**. Fedora, CachyOS, Arch e openSUSE podem ser identificados, mas **não recebem instalações automáticas ainda**.

### Instalação do zero

Após instalar a distro e fazer o primeiro login no KDE Plasma, abra o Konsole:

```bash
sudo apt update
sudo apt install -y git
cd "$HOME"
git clone https://github.com/victoralecrim11/configs-linux-kubunutu.git
cd configs-linux-kubunutu
```

Se você já clonou o projeto, **não clone novamente**: use `cd ~/configs-linux-kubunutu`.

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
cd "$HOME/configs-linux-kubunutu"
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

## Estrutura

```text
scripts/
├── kubuntu-hybrid-setup-v1.0.2.sh  # Setup visual / ambiente dev
├── perfil-barra-atual-kde.sh       # Instala/configura o painel + a dock Krema
└── alternar-barra-kde.sh           # Alterna entre KDE original e personalizado
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
