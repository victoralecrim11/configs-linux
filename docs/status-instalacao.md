# Status dos perfis de instalação

O projeto mantém **perfis de instalação e de aparência em sistemas separados**:

| Tipo | Comando | Conteúdo |
| --- | --- | --- |
| Instalação | `bash install.sh --status` | `premium`, `dev-fullstack`, `full`, resultados de execução e inventário de pacotes |
| Aparência | `bash scripts/perfis-kde.sh listar` | Snapshots personalizados do KDE, como Sweet ou Hybrid Premium |

## Consultar sem modificar o sistema

```bash
cd ~/configs-linux

bash install.sh --status
bash install.sh --list-profiles
bash install.sh --verify-profile full
bash install.sh --verify-profile premium
bash install.sh --verify-profile dev-fullstack

# Simulação não instala nem registra uma conclusão
bash install.sh --profile full --dry-run
```

A verificação mostra quantos pacotes básicos estão instalados e quais faltam. Os extras são verificados quando foram solicitados e registrados em uma instalação. Os pacotes Flatpak/Discover são comuns a todos os perfis, mas `--status` e `--verify-profile` não verificam a existência do remoto Flathub nem a disponibilidade efetiva da fonte no Discover. Para isso, execute `flatpak remotes --show-details` e confira a seção **Fontes** do Discover.

Os presets visuais Sweet, Layan e Breeze **não entram na contagem de pacotes**; são snapshots independentes. Por padrão não são registrados pelo `install.sh`: use `--with-visual-presets` com Premium/Full ou `bash scripts/catalogo-visual-kde.sh instalar-todos`. Para saber quais existem, rode `bash scripts/catalogo-visual-kde.sh listar` e `bash scripts/perfis-kde.sh listar`.

## Registro automático de cada etapa

A partir desta versão, o instalador armazena arquivos locais em:

```text
~/.local/state/linux-hybrid-v2/perfis-instalacao/
├── premium.state
├── dev.state        # identificador interno legado de dev-fullstack
└── full.state
```

Cada arquivo é gravado atomicamente, com permissão `0600`, e contém perfil, data UTC, distribuição, extras e resultado. Esses arquivos são **dados**, nunca executados como scripts.

| Resultado | Significado |
| --- | --- |
| `concluido` | Etapa executada e dependências previstas presentes |
| `parcial` | Etapa retornou, mas alguma dependência exigida está ausente |
| `falhou` | Execução interrompida durante a etapa |
| `desatualizado` | Registro de conclusão existe, porém uma nova inspeção encontrou pacotes ausentes |
| `sem registro` | Nenhuma conclusão foi registrada pelo rastreador |

O `full` executa Dev Fullstack e Premium separadamente. Se uma etapa falhar, as anteriores conservam seu estado e `full` recebe `falhou`. Se as etapas terminarem, mas alguma dependência não estiver presente, `full` será `parcial`.

O perfil aparece como **`dev-fullstack`** nos comandos e no status. O nome antigo **`dev`** continua aceito para instalação e consulta; ambos compartilham o mesmo registro local `dev.state`, evitando perder o histórico existente.

**Instalações anteriores à implementação não são marcadas automaticamente como concluídas.** Mesmo um inventário 24/24 prova apenas a presença dos pacotes, não a origem da instalação ou a aplicação do tema/painel. Uma nova execução real e validada cria o registro.

As consultas `--status`, `--verify-profile`, `--list-profiles` e as simulações `--dry-run` **não escrevem estado**. As configurações visuais permanecem separadas em `~/.local/share/linux-hybrid/profiles/`.

Para investigar instalações parciais, consulte os logs `~/.local/state/linux-hybrid-v2/install-*.log` e o [guia de problemas](solucao-de-problemas.md).
