# Configs Linux — KDE Plasma

Scripts para preparar e personalizar o KDE Plasma 6 no **Debian 13** e no **Kubuntu/Ubuntu 26.04 LTS**. Inclui instalação de ferramentas, temas, barra de tarefas e gerenciamento de perfis visuais com backup.

## Instalação rápida

Execute no terminal da sua sessão KDE, como **usuário normal**:

```bash
sudo apt update
sudo apt install -y git

git clone https://github.com/victoralecrim11/configs-linux.git
cd configs-linux
```

Se já possui o repositório:

```bash
cd ~/configs-linux
git pull --ff-only
```

Confira a distribuição e o acesso ao KDE Wayland antes de instalar:

```bash
bash install.sh --detect
bash install.sh --check-session
```

Escolha um perfil, simule e depois instale:

| Perfil | O que instala | Comando |
| --- | --- | --- |
| **Premium** | Visual KDE, Papirus, Breeze Dark e dock Krema | `bash install.sh --profile premium` |
| **Developer** | Git, Java, Python, PHP, Composer e ferramentas de desenvolvimento | `bash install.sh --profile dev` |
| **Full** | Premium + Developer | `bash install.sh --profile full` |

```bash
# Recomendado antes da execução real
bash install.sh --profile full --dry-run

# Instalação de exemplo
bash install.sh --profile full
```

O instalador solicita permissões `sudo` quando necessário. **Não execute com `sudo bash install.sh`**. Os perfis Premium e Full exigem KDE Plasma em sessão Wayland.

Os extras do Developer são opcionais: `--with-node`, `--with-docker`, `--with-dotnet` e `--with-vscode`. Consulte [todas as opções](docs/instalacao.md).

## Perfis de instalação e status

Perfis de **instalação** e de **aparência** são coisas diferentes.

```bash
# Instalação: lista premium, dev e full; mostra registro e pacotes atuais
bash install.sh --status

# Verifica dependências presentes sem instalar
bash install.sh --verify-profile full
```

A execução real registra cada etapa como `concluido`, `parcial` ou `falhou`. Caso um pacote seja removido depois, o perfil pode aparecer como `desatualizado`. Instalações feitas antes da implementação aparecem como `sem registro`, mesmo que todos os pacotes estejam presentes — não se inventa histórico de execução.

Os registros são locais e não são enviados ao GitHub: `~/.local/state/linux-hybrid-v2/perfis-instalacao/`. Consulte [como funciona o rastreador](docs/status-instalacao.md).

## Perfis visuais KDE

### Qual perfil visual está ativo agora?

No terminal do Debian/Kubuntu, execute:

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

### Temas visuais Sweet e recursos opcionais

O gerenciador `scripts/perfis-kde.sh` pode salvar e alternar perfis de aparência **já configurados localmente**. O instalador atual não oferece `--install-visual-profiles` nem inclui presets Sweet versionados. Temas como Sweet, Candy Icons e Andromeda devem ser instalados separadamente, antes de salvar os perfis. Consulte [recursos visuais e limitações](docs/recursos-visuais.md).

```bash
bash scripts/perfis-kde.sh listar
bash scripts/perfis-kde.sh atual
```

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
**Inter** pelo APT. No KDE Plasma, a interface usa Inter e a fonte
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
qualquer perfil de instalação, o APT instala os três pacotes globalmente.
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
