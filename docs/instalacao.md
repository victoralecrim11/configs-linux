# Guia de instalação e manutenção

Documentação ampliada dos perfis de instalação. Consulte também [Status de instalação](status-instalacao.md), [Problemas comuns](solucao-de-problemas.md) e o [README principal](../README.md).

## Comece aqui: instalador multidistro v3

O instalador `install.sh` **detecta automaticamente a distribuição** usando `/etc/os-release`. Na versão 3, a instalação está disponível para **Kubuntu/Ubuntu 26.04**, **Debian 13** e **CachyOS com KDE Plasma 6**. Arch genérico, Fedora e openSUSE podem ser detectados, mas continuam bloqueados.


### Instalação do zero

Após instalar a distro e fazer o primeiro login no KDE Plasma, abra o Konsole:

```bash
sudo apt update
sudo apt install -y git
# CachyOS: substitua os comandos acima por sudo pacman -Syu --needed git
cd "$HOME"
git clone https://github.com/victoralecrim11/configs-linux.git
cd configs-linux
```

Se você já clonou o projeto, **não clone novamente**: use `cd ~/configs-linux`. Se seu clone antigo ainda está em `~/configs-linux-kubunutu`, pode continuar usando essa pasta; o nome local não precisa mudar.


### Diagnóstico, simulação e backup inicial

```bash
bash install.sh --detect
bash install.sh --check-session
bash install.sh --profile full --dry-run
bash scripts/alternar-barra-kde.sh salvar-original
```

O último comando deve ser executado **antes de personalizar**, quando o painel padrão já existir. Isso preserva seu layout KDE original para alternância posterior. O `--dry-run` não modifica arquivos, não utiliza `sudo` e não adiciona repositórios.


### Escolha um dos perfis

| Perfil | Comando | O que instala |
|---|---|---|
| **Premium** (`visual`) | `bash install.sh --profile premium` | Breeze Dark, Papirus, wallpaper e painel superior com dock Krema |
| **Dev Fullstack** | `bash install.sh --profile dev-fullstack` | Git, compiladores, Python, Java 21, Maven, PHP, Composer e utilitários |
| **Full** | `bash install.sh --profile full` | Premium + Dev Fullstack |

Sem `--profile`, o instalador exibe uma seleção interativa no Konsole. Para automações não interativas, informe o perfil e `--yes` explicitamente (inclusive quando autorizar repositórios de terceiros). **Nunca execute `sudo bash install.sh`.** O script solicita `sudo` somente quando necessário.


### Alias de compatibilidade do Dev Fullstack

O nome oficial para o usuário é `dev-fullstack`. O comando antigo `--profile dev` continua funcionando como alias para os mesmos pacotes, e `bash install.sh --verify-profile dev` também é aceito. O rastreador preserva o arquivo `dev.state` existente (não renomeia nem exclui histórico). `bash install.sh --status` apresenta o perfil como `dev-fullstack`.

```bash
bash install.sh --profile dev-fullstack --dry-run
bash install.sh --profile dev-fullstack
bash install.sh --verify-profile dev-fullstack
```

O nome "Fullstack" é a identificação do perfil; Node.js, Docker, .NET e VS Code ainda são **extras opcionais**, conforme descrito acima.

### Extras do perfil Dev Fullstack (opcionais)

```bash
bash install.sh --profile full --with-node --with-docker --with-dotnet --with-vscode
```

- `--with-node`: instala Node.js e npm da distribuição.
- `--with-docker`: tenta Docker do repositório da distro, sem remover Podman automaticamente.
- `--with-dotnet`: instala SDK .NET 10; no Debian, usa o feed oficial Microsoft com confirmação; no CachyOS, `dotnet-sdk-10.0` do Pacman.
- `--with-vscode`: no Debian/Kubuntu, usa o repositório oficial Microsoft para VS Code após confirmação; no CachyOS, `visual-studio-code-bin` no AUR (helper paru/yay e consentimento).

