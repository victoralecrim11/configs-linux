# Configurações Linux — Kubuntu 26.04 LTS

Scripts de personalização do **Kubuntu 26.04 LTS / KDE Plasma 6**, com visual inspirado em Windows 11, Garuda e dock no estilo macOS. Desenvolvidos e testados inicialmente na VM `kubuntu-vm`.

## Comece aqui: instalar, clonar e executar

Após instalar o **Kubuntu 26.04 LTS**, entre na sessão KDE Plasma (Wayland) e abra o **Konsole**.

### 1. Instale o Git

```bash
sudo apt update
sudo apt install -y git
```

### 2. Clone o repositório

```bash
cd "$HOME"
git clone https://github.com/victoralecrim11/configs-linux-kubunutu.git
cd configs-linux-kubunutu
```

Se já clonou, basta executar `cd ~/configs-linux-kubunutu`. Não faça o clone novamente na mesma pasta.

### 3. Confira os scripts (sem alterar o sistema)

```bash
ls scripts/
for arquivo in scripts/*.sh; do bash -n "$arquivo" || exit 1; done
bash scripts/kubuntu-hybrid-setup-v1.0.2.sh --dry-run
```

### 4. Salve o painel KDE original (antes de personalizar)

```bash
bash scripts/alternar-barra-kde.sh salvar-original
```

Execute após o primeiro login, quando o painel padrão do KDE já estiver carregado. Esta etapa permite restaurá-lo posteriormente.

### 5. Aplique o perfil personalizado, com instalação da dock

```bash
bash scripts/alternar-barra-kde.sh personalizada
bash scripts/alternar-barra-kde.sh status
```

Esse fluxo aplica o painel superior, instala o Krema caso não esteja presente (via PPA e APT) e configura a dock. Pode solicitar sua senha para instalar pacotes. Faça logout/login se alguma mudança não aparecer imediatamente.

### 6. Opcional: personalize tema, ícones e wallpaper

Para aplicar recursos visuais adicionais sem refazer o painel nem a dock:

```bash
bash scripts/kubuntu-hybrid-setup-v1.0.2.sh --profile visual --no-panel --no-dock
```

Para incluir ferramentas de desenvolvimento, veja `--profile dev` e `--profile full` no `--help` e revise os pacotes antes de executar.

### Atualize o repositório depois

```bash
cd "$HOME/configs-linux-kubunutu"
git pull --ff-only
```

Se aparecer conflito ou alterações locais pendentes, confira `git status` antes de prosseguir.

### Alternância rápida

```bash
bash scripts/alternar-barra-kde.sh original
bash scripts/alternar-barra-kde.sh personalizada
bash scripts/alternar-barra-kde.sh backup
bash scripts/alternar-barra-kde.sh status
```

**Execute os scripts como usuário normal, sem `sudo bash`.** O `sudo` é solicitado somente para operações administrativas específicas. Esses comandos pressupõem que você está na raiz do repositório.

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
