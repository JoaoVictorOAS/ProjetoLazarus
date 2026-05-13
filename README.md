# ProjetoLazarus (AgileLazarus)

Ferramenta de gestão ágil com foco em:
- cadastro de membros, projetos, sprints e tarefas;
- apontamento de horas técnicas;
- métricas de acompanhamento (ex.: velocity e produtividade).

Projeto acadêmico em **Free Pascal/Lazarus**, com persistência em **PostgreSQL**.

## Tecnologias

- Free Pascal 3.x
- Lazarus 3.x (LCL)
- PostgreSQL 16
- SQLdb (`TPQConnection`, `TSQLTransaction`, `TSQLQuery`)

## Estrutura atual

```text
ProjetoLazarus/
├── CLAUDE.md
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
├── src/
│   ├── AgileLazarus.lpr
│   └── utils/
│       └── UDBConnection.pas
├── project1.lpi
├── project1.lpr
└── config.ini
```

## Pré-requisitos

1. Lazarus + Free Pascal instalados.
2. PostgreSQL rodando localmente.
3. Banco e usuário configurados (ou ajuste os dados no `config.ini`).

## Configuração do banco

Execute o script:

```sql
sql/create_database.sql
```

Ele cria tabelas principais (`membros`, `projetos`, `sprints`, `tarefas`, `horas_tecnicas`), views e dados iniciais.

## Arquivo de configuração

Crie/ajuste o `config.ini` na pasta do executável:

```ini
[database]
host=localhost
port=5432
database=agile_db
user=agile
password=agile123
```

> Recomenda-se usar credenciais próprias (não versionar segredos reais).

## Como executar

### Opção 1: Lazarus IDE
1. Abra `project1.lpi` no Lazarus.
2. Compile e execute pela IDE.

### Opção 2: linha de comando (se disponível)
```bash
lazbuild project1.lpi
```

## Status

O repositório contém a base do projeto e documentação de módulos em `docs/`.
A implementação completa segue a ordem definida em `CLAUDE.md`:
1. conexão (`UDBConnection`);
2. membros;
3. projetos;
4. sprints;
5. tarefas;
6. horas técnicas;
7. métricas.
