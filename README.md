# Configurações Linux — KDE Plasma multidistro

Scripts de personalização do **KDE Plasma 6** com perfis de instalação para **Kubuntu 26.04 LTS e Debian 13**, visual inspirado em Windows 11/Garuda/macOS e perfis visuais nomeados (v2.1). O projeto começou na VM `kubuntu-vm`.

## Comece aqui: gerenciar meus perfis KDE

O projeto tem **dois tipos diferentes de perfil**:

| Tipo | Exemplo | Serve para |
| --- | --- | --- |
| **Instalação** | `premium`, `dev`, `full` | Instalar programas e preparar a distribuição com `install.sh`. |
| **Aparência** | `hybrid-premium`, `sweet`, `kde-padrao-centralizado` | Salvar/trocar tema, ícones, barra, widgets e Krema com `scripts/perfis-kde.sh`. |

**Uma instalação Premium não é um perfil visual salvo.** Alterar a aparência não reinstala programas; instalar ferramentas Developer não muda necessariamente o visual.

### Instalar ou atualizar o repositório

Se ainda não clonou:

```bash
sudo apt update && sudo apt install -y git
cd "$HOME"
git clone https://github.com/victoralecrim11/configs-linux.git
cd configs-linux
```

Se o repositório já existe, use **apenas**:

```bash
cd ~/configs-linux
git pull --ff-only
```

No Konsole do KDE Plasma, execute os exemplos abaixo **como usuário normal, sem `sudo bash`**.

### Criar um novo perfil visual

1. Em **Configurações do Sistema → Cores e temas**, escolha tema, ícones, esquema de cores, fonte e efeitos.
2. Personalize painel, widgets e dock conforme desejar.
3. Execute `criar` para capturar o ambiente atual:

```bash
bash scripts/perfis-kde.sh criar meu-tema --recursos --dock off
```

Use `--dock on` para perfil que deve iniciar o **Krema**, `--dock off` para perfil **sem Krema** e `--dock keep` para deixar o estado da dock como estiver ao aplicar. `--recursos` também copia temas, ícones, wallpapers e fontes **locais do usuário**; pode consumir centenas de MB. Não inclui pacotes de sistema nem tudo que está fora de `~/.local/share/`.

### Editar um perfil já criado

`editar` **não abre um editor de código**: ele salva uma **nova versão da aparência atualmente aberta no KDE**, substituindo o snapshot nomeado e arquivando a versão antiga.

```bash
# Ver diferencas entre o ambiente atual e a versao salva
bash scripts/perfis-kde.sh comparar hybrid-premium

# Apos mudar tema, icones ou painel no KDE, salvar a nova versao
bash scripts/perfis-kde.sh editar hybrid-premium --recursos --dock on

# Listar as versoes anteriores (sem alterar o desktop)
bash scripts/perfis-kde.sh historico hybrid-premium
```

Se quiser voltar **ao snapshot de uma versão anterior**, copie exatamente o identificador exibido por `historico`:

```bash
bash scripts/perfis-kde.sh restaurar-versao hybrid-premium ID_DA_VERSAO
bash scripts/perfis-kde.sh aplicar hybrid-premium
```

`restaurar-versao` só substitui o **snapshot salvo**, guardando outra cópia no histórico; **não altera a interface em execução** até que `aplicar` seja executado. Para restaurar apenas o estado anterior à última troca de aparência, use `restaurar-ultimo`.

### Duplicar, renomear e excluir sem perder dados

```bash
# Duplicar o perfil em outro nome (sem alterar a interface)
bash scripts/perfis-kde.sh duplicar hybrid-premium windows-eleven-teste

# Renomear a copia
bash scripts/perfis-kde.sh renomear windows-eleven-teste windows-eleven-v2

# Ver detalhes e a lista de perfis
bash scripts/perfis-kde.sh detalhes windows-eleven-v2
bash scripts/perfis-kde.sh listar

# Excluir: exige confirmacao e move para lixeira local, nao apaga definitivamente
bash scripts/perfis-kde.sh excluir windows-eleven-v2

# Inspecionar e recuperar da lixeira
bash scripts/perfis-kde.sh lixeira
bash scripts/perfis-kde.sh restaurar-excluido windows-eleven-v2
```

