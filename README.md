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
