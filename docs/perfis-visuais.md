# Guia de perfis visuais KDE

Configurações pessoais de aparência e dock, independentes dos perfis de instalação. Consulte [Soluções de problemas](solucao-de-problemas.md) e [Histórico de testes](historico-e-testes.md).

## Comece aqui: gerenciar meus perfis KDE

O projeto tem **dois tipos diferentes de perfil**:

| Tipo | Exemplo | Serve para |
| --- | --- | --- |
| **Instalação** | `premium`, `dev-fullstack`, `full` | Instalar programas e preparar a distribuição com `install.sh`. |
| **Aparência** | `hybrid-premium`, `sweet`, `kde-padrao-centralizado` | Salvar/trocar tema, ícones, barra, widgets e Krema com `scripts/perfis-kde.sh`. |

**Uma instalação Premium não é um perfil visual salvo.** Alterar a aparência não reinstala programas; instalar ferramentas Dev Fullstack não muda necessariamente o visual.

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

### Listagem automática dos perfis visuais

```bash
cd ~/configs-linux
bash scripts/perfis-kde.sh listar
```

A listagem reúne automaticamente os perfis locais **[SALVO]** (prontos para aplicar, sujeitos às dependências) e os presets do repositório **[DISPONIVEL]** (ainda precisam ser registrados). Não baixa temas, não altera o KDE e não duplica nomes. Os snapshots pessoais não são sincronizados pelo Git.

| Preset do catálogo | Visual | Dock |
| --- | --- | --- |
| `sweet-kde-videoyt` | Sweet e Candy Icons | on |
| `layan-minimalist-modern` | Layan Dark | on |
| `catppuccin-mocha-videoyt` | Catppuccin Mocha Mauve | on |
| `garuda-dr460nized` | Inspirado no Garuda | on |
| `breeze-escuro-dock` | Breeze Dark | on |
| `breeze-classico` | Breeze clássico | off |

```bash
# Registrar um preset (simular e executar)
bash scripts/perfis-kde.sh instalar-preset sweet-kde-videoyt --dry-run
bash scripts/perfis-kde.sh instalar-preset sweet-kde-videoyt
# Ou registrar todos
bash scripts/perfis-kde.sh instalar-presets --dry-run
bash scripts/perfis-kde.sh instalar-presets
# Aplicar explicitamente após registrar
bash scripts/perfis-kde.sh aplicar sweet-kde-videoyt --dry-run
bash scripts/perfis-kde.sh aplicar sweet-kde-videoyt
bash scripts/perfis-kde.sh atual
```

O registro é opcional, requer sessão KDE e pode baixar recursos externos. A aplicação de presets com dock ligada exige Krema instalada e Wayland. Premium/Full também podem registrar os presets com `--with-visual-presets`; Dev Fullstack não aceita essa flag. Não confunda `install.sh --list-profiles` (perfis de instalação) com `scripts/perfis-kde.sh listar` (perfis visuais).

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

- **Premium / Dev Fullstack / Full:** instalam programas e preparam o sistema.
- **Original / hybrid-premium / sweet / outros:** são **fotografias locais da aparência do KDE**. Alternar entre elas **não** reinstala programas.

Os snapshots pessoais ficam **somente no computador**, em `${XDG_DATA_HOME:-$HOME/.local/share}/linux-hybrid/profiles/`. Não são adicionados ao Git automaticamente e podem conter preferências pessoais, wallpapers ou fontes que você não deve publicar.


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

**Importante:** o comando `salvar` **não baixa nem instala automaticamente o tema Sweet**. Ele registra o estado **depois** que você configurá-lo no KDE. Também não captura pacotes de sistema, applets não instalados ou temas disponíveis somente em `/usr/share`. Para reproduzir em outra distro, instale os componentes faltantes antes de aplicar o snapshot.


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
| `listar` / `status` | Lista perfis locais e presets disponíveis / estado registrado |
| `detalhes NOME` | Exibe metadados e tamanho dos recursos |
| `aplicar NOME --dry-run` | Simula sem alterar |
| `aplicar NOME` | Aplica configurações e dock |
| `restaurar-ultimo` | Recupera o último backup automático |
| `importar-legado original\|personalizada` | Importa snapshot do gerenciador antigo |

Em todos os casos, prefixe os comandos com `bash scripts/perfis-kde.sh`, na raiz do repositório.

---

## Catálogo de receitas visuais compartilháveis

Use `bash scripts/perfis-kde.sh catalogo` para ver os presets, e `bash scripts/perfis-kde.sh instalar-presets --dry-run` para simular. Execute `bash scripts/perfis-kde.sh instalar-presets` para registrar os que estiverem faltando, ou `bash scripts/perfis-kde.sh instalar-preset sweet-kde-videoyt` para registrar só esse. Os snapshots pessoais continuam em `~/.local/share/linux-hybrid/profiles/`, fora do Git.

O catálogo oferece os seis presets da tabela acima. Registrar não ativa; use `bash scripts/perfis-kde.sh aplicar NOME`. Os presets herdam a organização do painel do ambiente onde são criados e só modificam as opções visuais documentadas. Para fidelidade completa, ajustes de wallpapers, widgets, fonte e Alt+Tab ainda exigem conferência manual. Recursos Sweet podem precisar de acesso ao GitHub; a Krema deve estar instalada separadamente. Não use sudo para executar o catálogo.

## Layan Minimalist Modern

Tema oficial: https://github.com/vinceliuice/Layan-kde (Layan Dark, Kvantum e Tela).

```bash
bash scripts/catalogo-visual-kde.sh instalar layan-minimalist-modern
bash scripts/perfis-kde.sh aplicar layan-minimalist-modern
bash scripts/perfis-kde.sh atual
```

O preset preserva os outros perfis e registra backup antes de aplicar. A imagem de referencia inclui dock inferior e janelas escuras; layout exato, wallpaper e posicao das janelas podem exigir ajuste manual.

## Catppuccin Mocha — tutorial de vídeo

Perfil: `catppuccin-mocha-videoyt`, baseado em [COMO DEIXAR SEU LINUX LINDO! Customização no KDE Plasma + Catppuccin](https://youtu.be/usXZBNjo8gI). Usa Catppuccin Mocha Mauve ([repositório oficial](https://github.com/catppuccin/kde)), painel superior e dock Krema inferior com auto-ocultação.

```bash
bash scripts/perfis-kde.sh instalar-preset catppuccin-mocha-videoyt --dry-run
bash scripts/perfis-kde.sh instalar-preset catppuccin-mocha-videoyt
bash scripts/perfis-kde.sh aplicar catppuccin-mocha-videoyt
bash scripts/perfis-kde.sh restaurar-ultimo
```

Registrar o preset só baixa/instala os arquivos de tema na conta do usuário, sem rodar o instalador upstream que alteraria o desktop imediatamente. O papel de parede anime do trem, fontes e widgets exatos **não** são incluídos: imagem fornecida como referência, não como arquivo redistribuível. A identidade visual ainda depende da versão do Plasma e dos widgets existentes. Para uma dock inferior funcional, é necessária a Krema; sem ela, o gerenciador sinaliza dependência ausente.
