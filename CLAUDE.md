# CLAUDE.md — AgileLazarus
> Orquestrador principal. Leia este arquivo antes de qualquer coisa.

## Contexto do projeto
Ferramenta de gestão ágil com contagem de horas técnicas e métricas de software.
Desenvolvida em **Free Pascal / Lazarus** (LCL), banco **SQLite** via componente `TSQLite3Connection` do pacote SQLdb nativo do Lazarus.
Projeto escolar — arquitetura simples: **UI → módulo (unit Pascal) → banco**. Sem camada de serviço.

## Stack obrigatória
| Item | Tecnologia |
|---|---|
| Linguagem | Free Pascal 3.x |
| IDE/Framework UI | Lazarus 3.x + LCL |
| Banco | PostgreSQL 16 |
| Acesso ao banco | `TPQConnection` + `TSQLTransaction` + `TSQLQuery` (unit `pqconnection`, `sqldb`) |
| Gráficos | `TChart` (pacote TAChart nativo do Lazarus) |

## Regras de código Pascal — SEMPRE siga
1. Cada módulo = uma **unit** separada em `src/modules/`
2. Cada tela = uma **unit de form** em `src/forms/`
3. Utilitários compartilhados ficam em `src/utils/UDBConnection.pas`
4. **Nunca** abra conexão com o banco direto nos forms — use sempre `TDBConnection` de `UDBConnection`. Credenciais ficam em `config.ini` na pasta do executável, nunca hard-coded
5. Toda query usa **parâmetros nomeados** (`Params.ParamByName`) — nunca concatenação de string
6. Sempre feche `TSQLQuery` após uso (`Query.Close`)
7. Trate exceções com `try..except..finally` em toda operação de banco
8. Nomes: units com prefixo `U`, forms com prefixo `F` — ex: `UProjetos.pas`, `FProjetos.pas`
9. Strings de data sempre no formato `'YYYY-MM-DD HH:MM:SS'` para o SQLite
10. **Não use** componentes visuais de acesso a dados (DBGrid vinculado direto) — carregue dados manualmente em StringGrid ou ListView para ter controle total

## Estrutura de pastas
```
agile_lazarus/
├── CLAUDE.md                  ← este arquivo
├── agile.db                   ← banco SQLite (gerado)
├── sql/
│   └── create_database.sql    ← DDL completo + seed
├── docs/
│   └── agents/
│       ├── AGENT_DATABASE.md
│       ├── AGENT_PROJETOS.md
│       ├── AGENT_SPRINTS.md
│       ├── AGENT_TAREFAS.md
│       ├── AGENT_HORAS.md
│       ├── AGENT_MEMBROS.md
│       └── AGENT_METRICAS.md
└── src/
    ├── AgileLazarus.lpi        ← arquivo de projeto Lazarus
    ├── AgileLazarus.lpr        ← program principal
    ├── utils/
    │   └── UDBConnection.pas
    ├── modules/
    │   ├── UProjetos.pas
    │   ├── USprints.pas
    │   ├── UTarefas.pas
    │   ├── UHorasTecnicas.pas
    │   ├── UMembros.pas
    │   └── UMetricas.pas
    └── forms/
        ├── FMain.pas / FMain.lfm
        ├── FProjetos.pas / FProjetos.lfm
        ├── FSprints.pas / FSprints.lfm
        ├── FTarefas.pas / FTarefas.lfm
        ├── FHorasTecnicas.pas / FHorasTecnicas.lfm
        ├── FMembros.pas / FMembros.lfm
        └── FMetricas.pas / FMetricas.lfm

```

## Ordem de implementação
1. `UDBConnection` — conexão única compartilhada
2. `UMembros` + `FMembros` — entidade base sem dependências
3. `UProjetos` + `FProjetos`
4. `USprints` + `FSprints`
5. `UTarefas` + `FTarefas`
6. `UHorasTecnicas` + `FHorasTecnicas` — timer incluso
7. `UMetricas` + `FMetricas` — depende de todos os módulos acima

## Como chamar cada agente
Ao trabalhar em um módulo específico, carregue o agente correspondente:
- `docs/agents/AGENT_DATABASE.md` — estrutura do banco, DDL, queries
- `docs/agents/AGENT_PROJETOS.md` — módulo de projetos
- `docs/agents/AGENT_SPRINTS.md` — módulo de sprints
- `docs/agents/AGENT_TAREFAS.md` — módulo de tarefas e kanban
- `docs/agents/AGENT_HORAS.md` — contagem de horas técnicas e timer
- `docs/agents/AGENT_MEMBROS.md` — módulo de membros
- `docs/agents/AGENT_METRICAS.md` — cálculo e exibição de métricas
