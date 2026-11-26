# Configs Linux — KDE Plasma

Scripts para preparar e personalizar o KDE Plasma 6 no **Debian 13**, **Kubuntu/Ubuntu 26.04 LTS** e **CachyOS** (Pacman). Inclui instalação de ferramentas, temas, barra de tarefas e gerenciamento de perfis visuais com backup.

## Instalação rápida

O projeto **não é instalado pela loja de aplicativos**: você clona o repositório com Git e executa `install.sh` no terminal **como usuário normal**. Use o procedimento da sua distribuição, sempre após concluir a instalação do Linux e iniciar uma sessão KDE Plasma.

### Debian 13 / Kubuntu 26.04

```bash
sudo apt update
sudo apt install -y git

cd "$HOME"
git clone https://github.com/victoralecrim11/configs-linux.git
cd configs-linux
```

### CachyOS KDE (Pacman)

```bash
# Atualiza o sistema e instala o Git
sudo pacman -Syu --needed git

# Baixa o instalador da branch principal
cd "$HOME"
git clone https://github.com/victoralecrim11/configs-linux.git
cd configs-linux
```

**Já clonou o projeto?** Não faça outro clone. Atualize os arquivos no diretório existente:

```bash
cd "$HOME/configs-linux"
git pull --ff-only
```

Em qualquer uma das distribuições suportadas, confira a detecção e faça uma simulação **sem instalar nada**:

```bash
bash install.sh --detect
bash install.sh --check-session
bash install.sh --profile full --dry-run
```

Escolha **apenas o perfil que deseja instalar**:

| Perfil | O que instala | Comando |
| --- | --- | --- |
| **Premium** | Visual KDE, Papirus, Breeze Dark e dock Krema | `bash install.sh --profile premium` |
| **Dev Fullstack** | Git, NVM, Node.js LTS, Java, Python, PHP, Composer e ferramentas de desenvolvimento | `bash install.sh --profile dev-fullstack` |
| **Full** | Premium + Dev Fullstack | `bash install.sh --profile full` |

O instalador solicita `sudo` quando necessário. **Nunca execute `sudo bash install.sh`**. Os perfis Premium e Full exigem KDE Plasma em sessão Wayland. NVM e Node.js LTS são instalados por padrão. Para instalar também Node.js da distribuição, Docker, .NET ou VS Code, use as opções `--with-node`, `--with-docker`, `--with-dotnet` e `--with-vscode` (somente Dev Fullstack ou Full). Veja [o guia completo](docs/instalacao.md).

### Instalação passo a passo no CachyOS

Se você acabou de instalar o CachyOS (inclusive numa VM), conclua primeiro o instalador gráfico, reinicie, remova a ISO virtual se necessário e **entre na sua conta do sistema instalado**, não em `liveuser`. Abra o **Konsole**.

**1. Instale o Git e clone o projeto.** Execute o bloco `CachyOS KDE (Pacman)` acima. Como o suporte já está na `main`, não é necessário selecionar uma branch de desenvolvimento.

**2. Confirme a detecção.**

```bash
cd "$HOME/configs-linux"
bash install.sh --detect
```

A saída deve mostrar `Familia: pacman` e `Backend: cachyos`. Se aparecer `nao homologado`, **não prossiga**.

**3. Confira a sessão KDE e simule o perfil desejado.**

```bash
bash install.sh --check-session
bash install.sh --profile dev-fullstack --dry-run
# Para conferir os dois perfis juntos:
bash install.sh --profile full --dry-run
```

O `--dry-run` apenas exibe o plano: não instala pacotes e não modifica o KDE. Os perfis Premium/Full requerem **Wayland**; o Dev Fullstack pode ser instalado sem esses ajustes visuais.

**4. Instale um perfil (escolha uma opção).**

```bash
# Somente ferramentas de desenvolvimento (recomendado como primeiro teste na VM)
bash install.sh --profile dev-fullstack

# OU somente personalização KDE + Krema
# bash install.sh --profile premium

# OU os dois conjuntos de recursos
# bash install.sh --profile full
```

As duas alternativas comentadas são comandos opcionais: **remova o `#` apenas da opção escolhida**. O backend usa Pacman, com atualização completa na primeira transação necessária. Leia e confirme as operações do gerenciador de pacotes.

