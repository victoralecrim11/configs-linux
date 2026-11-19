# Recursos visuais KDE — instalação e limites

Este guia descreve os recursos **efetivamente integrados** ao instalador atual do `configs-linux`. Consulte também [Perfis visuais](perfis-visuais.md), [Instalação](instalacao.md) e [Soluções de problemas](solucao-de-problemas.md).

## Premium e Full

O perfil `premium` configura o KDE Plasma com **Breeze Dark**, ícones **Papirus Dark**, wallpaper gerado pelo instalador, painel configurado e dock Krema. O perfil `full` executa o Premium e inclui as ferramentas do perfil de desenvolvimento.

```bash
cd ~/configs-linux
bash install.sh --profile premium --dry-run
bash install.sh --profile premium
```

O instalador Premium também chama `scripts/efeito-lampada-magica.sh` para tentar ativar o efeito nativo de minimização do KWin. A ativação visual depende da versão do KWin e deve ser testada na sessão.

## Ajustes exclusivos do Full

Além do Premium, `full` chama `lib/full-visual.sh`: decoração **Plastik**, wallpaper original **Nuvole** (identificado pelos metadados em `/usr/share/wallpapers/Next/`, quando disponível) e ocultação automática do painel KDE.

Para reaplicar somente esses ajustes:

```bash
bash scripts/aplicar-visual-full.sh
```

## Dock Krema

A instalação da Krema utiliza o repositório de pacotes definido em `lib/krema.sh`. O script `scripts/configurar-clique-krema.sh` define o clique esquerdo sobre janelas ativas como minimizar/restaurar, com as opções `SingleWindowClickAction=1` e `GroupedWindowClickAction=2`.

```bash
bash scripts/configurar-clique-krema.sh --apply
bash scripts/configurar-clique-krema.sh --status
```

## Sweet, Candy Icons e outros temas de terceiros

O gerenciador `scripts/perfis-kde.sh` salva e reaplica **perfis visuais locais**. Ele pode preservar recursos já presentes usando `--recursos`, mas **não instala automaticamente** os temas Sweet, Candy Icons, Andromeda ou seus papéis de parede.

Para aplicar um visual que dependa desses recursos, instale primeiro os componentes compatíveis com sua versão do KDE pelo gerenciador de temas do Plasma e depois capture o perfil:

```bash
bash scripts/perfis-kde.sh listar
bash scripts/perfis-kde.sh criar sweet --recursos --dock keep
```

Se o perfil já existir, use `editar` no lugar de `criar`. Os snapshots ficam em `~/.local/share/linux-hybrid/profiles/` e não são publicados no GitHub.

## Fontes e atalhos

Os três perfis de instalação incluem **Fira Code, JetBrains Mono e Inter** pelo APT; no KDE, Inter é usada na interface e JetBrains Mono como fonte monoespaçada. O script de atalhos `scripts/atalhos-windows-kde.sh` prepara combinações semelhantes às do Windows. Atalhos de aplicativos podem exigir validação em **Configurações do Sistema → Atalhos** após entrar novamente na sessão.

```bash
bash scripts/aplicar-comum-kde.sh
bash scripts/atalhos-windows-kde.sh --dry-run
```

## Testes

```bash
bash tests/smoke.sh
bash tests/perfis-kde-smoke.sh
bash tests/sweet-barra-smoke.sh
```

Os testes de smoke não devem alterar a sessão em uso. Antes de instalar um perfil completo, faça simulação e mantenha backup das preferências KDE.