Para automações não interativas, `excluir NOME --yes` permite pular a confirmação, mas **exclui somente o snapshot nomeado** (move para lixeira). O visual atualmente aplicado e os aplicativos instalados não são modificados. Excluir o perfil registrado como ativo limpa apenas o indicador de perfil, não muda a sessão.

**Segurança:** não use nomes com barras ou espaços; use `a-z`, `0-9`, `-` e `_` (até 40 caracteres). `criar` não sobrescreve nomes existentes; `editar` preserva a versão anterior; `duplicar` e `renomear` recusam nomes já usados. Os snapshots da lixeira podem ser recuperados com `restaurar-excluido`.

### Alternância automática do painel ao ativar ou desativar a Krema

O gerenciador ajusta a **posição do painel KDE** e a **visibilidade da Krema** em conjunto, sem remover widgets nem alterar os perfis salvos.

| Ação | Painel KDE | Krema |
| --- | --- | --- |
| **`dock on`** | Topo, sempre visível, mantendo seus ícones | Inferior, oculta automaticamente; aparece quando o cursor alcança a borda inferior |
| **`dock off`** | Inferior, com os ícones centralizados | Fechada e desativada na inicialização |
| **`aplicar NOME --dock on`** | Aplica o perfil e depois posiciona o painel no topo | Inicia Krema com ocultação automática |
| **`aplicar NOME --dock off`** | Aplica o perfil e depois posiciona o painel embaixo | Mantém Krema desligada |
| **`aplicar NOME --dock keep`** | Mantém a posição do painel que vem do snapshot | Não muda o estado da Krema |

```bash
cd ~/configs-linux

# Usar o tema que ja esta ativo sem recarregar todo o perfil:
bash scripts/perfis-kde.sh dock on       # painel superior + dock oculta
bash scripts/perfis-kde.sh dock off      # barra inferior + sem dock

# Fazer a mesma alternancia ao carregar um perfil visual:
bash scripts/perfis-kde.sh aplicar sweet --dock on
bash scripts/perfis-kde.sh aplicar sweet --dock off

# Conferir os perfis e o ultimo estado registrado:
bash scripts/perfis-kde.sh status
```

**Detalhes de auto-hide (Krema 0.13.0):** `VisibilityMode=1` (AutoHide), `RevealTriggerLocation=0` (borda da tela), `ShowDelay=100` ms, `HideDelay=700` ms, posição inferior (`Edge=1`) e distância à borda de 8 px (`FloatingMarginReference=0`, `FloatingMargin=8`). A Krema permanece animada, mas recolhe automaticamente após o cursor sair. O painel Plasma fica sempre visível, tanto embaixo quanto no topo, sem ocultação automática.

**Atenção:** use esses comandos para ligar/desligar a dock e mover o painel **juntos**. Executar `krema` ou `pkill krema` manualmente **não aciona automaticamente** a mudança de posição do painel. A ativação requer Krema instalada e sessão **Wayland**. Cada troca faz um backup local em `~/.local/share/linux-hybrid/profiles/.historico/`, sem atualizar o snapshot do perfil. Para recuperar uma aplicação anterior de perfil, existe `restaurar-ultimo`.

A escolha `--dock on|off` no comando `aplicar` é temporária: o perfil `sweet` pode continuar salvo como `dock=off`, mesmo quando `dock on` está ativo na sessão atual. Para não ficar sem tarefas, o gerenciador recusa desligar a Krema em perfis que não possuem gerenciador de tarefas no painel.

### Sweet recuperado: tema Candy, barra centralizada e Krema opcional