**5. Extras opcionais (somente Dev Fullstack/Full).**

```bash
# Simulação com Node, Docker, .NET 10 e VS Code
bash install.sh --profile dev-fullstack --with-node --with-docker --with-dotnet --with-vscode --dry-run

# Instalação real, se você quiser os quatro extras
bash install.sh --profile dev-fullstack --with-node --with-docker --with-dotnet --with-vscode
```

O VS Code da Microsoft utiliza `visual-studio-code-bin` no **AUR**. A dock Krema, necessária para Premium/Full, também depende do AUR. Se `paru`/`yay` não estiver disponível, o instalador oferece instalar `paru` pelo repositório configurado; o uso do AUR exige **autorização adicional** e revisão do PKGBUILD. Não aceite instruções ou pacotes de terceiros sem conferir a origem.

**6. Verifique o resultado e explore os perfis visuais.**

```bash
bash install.sh --status
bash install.sh --verify-profile dev-fullstack
bash scripts/perfis-kde.sh listar
bash scripts/catalogo-visual-kde.sh listar
```

Para conferir outro perfil, substitua `dev-fullstack` por `premium` ou `full` em `--verify-profile`. Os seis presets visuais são **opcionais** e não são ativados automaticamente:

```bash
# Somente Premium/Full: simule e registre os presets sem aplicá-los
bash install.sh --profile premium --with-visual-presets --dry-run
bash install.sh --profile premium --with-visual-presets

# Depois, escolha um visual explicitamente
bash scripts/perfis-kde.sh aplicar layan-minimalist-modern --dry-run
bash scripts/perfis-kde.sh aplicar layan-minimalist-modern
```

**Dica para VirtualBox:** crie um snapshot da VM antes dos perfis Premium/Full. A instalação real pode alterar painéis, decoração, efeitos e wallpaper. Os testes automatizados não substituem a validação visual na sua versão do Plasma.

### Flatpak, Flathub e loja da distribuição

**Todos os perfis de instalação** incluem Flatpak e a loja da distribuição. No Debian/Kubuntu, os pacotes são `flatpak`, `plasma-discover`, `plasma-discover-backend-flatpak`, `kde-config-flatpak`; no CachyOS, `flatpak` e `cachyos-packageinstaller`. O Discover existente não é removido. O instalador adiciona **Flathub para o usuário atual**, se ainda não existir como remoto de usuário ou sistema, sem sobrescrever nem duplicar configurações. No CachyOS, use uma versão do Package Installer com suporte Flatpak (2.0 ou posterior) e habilite a opção nas configurações, se necessário. Caso a versão instalada seja antiga, atualize com `sudo pacman -Syu`. A instalação não baixa aplicativos do Flathub automaticamente.

```bash
# Conferir os pacotes e a fonte Flathub depois de instalar
bash install.sh --verify-profile full
flatpak remotes --show-details
```

Feche e reabra a loja gráfica; faça logout/login (ou reinicie) se os apps Flatpak ainda não aparecerem. A verificação `--verify-profile` confere pacotes, não o remoto Flathub nem a interface gráfica. Consulte [o guia de instalação](docs/instalacao.md).

### Notas sobre pacotes no CachyOS

O backend CachyOS instala pacotes oficiais via **Pacman** e evita o uso isolado de `pacman -Sy` (atualizações parciais). `--yes` não ignora as confirmações do Pacman nem as autorizações exigidas para o AUR. **Arch Linux genérico não é uma distribuição homologada por este instalador.**

No CachyOS, o script mapeia nomes de pacotes APT para equivalentes Pacman, integra Flatpak/Package Installer, utiliza `dotnet-sdk-10.0` para .NET 10 e solicita confirmação para o uso do AUR com Krema ou VS Code. Os perfis visuais KDE são separados dos perfis de instalação, e os snapshots pessoais permanecem locais.

## Perfis de instalação e status

Perfis de **instalação** e de **aparência** são coisas diferentes.

```bash
# Instalação: lista premium, dev-fullstack e full; mostra registro e pacotes atuais
bash install.sh --status

# Verifica dependências presentes sem instalar
bash install.sh --verify-profile dev-fullstack
bash install.sh --verify-profile full
```

