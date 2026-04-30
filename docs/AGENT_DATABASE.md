# AGENT_DATABASE.md
> Leia CLAUDE.md antes deste arquivo.

## Responsabilidade
Tudo relacionado ao banco PostgreSQL: conexão, configuração, queries base, utilitário `UDBConnection`.

## Diferenças PostgreSQL vs SQLite — leia antes de codar
| Ponto | SQLite | PostgreSQL |
|---|---|---|
| Componente | `TSQLite3Connection` | `TPQConnection` |
| Unit | `sqlite3conn` | `pqconnection` |
| Last insert ID | `last_insert_rowid()` | `RETURNING id` |
| Auto-increment | `AUTOINCREMENT` | `SERIAL` |
| Boolean | `INTEGER 0/1` | `BOOLEAN true/false` |
| Now | `datetime('now')` | `NOW()` |
| Intervalo | `date('now','+14 days')` | `NOW() + INTERVAL '14 days'` |
| Coluna gerada | `VIRTUAL` | `STORED` |

## config.ini — credenciais fora do código

Criar na pasta do executável:
```ini
[database]
host=localhost
port=5432
database=agile_db
user=agile
password=agile123
```

## UDBConnection.pas

```pascal
unit UDBConnection;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, IniFiles, pqconnection, sqldb;

type
  TDBConnection = class
  private
    class var FConn : TPQConnection;
    class var FTrans: TSQLTransaction;
  public
    class procedure Initialize(const AConfigPath: string);
    class procedure Finalize;
    class function  Connection: TPQConnection;
    class function  Transaction: TSQLTransaction;
    class function  NewQuery: TSQLQuery;
    class procedure Commit;
    class procedure Rollback;
  end;

implementation

class procedure TDBConnection.Initialize(const AConfigPath: string);
var Ini: TIniFile;
begin
  Ini := TIniFile.Create(AConfigPath);
  try
    FConn  := TPQConnection.Create(nil);
    FTrans := TSQLTransaction.Create(nil);
    FConn.Transaction := FTrans;
    FTrans.DataBase   := FConn;
    FConn.HostName     := Ini.ReadString('database', 'host',     'localhost');
    FConn.DatabaseName := Ini.ReadString('database', 'database', 'agile_db');
    FConn.UserName     := Ini.ReadString('database', 'user',     'agile');
    FConn.Password     := Ini.ReadString('database', 'password', '');
    FConn.Port         := Ini.ReadInteger('database','port',      5432);
    FConn.Open;
  finally
    Ini.Free;
  end;
end;

class procedure TDBConnection.Finalize;
begin
  FTrans.Commit;
  FConn.Close;
  FTrans.Free;
  FConn.Free;
end;

class function TDBConnection.Connection: TPQConnection;
begin Result := FConn; end;

class function TDBConnection.Transaction: TSQLTransaction;
begin Result := FTrans; end;

class function TDBConnection.NewQuery: TSQLQuery;
begin
  Result := TSQLQuery.Create(nil);
  Result.DataBase    := FConn;
  Result.Transaction := FTrans;
end;

class procedure TDBConnection.Commit;
begin FTrans.Commit; end;

class procedure TDBConnection.Rollback;
begin FTrans.Rollback; end;

end.
```

## Program principal

```pascal
TDBConnection.Initialize(ExtractFilePath(ParamStr(0)) + 'config.ini');
```

## Padrão INSERT com RETURNING (obrigatório no PostgreSQL)

```pascal
// NEVER use ExecSQL + last_insert_rowid() — isso é SQLite
// No PostgreSQL: RETURNING id + Q.Open
Q.SQL.Text :=
  'INSERT INTO projetos (nome, descricao) VALUES (:nome, :desc) RETURNING id';
Q.Params.ParamByName('nome').AsString := ANome;
Q.Params.ParamByName('desc').AsString := ADesc;
Q.Open;
Result := Q.FieldByName('id').AsInteger;
TDBConnection.Commit;
```

## Tabelas e colunas rápidas
| Tabela | Colunas-chave |
|---|---|
| membros | id, nome, papel, email, ativo (BOOLEAN) |
| projetos | id, nome, descricao, status, data_inicio, data_fim |
| projeto_membros | projeto_id, membro_id |
| sprints | id, projeto_id, numero, goal, capacidade_pts, status, data_inicio, data_fim |
| tarefas | id, sprint_id, membro_id, titulo, tipo, status, pontos, prioridade, criado_em, atualizado_em |
| horas_tecnicas | id, tarefa_id, membro_id, tipo, inicio, fim, total_min (STORED), obs |

## Views disponíveis
- `v_horas_por_tarefa`
- `v_horas_por_sprint_tipo`
- `v_velocity`

## Setup no Lazarus
1. **Package → Install/Uninstall Packages** → instalar `pqconnection`
2. Windows: copiar `libpq.dll` para a pasta do executável
3. Linux: `apt install libpq-dev`
