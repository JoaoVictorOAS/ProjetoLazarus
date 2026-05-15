# AgileLazarus (ProjetoLazarus)

Ferramenta de gestão ágil com:
- cadastro de membros, projetos, sprints e tarefas;
- apontamento de horas técnicas;
- métricas de acompanhamento (como velocity e produtividade).

Projeto acadêmico em **Free Pascal/Lazarus** com banco **PostgreSQL** via SQLdb (`TPQConnection`).

## Tecnologias

- Free Pascal 3.x
- Lazarus 3.x (LCL)
- PostgreSQL 16
- SQLdb (`TPQConnection`, `TSQLTransaction`, `TSQLQuery`)
- TAChart (`TChart`) para gráficos

## Estrutura do repositório

```text
ProjetoLazarus/
├── CLAUDE.md
├── README.md
├── config.ini
├── docs/
│   ├── AGENT_DATABASE.md
│   ├── AGENT_MEMBROS.md
│   ├── AGENT_PROJETOS.md
│   ├── AGENT_SPRINTS.md
│   ├── AGENT_TAREFAS.md
│   ├── AGENT_HORAS.md
│   └── AGENT_METRICAS.md
├── sql/
│   └── create_database.sql
└── src/
    ├── AgileLazarus.lpi
    ├── AgileLazarus.lpr
    ├── utils/
    │   └── UDBConnection.pas
    ├── modules/
    └── forms/
```

## Pré-requisitos

1. Lazarus + Free Pascal instalados.
2. PostgreSQL em execução.
3. Banco e usuário configurados.

## Configuração do banco

Execute o script:

```sql
sql/create_database.sql
```

Ele cria as tabelas principais (`membros`, `projetos`, `sprints`, `tarefas`, `horas_tecnicas`), views de métricas e dados iniciais.

## Configuração da aplicação (`config.ini`)

A aplicação lê as credenciais pelo `config.ini`:

```ini
[database]
host=localhost
port=5432
database=agile_db
user=agile
password=agile123
```

> Em produção, mantenha credenciais reais fora do versionamento.

## Como executar

### Opção 1: Lazarus IDE
1. Abra `src/AgileLazarus.lpi`.
2. Compile e execute pela IDE.

### Opção 2: linha de comando
```bash
lazbuild src/AgileLazarus.lpi
```

## Módulos implementados

- `UMembros` / `FMembros`
- `UProjetos` / `FProjetos`
- `USprints` / `FSprints`
- `UTarefas` / `FTarefas`
- `UHorasTecnicas` / `FHorasTecnicas`
- `UMetricas` / `FMetricas`