O perfil `sweet` foi corrigido para usar **Sweet + esquema de cores Sweet + candy-icons**, com o **gerenciador de tarefas nativo do KDE centralizado** e a dock Krema **desligada por padrão**. O wallpaper permanece no lugar. A versão anterior foi arquivada automaticamente em `~/.local/share/linux-hybrid/profiles/.historico/`.

```bash
cd ~/configs-linux

# Ativar o Sweet corrigido, com a barra nativa e sem Krema (padrão)
bash scripts/perfis-kde.sh aplicar sweet

# Escolher o comportamento da dock somente nesta aplicação
bash scripts/perfis-kde.sh aplicar sweet --dock on
bash scripts/perfis-kde.sh aplicar sweet --dock off

# Simular antes de mexer no KDE
bash scripts/perfis-kde.sh aplicar sweet --dock off --dry-run
```

**Importante:** `--dock on|off|keep` em `aplicar` é uma **sobrescrita temporária** da opção de dock salva; não altera o snapshot do perfil. Para tornar a alteração definitiva, utilize `editar sweet --recursos --dock on|off` depois de configurar o visual. Caso o perfil não contenha o applet de tarefas, o gerenciador bloqueia `--dock off`, evitando uma barra vazia sem alternador de aplicativos.

O comportamento atual de `--dock on` usa **ocultação automática** (`VisibilityMode=1`) e move a barra KDE para o topo, evitando manter a dock sempre sobre as janelas. A configuração anterior com `VisibilityMode=0` era o comportamento histórico do setup. Veja a seção **Alternância automática do painel ao ativar ou desativar a Krema**.

A instalação do tema Sweet ou dos Candy Icons não é automática ao aplicar o snapshot: eles precisam estar disponíveis no sistema. O comando `editar ... --recursos` preserva cópias locais quando existirem. Os backups de configuração ficam no computador, não no GitHub.

### Consultar, alternar e fazer backup de segurança

```bash
bash scripts/perfis-kde.sh status
bash scripts/perfis-kde.sh listar
bash scripts/perfis-kde.sh comparar hybrid-premium
bash scripts/perfis-kde.sh aplicar hybrid-premium --dry-run
bash scripts/perfis-kde.sh aplicar hybrid-premium
bash scripts/perfis-kde.sh aplicar sweet
bash scripts/perfis-kde.sh aplicar kde-padrao-centralizado
bash scripts/perfis-kde.sh restaurar-ultimo
```

A aplicação de um perfil faz backup automático, pode reiniciar **Plasma Shell e Krema**, e pode exigir logout/login para atualizar efeitos do KWin. `--dry-run` não modifica arquivos. Use `bash tests/perfis-kde-smoke.sh` para validar o gerenciador **sem alterar o KDE real**.

As pastas pessoais são:
```text
~/.local/share/linux-hybrid/profiles/
├── hybrid-premium/          # Snapshot atual salvo: Windows Eleven
├── sweet/                   # Sweet com icones centralizados, Krema off
├── kde-padrao-centralizado/ # Barra KDE centralizada sem Krema
├── .historico/              # Versoes antigas e backups
└── .lixeira/                # Perfis excluidos, recuperaveis
```

### Vídeo demonstrativo — personalização do KDE com tema Sweet