Os extras **não** são instalados implicitamente no perfil Dev ou Full. Isso evita adicionar serviços e repositórios que você talvez não queira. Pacotes indisponíveis são informados e instalações APT com remoção de dependências são bloqueadas.

### Flatpak/Flathub integrado à loja da distribuição (padrão)

Todo perfil (`dev-fullstack`, `premium`, `full`) instala Flatpak e a loja da distribuição. No Debian/Kubuntu: `flatpak`, `plasma-discover`, `plasma-discover-backend-flatpak`, `kde-config-flatpak`. No CachyOS: `flatpak` e `cachyos-packageinstaller`. Nenhuma loja existente é removida. Depois, o script detecta se o remoto `flathub` já existe no escopo do usuário ou do sistema. Se não existir em nenhum deles, adiciona-o **somente ao usuário atual** com:

```bash
flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
```

A configuração é idempotente e não instala apps Flatpak automaticamente. Reabra a loja. No CachyOS, use Package Installer 2.0 ou posterior e habilite o suporte Flatpak nas configurações, se necessário; para atualizar, execute `sudo pacman -Syu`. faça logout/login para atualizar integrações de sessão.

```bash
flatpak remotes --show-details
# Debian/Kubuntu: dpkg-query -W flatpak plasma-discover plasma-discover-backend-flatpak kde-config-flatpak
# CachyOS: pacman -Q flatpak cachyos-packageinstaller
```

O rastreador de perfis valida a **presença dos pacotes**, não se a fonte Flathub aparece visualmente na loja gráfica. Se a rede falhar durante a configuração do remoto, a instalação retorna erro e a falha é registrada.

### CachyOS: primeira execução e cuidados com AUR

No CachyOS, inicie com `sudo pacman -Syu --needed git`, clone o repositório e rode `bash install.sh --detect` seguido de `bash install.sh --profile dev-fullstack --dry-run`. A primeira transação real do instalador realiza **upgrade completo com Pacman** antes de instalar os pacotes solicitados. Não há `pacman -Sy` isolado nem instalação automática de AUR para o perfil de desenvolvimento básico.

Os nomes dos pacotes são traduzidos internamente (ex.: `build-essential` → `base-devel`, `openjdk-21-jdk` → `jdk21-openjdk`, `fonts-inter` → `inter-font`, `plasma-discover` → `discover`). Verificação de status usa `pacman -Q`, não `dpkg-query`.

Os perfis **premium** e **full** requerem Krema do AUR, segundo instruções oficiais do projeto. Para isso, tenha `paru` ou `yay` disponível, revise a receita PKGBUILD e aceite a confirmação adicional. Se não houver helper, o script oferece instalar `paru` pelos repositórios oficiais mediante confirmação e interrompe o processo caso você recuse. O acesso ao AUR requer uma segunda confirmação. O extra `--with-vscode` também depende do AUR; os extras `--with-dotnet`, `--with-node` e `--with-docker` usam pacotes dos repositórios oficiais. A execução do instalador nunca é feita com `sudo bash`; `sudo` é pedido somente para o Pacman.

O status confirma presença de **pacotes** e execução registrada, não garante que a dock, o painel ou um tema funcionem perfeitamente na versão atual do Plasma. Faça snapshot da VM antes de testar `premium` e `full`.

### Presets visuais (opcionais, Premium/Full)

A instalação convencional do Premium/Full prepara o visual, Krema e ferramentas, mas **não** registra automaticamente `sweet-kde-videoyt`, `layan-minimalist-modern`, `breeze-escuro-dock` e `breeze-classico`.

```bash
bash install.sh --profile full --with-visual-presets --dry-run
bash install.sh --profile full --with-visual-presets
bash scripts/catalogo-visual-kde.sh listar
bash scripts/perfis-kde.sh listar
```

O `--with-visual-presets` pede confirmação específica, baixa temas externos (Sweet e Layan), executa o instalador upstream do Layan como usuário normal e **registra sem ativar** os quatro perfis. Perfis já salvos permanecem intactos. `--with-visual-presets` não é permitido com `--profile dev-fullstack` e não afeta a instalação padrão sem a flag. Para ativar, use `bash scripts/perfis-kde.sh aplicar NOME`.


