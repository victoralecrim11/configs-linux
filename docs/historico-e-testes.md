# Histórico técnico e testes anteriores

Experimentos realizados durante o desenvolvimento. Para configuração atual, veja [Instalação](instalacao.md), [Perfis visuais](perfis-visuais.md) e [Solução de problemas](solucao-de-problemas.md).

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


## Validação

```bash
for arquivo in scripts/*.sh; do bash -n "$arquivo" || exit 1; done
bash scripts/kubuntu-hybrid-setup-v1.0.2.sh --dry-run
```

A validação sintática e a simulação do instalador passaram na VM. **Não executei a restauração nem reinstalei o ambiente durante a preparação do repositório.**