O nome oficial é `dev-fullstack`; `--profile dev` e `--verify-profile dev` continuam aceitos por compatibilidade. O histórico local permanece no arquivo `dev.state`, sem necessidade de migração.

A execução real registra cada etapa como `concluido`, `parcial` ou `falhou`. Caso um pacote seja removido depois, o perfil pode aparecer como `desatualizado`. Instalações feitas antes da implementação aparecem como `sem registro`, mesmo que todos os pacotes estejam presentes — não se inventa histórico de execução.

Os registros são locais e não são enviados ao GitHub: `~/.local/state/linux-hybrid-v2/perfis-instalacao/`. Consulte [como funciona o rastreador](docs/status-instalacao.md).

## Perfis visuais KDE

### Qual perfil visual está ativo agora?

No terminal do Debian/Kubuntu/CachyOS, execute:

```bash
cd ~/configs-linux
bash scripts/perfis-kde.sh atual
```

**`atual`** mostra o último perfil visual ativado e informa se a Krema está ligada ou desligada. Para consultar os perfis disponíveis use `bash scripts/perfis-kde.sh listar`; para trocar use `bash scripts/perfis-kde.sh aplicar NOME`. O comando `atual` não verifica todas as mudanças manuais feitas depois da última ativação.

Os estilos de aparência são snapshots locais, **separados da instalação dos pacotes**.

```bash
# Mostrar o ultimo perfil visual ativado
bash scripts/perfis-kde.sh atual

# Listar estilos visuais salvos
bash scripts/perfis-kde.sh listar

# Salvar aparência atual em um novo perfil
bash scripts/perfis-kde.sh criar meu-estilo --recursos --dock off

# Atualizar um perfil preservando a versão anterior
bash scripts/perfis-kde.sh editar meu-estilo --recursos --dock off

# Pré-visualizar e aplicar um perfil existente
bash scripts/perfis-kde.sh aplicar meu-estilo --dry-run
bash scripts/perfis-kde.sh aplicar meu-estilo

# Dock Krema + painel superior ou painel inferior sem dock
bash scripts/perfis-kde.sh dock on
bash scripts/perfis-kde.sh dock off
```

Os snapshots ficam em `~/.local/share/linux-hybrid/profiles/`, sem serem enviados ao repositório. Veja o [guia de perfis KDE](docs/perfis-visuais.md) para duplicar, renomear, excluir, recuperar versões e configurar Sweet, ícones e efeitos.

### Catálogo de perfis visuais

O catálogo oferece seis presets: `sweet-kde-videoyt`, `layan-minimalist-modern`, `catppuccin-mocha-videoyt`, `garuda-dr460nized`, `breeze-escuro-dock` e `breeze-classico`. Instalar um preset registra sua configuração sem alterar o visual ativo. Para aplicar, use o gerenciador:

```bash
bash scripts/catalogo-visual-kde.sh listar
bash scripts/catalogo-visual-kde.sh instalar layan-minimalist-modern
bash scripts/catalogo-visual-kde.sh instalar catppuccin-mocha-videoyt
bash scripts/perfis-kde.sh aplicar catppuccin-mocha-videoyt
bash scripts/perfis-kde.sh atual
```

**Os seis presets não são registrados automaticamente por padrão**. Para incluí-los na execução de Premium ou Full, use o opt-in:

```bash
bash install.sh --profile full --with-visual-presets --dry-run
bash install.sh --profile full --with-visual-presets
```

O instalador pede confirmação adicional: registra os seis perfis **sem aplicar nenhum**, preserva perfis existentes e instala recursos dos temas Sweet/Layan a partir de projetos de terceiros (inclusive executando o instalador do Layan como usuário comum). Também é possível registrar os perfis separadamente pelo catálogo. O perfil `dev` não instala presets visuais, mesmo com Flatpak e a loja gráfica disponíveis.

