# Scripts e procedimentos legados

Procedimentos das versões anteriores preservados para referência. Prefira o instalador e o gerenciador de perfis atuais.

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

## Script legado de configuração do painel e da dock

O `scripts/perfil-barra-atual-kde.sh` ainda está disponível para manutenção e migração de instalações antigas. Para alternar **perfis visuais nomeados**, prefira `scripts/perfis-kde.sh`.

```bash
bash scripts/perfil-barra-atual-kde.sh status
bash scripts/perfil-barra-atual-kde.sh backup
bash scripts/perfil-barra-atual-kde.sh aplicar
bash scripts/perfil-barra-atual-kde.sh restaurar "$HOME/.local/share/kubuntu-hybrid/perfis-barra/NOME-DO-BACKUP"
```

**Atenção:** o comando legado `aplicar` reconfigura o painel KDE e pode modificar a aparência atual. Faça backup antes de usá-lo.

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