### Alternar KDE original ↔ Premium

```bash
bash scripts/alternar-barra-kde.sh status
bash scripts/alternar-barra-kde.sh original
bash scripts/alternar-barra-kde.sh personalizada
bash scripts/alternar-barra-kde.sh backup
```

A alternância controla o painel e a dock Krema, mas **não desinstala ferramentas Dev Fullstack**. A reinstalação do Krema usa PPA no Ubuntu 26.04, OBS assinado no Debian 13 e AUR (paru/yay, com confirmação) no CachyOS. Em uma instalação nova, faça logout/login caso os efeitos ainda não estejam visíveis.


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
bash install.sh --profile dev-fullstack --dry-run
```

Os testes verificam sintaxe e seleção de distro/perfil **sem instalar pacotes**. A primeira instalação real em cada sistema, especialmente CachyOS com AUR/Krema, deve ser validada em VM ou ambiente descartável antes de usar na máquina principal. A lógica de pacotes é baseada em listas revisadas e fontes oficiais do projeto; o instalador **não pesquisa e executa comandos arbitrários da internet**.


### Projetos de suporte futuro

Fedora (DNF), Arch genérico (Pacman) e openSUSE (Zypper/OBS) possuem detecção de família, mas **continuam sem backend homologado**. CachyOS usa o backend `lib/pacman.sh`. O instalador interrompe a instalação nesses sistemas para proteger o ambiente.

---

## Estrutura

```text
install.sh                       # Entrada unica v3; detecta a distro e o perfil
lib/
├── platform.sh                 # Deteccao de distro/versao/familia
├── core.sh                     # Backups, confirmacoes e instalacao APT
├── pacman.sh                   # Pacotes, seguranca e mapeamento CachyOS
├── krema.sh                    # Krema: PPA Ubuntu 26.04 / OBS Debian 13
├── premium.sh                  # Tema KDE + wallpaper + dock
└── dev.sh                      # Pacotes Developer e extras opt-in
scripts/
├── kubuntu-hybrid-setup-v1.0.2.sh  # Instalador anterior para Kubuntu
├── perfil-barra-atual-kde.sh       # Configura painel + dock (KDE)
├── alternar-barra-kde.sh           # KDE original ↔ personalizado (legado)
├── perfis-kde.sh                  # Gestao de multiplos perfis visuais KDE
└── corrigir-sweet-barra.sh        # Sweet inferior sem sobreposicao e com dock Krema
tests/
├── fixtures/                   # Exemplos de /etc/os-release
├── smoke.sh                    # Testes do instalador universal
└── perfis-kde-smoke.sh          # Testes isolados de perfis KDE
.github/workflows/smoke.yml     # Testes automaticos no GitHub
```

## Requisitos

- Kubuntu/Ubuntu 26.04, Debian 13 ou CachyOS com KDE Plasma 6.
- Sessão KDE Wayland para recursos da dock.
- Bash, systemd e acesso administrativo **apenas quando solicitado pelo instalador**.
- Revise os scripts e seus repositórios externos antes da execução.

## Observações

- Mudanças visuais podem exigir sair da sessão e entrar novamente.
- Recursos extras, incluindo o Krema e repositórios externos, dependem de disponibilidade e compatibilidade.
- Guarde backups fora do Git antes de experimentar novas alterações.


### NVM e Node.js

Os perfis `dev-fullstack` e `full` instalam o NVM oficial v0.40.3 e Node.js LTS no usuário, sem sudo. Instalações existentes e aliases padrão válidos são preservados. A opção `--with-node` continua instalando adicionalmente os pacotes da distribuição, mas não é necessária para usar Node.js.

Abra um novo terminal Bash ou Zsh e confira:

```bash
nvm --version
node -v
npm -v
nvm ls
```

No Fish, execute `bash` antes de usar NVM (não há suporte nativo ao Fish). O modo dry-run não baixa nem instala NVM. A verificação do perfil inclui NVM, Node e npm.