O perfil `catppuccin-mocha-videoyt` segue o vídeo [COMO DEIXAR SEU LINUX LINDO!](https://youtu.be/usXZBNjo8gI): Catppuccin Mocha Mauve, painel KDE superior e dock Krema inferior em ocultação automática. O wallpaper japonês do trem e os widgets/calendário do vídeo não são distribuídos pelo preset, pois sua origem e licença ainda não foram confirmadas. O perfil novo é registrado sem aplicar a sessão.\n\nA instalação dos temas de terceiros exige Git e internet; a dock Krema precisa estar instalada separadamente. O catálogo não publica snapshots pessoais e não garante reprodução pixel a pixel. Consulte [perfis KDE](docs/perfis-visuais.md) e [recursos visuais](docs/recursos-visuais.md) para detalhes e limitações.

## Atalhos do Windows no KDE

Os perfis de instalação `premium`, `dev` e `full` aplicam o mapa comum de atalhos **quando executados em sessão KDE**. A troca dos perfis visuais também tenta reaplicá-lo. Faça uma simulação antes:

```bash
bash scripts/atalhos-windows-kde.sh --dry-run
bash scripts/atalhos-windows-kde.sh --apply
```

Atalhos nativos: `Win+D`, `Win+L`, `Win+Tab`, `Win+V`, `Win+setas`, `Alt+Tab` e `Alt+F4`. Lançadores .desktop para `Win+E`, `Win+R`, `Win+I`, `Win+Shift+S`, `Ctrl+Alt+T`, `Ctrl+Shift+Esc` e `Ctrl+Alt+C` são preparados, mas **precisam ser validados em Configurações → Atalhos**, pois o KGlobalAccel do Plasma 6 pode não registrar entradas `.desktop` automaticamente. Veja os detalhes em [recursos visuais](docs/recursos-visuais.md).

## Documentação

| Guia | Assunto |
| --- | --- |
| [Instalação Developer](docs/instalacao.md) | Pacotes de desenvolvimento e opções |
| [Recursos Sweet](docs/recursos-visuais.md) | Origem e limites da instalação automática |
| [Atalhos KDE](docs/recursos-visuais.md#fontes-e-atalhos) | Teclas Windows e notas de compatibilidade |
| [Instalação](docs/instalacao.md) | Perfis, distribuições e opções |
| [Status de instalação](docs/status-instalacao.md) | Registro automático e verificação dos pacotes |
| [Perfis visuais KDE](docs/perfis-visuais.md) | Criar, editar e alternar configurações |
| [Solução de problemas](docs/solucao-de-problemas.md) | Sudo, Wayland, Krema, APT e restauração |
| [Histórico e testes](docs/historico-e-testes.md) | Experimentos com painéis, temas e dock |
| [Scripts legados](docs/legado.md) | Instruções das versões anteriores |

## Testes

```bash
bash tests/smoke.sh
bash tests/perfis-kde-smoke.sh
bash tests/sweet-barra-smoke.sh
```

Esses testes não precisam de `sudo` e não devem modificar o KDE em execução. Uma instalação real pode alterar tema, painel e wallpaper; faça backup e use `--dry-run` primeiro.

**Licenciamento:** consulte as licenças e condições dos programas, temas, ícones e componentes de terceiros instalados.


### Visual do perfil Full (KDE Plasma)

O instalador `bash install.sh --profile full` configura a decoração **Plastik**,
localiza o wallpaper original **Nuvole** pelo metadata.json (inclusive no diretório padrão **/usr/share/wallpapers/Next/**) e ativa a ocultação
automática do painel KDE. Se Nuvole não estiver disponível, preserva o
papel de parede atual e avisa (não substitui por uma imagem diferente).
A Krema e os demais perfis de instalação não são alterados.

Para reaplicar **somente** esses ajustes, sem reinstalar os programas:

```bash
cd ~/configs-linux
bash scripts/aplicar-visual-full.sh
```

O painel aparece ao tocar a borda em que está posicionado. Caso Nuvole não seja encontrado, instale-o pelo gerenciador de papéis de parede do KDE e execute novamente.

### Fontes comuns a todos os perfis

Todos os perfis de instalação instalam **Fira Code**, **JetBrains Mono** e
**Inter** pelo gerenciador da distribuição (APT no Debian/Kubuntu; Pacman no CachyOS). No KDE Plasma, a interface usa Inter e a fonte
monoespaçada padrão usa JetBrains Mono. Fira Code fica instalada para os
editores/IDEs (configurar a preferência de cada editor separadamente).
Os atalhos comuns ficam em `scripts/atalhos-windows-kde.sh`, com backups
em `~/.local/state/linux-hybrid-v2/shortcuts/`. O Plasma 6 Wayland pode
precisar de logout/login para registrar os atalhos dos lançadores.


Para reaplicar as preferências KDE sem reinstalar ferramentas:

```bash
bash scripts/aplicar-comum-kde.sh
```

**Nota:** as fontes Inter e JetBrains Mono podem estar instaladas somente
no diretório do usuário se não houve acesso administrativo; ao executar
qualquer perfil de instalação, o gerenciador da distribuição instala os pacotes de fontes globalmente, conforme sua disponibilidade.
Os atalhos de lançadores no Plasma 6 Wayland exigem confirmação visual
em Configurações do Sistema → Atalhos, possivelmente após novo login.

### Efeito Lâmpada Mágica no Premium / Full

O perfil `premium` (incluído também no `full`) ativa o efeito **Magic Lamp**
nativo do KWin ao minimizar janelas. O instalador grava
`[Plugins] magiclampEnabled=true` em `~/.config/kwinrc`, desativa o efeito
concorrente `squash`, cria backup e solicita carregamento ao KWin sem
reiniciá-lo no Wayland.

Para aplicar **apenas** o efeito, sem reinstalar o perfil:

```bash
cd ~/configs-linux
bash scripts/efeito-lampada-magica.sh --apply
bash scripts/efeito-lampada-magica.sh --status
```

Se o efeito não aparecer, confira **Configurações do Sistema → Efeitos da área
de trabalho → Lâmpada Mágica** e faça logout/login. A disponibilidade do
plugin depende da versão e dos pacotes do KWin; salvar a opção não garante
que o efeito foi carregado na sessão.


### Minimizar/restaurar pela dock Krema (todos os perfis)

Ao clicar com o botão esquerdo no ícone de uma janela **ativa**, a Krema
minimiza essa janela. Ao clicar novamente, ela restaura ou coloca em foco.
Isso também funciona para aplicativos com várias janelas abertas: apenas a
janela ativa do grupo é minimizada.

O instalador aplica a opção em **premium**, **dev** e **full** quando executado
em uma sessão KDE. O gerenciador `scripts/perfis-kde.sh` também reaplica
o comportamento após restaurar qualquer perfil visual, evitando que snapshots
antigos reponham o clique padrão. O script altera somente as chaves
`SingleWindowClickAction=1` e `GroupedWindowClickAction=2` no grupo
`[General]` de `~/.config/kremarc`, com backup da configuração anterior.

Para aplicar imediatamente, **sem reinstalar os programas**:

```bash
cd ~/configs-linux
bash scripts/configurar-clique-krema.sh --apply
bash scripts/configurar-clique-krema.sh --status
```

Se a Krema estiver aberta, ela será reiniciada para adotar os novos
valores; se estiver desligada, permanece desligada. **Não use sudo**.
Para o efeito Lâmpada Mágica, a ativação do plugin KWin é independente
da ação de clique da dock.

### Preset Layan Minimalist Modern

```bash
bash scripts/catalogo-visual-kde.sh instalar layan-minimalist-modern
bash scripts/perfis-kde.sh aplicar layan-minimalist-modern
```

Detalhes em [docs/perfis-visuais.md](docs/perfis-visuais.md).

### Preset Garuda Dr460nized

Visual inspirado no Garuda para KDE Plasma 6, sem instalar repositorios ou configuracoes de sistema do Garuda. Usa Sweet, BeautyLine, wallpaper Maldrakor, efeitos KWin e o layout Krema existente. Requer Git, curl, internet e Krema instalada. O menu global e a fidelidade visual dependem do painel existente; nao e uma copia integral do tema oficial.

```bash
bash scripts/catalogo-visual-kde.sh instalar garuda-dr460nized --dry-run
bash scripts/catalogo-visual-kde.sh instalar garuda-dr460nized
bash scripts/perfis-kde.sh aplicar garuda-dr460nized --dry-run
bash scripts/perfis-kde.sh aplicar garuda-dr460nized
```

Recursos obtidos dos projetos upstream Sweet e [BeautyLine](https://gitlab.com/garuda-linux/themes-and-settings/artwork/beautyline), [Garuda Wallpapers](https://gitlab.com/garuda-linux/themes-and-settings/artwork/garuda-wallpapers). A instalacao registra o preset sem ativar a sessao. Valide em uma VM antes do uso definitivo.


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
