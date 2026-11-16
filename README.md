# Configurações Linux — Kubuntu 26.04 LTS

Scripts de personalização do **Kubuntu 26.04 LTS / KDE Plasma 6**, com visual inspirado em Windows 11, Garuda e dock no estilo macOS. Desenvolvidos e testados inicialmente na VM `kubuntu-vm`.

## Estrutura

```text
scripts/
├── kubuntu-hybrid-setup-v1.0.2.sh  # Personalização, pacotes dev e ajustes opcionais
└── alternar-barra-kde.sh          # Backup e alternância do layout de painéis/widgets
```

## Requisitos

- Kubuntu/Ubuntu 26.04 com KDE Plasma 6.
- Sessão KDE Wayland para recursos da dock.
- Bash, systemd e acesso administrativo **apenas quando solicitado pelo instalador**.
- Revise os scripts e seus repositórios externos antes da execução.

## Instalação / personalização

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

## Voltar à barra padrão do KDE

**Faça backup da personalização antes de alternar:**

```bash
bash scripts/alternar-barra-kde.sh backup
bash scripts/alternar-barra-kde.sh original
```

Para voltar à barra personalizada salva:

```bash
bash scripts/alternar-barra-kde.sh personalizada
```

O script atua em `~/.config/plasma-org.kde.plasma.desktop-appletsrc`, que contém **painéis e widgets da área de trabalho**. Ao usar `original`, ele salva uma cópia com data, remove o arquivo de configuração dos painéis e reinicia `plasma-plasmashell.service` para solicitar a recriação do layout padrão. Dependendo do estado da sessão Plasma, pode ser necessário fazer logout/login. Ele **não desinstala** uma dock de terceiros; essa dock pode continuar sendo iniciada separadamente.

Os backups de alternância ficam em `~/.local/share/backup-barra-kde/`. Nunca publique arquivos pessoais de `~/.config`, tokens ou senhas neste repositório público.

## Validação

```bash
bash -n scripts/*.sh
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

O comando `aplicar` mantém os widgets existentes, e não remove aplicativos ou docks. Para reproduzir o ambiente completo em outra máquina, instale o Krema e os elementos visuais necessários usando o instalador original; o script de perfil **não instala dependências nem recria integralmente todos os widgets e arquivos de ícones**.

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
