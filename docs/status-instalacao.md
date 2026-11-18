# Status dos perfis de instalação

O projeto mantém **perfis de instalação e de aparência em sistemas separados**:

| Tipo | Comando | Conteúdo |
| --- | --- | --- |
| Instalação | `bash install.sh --status` | `premium`, `dev`, `full`, resultados de execução e inventário de pacotes |
| Aparência | `bash scripts/perfis-kde.sh listar` | Snapshots personalizados do KDE, como Sweet ou Hybrid Premium |

## Consultar sem modificar o sistema

```bash
cd ~/configs-linux

bash install.sh --status
bash install.sh --list-profiles
bash install.sh --verify-profile full
bash install.sh --verify-profile premium
bash install.sh --verify-profile dev

# Simulação não instala nem registra uma conclusão
bash install.sh --profile full --dry-run
```

A verificação mostra quantos pacotes básicos estão instalados e quais faltam. Os extras são verificados quando foram solicitados e registrados em uma instalação.

## Registro automático de cada etapa

A partir desta versão, o instalador armazena arquivos locais em:

```text
~/.local/state/linux-hybrid-v2/perfis-instalacao/
├── premium.state
├── dev.state
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

O `full` executa Developer e Premium separadamente. Se uma etapa falhar, as anteriores conservam seu estado e `full` recebe `falhou`. Se as etapas terminarem, mas alguma dependência não estiver presente, `full` será `parcial`.

**Instalações anteriores à implementação não são marcadas automaticamente como concluídas.** Mesmo um inventário 24/24 prova apenas a presença dos pacotes, não a origem da instalação ou a aplicação do tema/painel. Uma nova execução real e validada cria o registro.

As consultas `--status`, `--verify-profile`, `--list-profiles` e as simulações `--dry-run` **não escrevem estado**. As configurações visuais permanecem separadas em `~/.local/share/linux-hybrid/profiles/`.

Para investigar instalações parciais, consulte os logs `~/.local/state/linux-hybrid-v2/install-*.log` e o [guia de problemas](solucao-de-problemas.md).
