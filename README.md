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
| **Developer** | Git, Java, Python, PHP, Composer, ferramentas de desenvolvimento | `bash install.sh --profile dev` |
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
# Instalação: lista premium, dev e full; mostra o registro e os pacotes atuais
bash install.sh --status

# Verifica dependências presentes sem instalar
bash install.sh --verify-profile full
```

A execução real registra cada etapa como `concluido`, `parcial` ou `falhou`. Caso um pacote seja removido depois, o perfil pode aparecer como `desatualizado`. Instalações feitas antes da implementação aparecem como `sem registro`, mesmo que todos os pacotes estejam presentes — não se inventa histórico de execução.

Os registros são locais e não são enviados ao GitHub: `~/.local/state/linux-hybrid-v2/perfis-instalacao/`. Consulte [como funciona o rastreador](docs/status-instalacao.md).

## Perfis visuais KDE

Os estilos de aparência são snapshots locais, **separados da instalação dos pacotes**.

```bash
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

## Documentação

| Guia | Assunto |
| --- | --- |
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