🎥 **[Make your KDE Sweet | Customizing KDE Plasma — NH Soft (23/04/2025)](https://www.youtube.com/watch?v=PyyxQYkloLo)**

O vídeo demonstra o processo de personalização do **KDE Neon com Plasma 6.3.4**, utilizando o tema **Sweet**. As principais etapas são:

| Tempo no vídeo | Assunto |
| --- | --- |
| [00:51](https://www.youtube.com/watch?v=PyyxQYkloLo&t=51s) | Wallpaper e tela de bloqueio |
| [01:37](https://www.youtube.com/watch?v=PyyxQYkloLo&t=97s) | Fontes personalizadas |
| [03:34](https://www.youtube.com/watch?v=PyyxQYkloLo&t=214s) | Tema, ícones e decoração de janelas |
| [06:55](https://www.youtube.com/watch?v=PyyxQYkloLo&t=415s) | Transparência e desfoque |
| [08:59](https://www.youtube.com/watch?v=PyyxQYkloLo&t=539s) | Ícone do menu de aplicativos |
| [09:38](https://www.youtube.com/watch?v=PyyxQYkloLo&t=578s) | Animações |
| [10:58](https://www.youtube.com/watch?v=PyyxQYkloLo&t=658s) | Prévia do Alt+Tab |

O tutorial serve como referência visual para o perfil **`sweet`**. O perfil **`hybrid-premium`** utiliza uma configuração independente, com tema Windows Eleven Dark e ícones Windows-Eleven. A dock Krema pode ser ativada ou desativada em cada perfil.

---

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

## Experimento de painel lateral e restauração da barra de fábrica do Kubuntu (17/11/2026)

Na VM **Kubuntu 26.04.1 / KDE Plasma 6.6.6 / Wayland**, com Krema 0.13.0, foi testado um painel vertical **à esquerda**, mantendo a **Krema centralizada embaixo**. Uma captura real com o navegador aberto não mostrou sobreposição entre a dock e o conteúdo do navegador na disposição testada. O resultado pode variar com a resolução, o dimensionamento de tela e outras janelas.

Depois do teste, foi recriada a **barra de fábrica do Kubuntu** usando o template **já instalado na própria distro**:
`/usr/share/plasma/layout-templates/org.kubuntu.desktop.defaultPanel/contents/layout.js`
(`loadTemplate("org.kubuntu.desktop.defaultPanel")` via API do Plasma). Ela foi restaurada na **parte inferior**, com os sete widgets padrão: Kickoff, pager, gerenciador de tarefas só com ícones (`icontasks`), separador de margens, bandeja, relógio e mostrar área de trabalho.

**Estado final validado:** um único painel KDE oficial embaixo (54 unidades de altura, escala da sessão 150%) e Krema ainda animada, **sempre visível** e centralizada acima dele. Para evitar que a Krema fique sobre a barra, o ajuste confirmado foi `Edge=1`, `VisibilityMode=0`, `Floating=true`, `FloatingMarginReference=1` (**borda interna do painel inferior sempre visível**) e `FloatingMargin=8`. A preferência `ReserveScreenSpace=true` permaneceu gravada. Captura real e reaplicação do perfil confirmaram a disposição; não é garantia universal para aplicativos/monitores diferentes.

### Perfis guardados **localmente na VM**

```bash
cd ~/configs-linux
bash scripts/perfis-kde.sh listar

# Painel lateral à esquerda + Krema no centro inferior (teste)
bash scripts/perfis-kde.sh aplicar lateral-teste

# Barra KDE de fábrica embaixo + Krema acima (resultado final)
bash scripts/perfis-kde.sh aplicar kubuntu-painel-padrao

# Alternativas anteriores preservadas
bash scripts/perfis-kde.sh aplicar sweet
bash scripts/perfis-kde.sh aplicar hybrid-premium
```

**Atenção:** `lateral-teste` e `kubuntu-painel-padrao` são snapshots pessoais criados na VM, em `~/.local/share/linux-hybrid/profiles/`. **Eles não são instalados automaticamente pelo `git clone` e não foram enviados ao GitHub.** Caso vá usá-los em outra instalação, faça uma cópia privada dos perfis e valide os temas e widgets presentes. A aparência Sweet e os Candy Icons foram mantidos no sistema; o que voltou ao padrão foi **a disposição da barra do Kubuntu**, não todos os temas globais.

Foi feito backup prévio em `~/.local/share/linux-hybrid/backups/antes-lateral-fabrica-*/`. O perfil lateral foi salvo antes da restauração, e o perfil de fábrica foi salvo e **reaplicado realmente**, verificando `panelIds.length=1`, `location=bottom`, widget `org.kde.plasma.icontasks`, Plasma ativo e Krema em execução. O perfil `sweet` não foi sobrescrito.

---

## KDE padrão com ícones centralizados e sem Krema (17/11/2026)

**Aplicado e validado na VM Kubuntu 26.04.1 (Plasma 6.6.6/Wayland)**. Mantém a barra de tarefas do Kubuntu embaixo, o **Kickoff** à esquerda, o **Gerenciador de tarefas apenas com ícones** no centro e a **bandeja/relógio** à direita. A Krema fica desativada, inclusive na inicialização do perfil. O tema/ícones em uso não são removidos.

### Como preparar e centralizar em outra instalação

Depois de entrar na sessão KDE Plasma, clone o repositório (apenas uma vez):

```bash
sudo apt update && sudo apt install -y git
cd "$HOME"
git clone https://github.com/victoralecrim11/configs-linux.git
cd configs-linux
```

Se o projeto já estiver clonado, execute `cd ~/configs-linux && git pull --ff-only` em vez de clonar novamente.

```bash
# Inspecionar o painel, sem alteracoes
bash scripts/centralizar-barra-kde.sh --status

# Fazer backup e centralizar os icones com dois espacadores nativos
bash scripts/centralizar-barra-kde.sh --aplicar
```

O script detecta o painel com o applet `org.kde.plasma.icontasks` e exige o conjunto padrão de sete widgets do Kubuntu. Ele **não altera um painel desconhecido**, não apaga aplicativos nem reinstala pacotes. Cria cópias de segurança em `~/.local/share/linux-hybrid/backups/pre-centralizar-*/`. Para poder ordenar os widgets com segurança no Plasma 6.6, reinicia **somente o Plasma Shell**; suas janelas abertas permanecem. Se já houver os dois espaçadores necessários, não cria outros.

**Forma manual, sem script:** clique com o botão direito no painel → **Entrar no modo de edição** → **Adicionar espaçador** duas vezes. Coloque um imediatamente à esquerda do **Gerenciador de tarefas apenas com ícones** e o outro imediatamente à direita, mantendo o Menu de Aplicativos à esquerda e a Bandeja do Sistema à direita. Deixe os espaçadores flexíveis/expansíveis. Essa é a mesma disposição aplicada automaticamente pelo script.

### Salvar e ativar a aparência sem Krema

Após centralizar, salve o perfil no gerenciador:

```bash
# Apenas na primeira vez
bash scripts/perfis-kde.sh salvar kde-padrao-centralizado --recursos --dock off

# Ativar o perfil, desativando Krema e seu autostart
bash scripts/perfis-kde.sh aplicar kde-padrao-centralizado
```

Se você já tem o perfil salvo e fez alguma modificação, use `atualizar kde-padrao-centralizado --recursos --dock off` em vez de `salvar`, que protege perfis existentes contra sobrescrita.

```bash
# Verificar e alternar (comandos na raiz do repositório)
bash scripts/perfis-kde.sh status
bash scripts/perfis-kde.sh listar
bash scripts/perfis-kde.sh aplicar kde-padrao-centralizado   # KDE centralizado, sem Krema
bash scripts/perfis-kde.sh aplicar sweet                     # Sweet corrigido com barra KDE (sem Krema)
bash scripts/perfis-kde.sh aplicar kubuntu-painel-padrao      # Kubuntu original + Krema
```

**Estado validado na VM:** espaçadores nativos `org.kde.plasma.panelspacer` com ordem `33;34;56;35;57;36;37;52;53` (esses IDs **não são portáteis**; o script detecta os IDs em cada máquina), Plasma Shell ativo, Krema encerrada, e override de autostart do usuário com `Hidden=true`. Snapshot salvo como `~/.local/share/linux-hybrid/profiles/kde-padrao-centralizado/`, com `dock=off`, configurações KDE e cerca de 203 MB de recursos locais.

**Importante:** o snapshot pessoal não está no GitHub. O repositório oferece o script `centralizar-barra-kde.sh` e o gerenciador `perfis-kde.sh` para reproduzir o layout; ao migrar entre computadores, capture outro snapshot ou copie o seu perfil local de forma privada.

---

## Gerenciador de perfis visuais KDE v2.1 — Original, Hybrid Premium, Sweet e outros

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

### Referência histórica: Sweet com Krema sempre visível (configuração anterior)

Em **17/11/2026**, a configuração foi aplicada e testada na VM **Kubuntu 26.04.1 / Plasma 6.6.6 / Wayland / Krema 0.13.0**. O tema global **Sweet já estava selecionado** (`kdeglobals → KDE → LookAndFeelPackage=Sweet`). O comportamento que fazia a dock desaparecer era `kremarc → General → VisibilityMode=2` (**Dodge windows**), e não a ocultação do painel superior do Plasma.

**Configuração histórica anterior à alternância dinâmica (não é mais o padrão de `dock on`):**

- **Krema inferior e centralizada**, com os aplicativos existentes preservados (`Edge=1`). O layout centralizado é nativo do Krema.
- **`VisibilityMode=0`**, que significa **Always visible** segundo o `krema.kcfg` do projeto oficial. O modo anterior `2` significa **Dodge windows**.
- **`ReserveScreenSpace=true`** salvo na configuração. **Atenção:** a funcionalidade de reserva de espaço aparece como *trabalho ainda não lançado* no README do Krema; não há garantia de que **Krema 0.13.0** respeite essa preferência quando uma janela maximizada encostar na dock.
- **Estado histórico da primeira configuração Sweet:** painel Plasma superior de 36 px, sem ocultação. **Em atualização posterior no mesmo dia, a barra foi retornada à parte inferior**; confira a seção abaixo para o perfil `sweet` atual.
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

**Resultado na VM:** os perfis `hybrid-premium` e `sweet` coexistem. O Sweet foi salvo com os recursos locais (~203 MB) e reaplicado em sessão real; o Plasma continuou ativo e o processo Krema foi reiniciado, mantendo `VisibilityMode=0`. Os backups locais não foram publicados no GitHub. A etapa posterior de correção reposiciona o painel inferior e valida a área de maximização das janelas via KWin.

### Referência histórica: Sweet com barra inferior e Krema sempre visível

**Validado na VM Kubuntu 26.04.1 com Plasma 6.6.6, em 17/11/2026.** O perfil `sweet` foi atualizado **depois** de reposicionar o painel KDE para a borda inferior. A dock Krema ficou centralizada **imediatamente acima** da barra, preservando os lançadores e as preferências de animação; o perfil `hybrid-premium` continua com sua disposição própria e não foi alterado.

Estado verificado por API do Plasma, arquivos de configuração e captura de tela da sessão real:

| Elemento | Configuração |
|---|---|
| Painel KDE principal | Inferior (`location=4`), 36 px, sempre visível (`hiding=none`), widgets preservados |
| Krema | Inferior (`Edge=1`), centralizada e sempre visível (`VisibilityMode=0`) |
| Separação dock → barra | 8 px; `Floating=true`, `FloatingMarginReference=0`, `FloatingMargin=44` |
| Preferência de reserva de espaço | `ReserveScreenSpace=true` |
| Tema e ícones | Sweet + Candy Icons (`candy-icons`) |
| Apps fixados no Krema | Dolphin, Konsole e Configurações do Sistema |

O ambiente tinha um painel vazio adicional com o papel de reservar espaço para a dock. Ele desapareceu automaticamente após o reposicionamento e a estabilização do Plasma, ficando **apenas o painel principal com seus sete widgets**. **Não apague manualmente outros painéis** sem conferir o que contêm.

#### Recuperar o Sweet que já foi salvo neste computador

```bash
cd ~/configs-linux
git pull --ff-only
bash scripts/perfis-kde.sh listar
bash scripts/perfis-kde.sh aplicar sweet
```

O script `perfis-kde.sh` reinicia Plasma Shell e Krema para que ambos releiam as configurações. `hybrid-premium` continua disponível com `bash scripts/perfis-kde.sh aplicar hybrid-premium`.

#### Recriar a mesma disposição em outra instalação KDE

A instalação nova **não possui automaticamente o snapshot pessoal da VM**. Depois de instalar/aplicar o Sweet e o Krema, faça backup do painel e, no Konsole (sem `sudo`), mova o painel **que contém a bandeja de sistema** para baixo por meio da API Plasma 6:

```bash
busctl --user call org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell evaluateScript s \
'(function(){var p=null;for(var i=0;i<panelIds.length;i++){var c=panelById(panelIds[i]);if(!c)continue;for(var j=0;j<c.widgetIds.length;j++){var w=c.widgetById(c.widgetIds[j]);if(w&&w.type==="org.kde.plasma.systemtray"){p=c;break;}}if(p)break;}if(!p)throw new Error("Painel principal nao encontrado");p.location="bottom";p.hiding="none";p.height=36;p.lengthMode="fill";print("Painel KDE movido: "+p.id);})();'
```

Ou altere a posição manualmente em **Editar modo de edição do painel → Posição → Inferior**. Para preservar a dock animada e deixá-la centralizada acima do painel, encerre Krema, grave as opções e reabra:

```bash
pkill -x -u "$(id -u)" krema || true
kwriteconfig6 --file kremarc --group General --key Edge --type int 1
kwriteconfig6 --file kremarc --group General --key VisibilityMode --type int 0
kwriteconfig6 --file kremarc --group General --key Floating --type bool true
kwriteconfig6 --file kremarc --group General --key FloatingMarginReference --type int 0
kwriteconfig6 --file kremarc --group General --key FloatingMargin --type int 44
kwriteconfig6 --file kremarc --group General --key ReserveScreenSpace --type bool true
nohup krema >/dev/null 2>&1 &
```

A margem de 44 px foi ajustada para o painel de **36 px + 8 px de folga**, em escala 100%. Em outros tamanhos de painel ou escala, ajuste a margem conforme a geometria real para evitar sobreposição. ReserveScreenSpace é uma preferência do Krema, mas não garante que qualquer versão da dock impeça a sobreposição com todas as janelas maximizadas.

Se estiver satisfeita com a aparência resultante e **já existir** o perfil Sweet:

```bash
bash scripts/perfis-kde.sh atualizar sweet --recursos --dock on
```

Se for o **primeiro** Sweet salvo nesse computador, use `salvar sweet --recursos --dock on` em vez de `atualizar`. O gerenciador arquiva a versão anterior sob `~/.local/share/linux-hybrid/profiles/.historico/`.

**Teste real executado:** após salvar o novo estado, `aplicar sweet` restaurou a barra inferior (36 px, sete widgets), Sweet, Candy Icons, Krema (`VisibilityMode=0` e margem 44 px), com Plasma Shell ativo. A largura do painel retornou ao tamanho da tela após alguns instantes de estabilização. O snapshot continua privado no computador e não foi enviado ao GitHub.

**Nota:** `scripts/perfil-barra-atual-kde.sh aplicar` é um instalador **legado** que configura explicitamente o painel **superior** e a Krema com outro modo de visibilidade. Para restaurar este visual atualizado, utilize **`bash scripts/perfis-kde.sh aplicar sweet`**, não o instalador legado.

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
├── perfis-kde.sh                  # Gestao de multiplos perfis visuais KDE
└── corrigir-sweet-barra.sh        # Sweet inferior sem sobreposicao e com dock Krema
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
