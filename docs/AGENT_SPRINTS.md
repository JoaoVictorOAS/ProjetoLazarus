# AGENT_SPRINTS.md
> Leia CLAUDE.md + AGENT_DATABASE.md antes deste arquivo.

## Responsabilidade
CRUD de sprints vinculadas a um projeto.

## USprints.pas

```pascal
unit USprints;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, sqldb, UDBConnection;

type
  TSprint = record
    Id            : Integer;
    ProjetoId     : Integer;
    Numero        : Integer;
    Goal          : string;
    CapacidadePts : Integer;
    Status        : string; // 'planejada','ativa','encerrada'
    DataInicio    : string;
    DataFim       : string;
  end;

  TSprints = class
  public
    class function  ListarPorProjeto(AProjetoId: Integer): TArray<TSprint>;
    class function  BuscarAtiva(AProjetoId: Integer): TSprint;
    class function  BuscarPorId(AId: Integer): TSprint;
    class function  Inserir(const AS_: TSprint): Integer;
    class procedure Atualizar(const AS_: TSprint);
    class procedure IniciarSprint(AId: Integer);
    class procedure EncerrarSprint(AId: Integer);
    class function  ProximoNumero(AProjetoId: Integer): Integer;
  end;

implementation

class function TSprints.ProximoNumero(AProjetoId: Integer): Integer;
var Q: TSQLQuery;
begin
  Q := TDBConnection.NewQuery;
  try
    Q.SQL.Text :=
      'SELECT COALESCE(MAX(numero), 0) + 1 AS prox FROM sprints WHERE projeto_id = :pid';
    Q.Params.ParamByName('pid').AsInteger := AProjetoId;
    Q.Open;
    Result := Q.FieldByName('prox').AsInteger;
  finally
    Q.Close; Q.Free;
  end;
end;

class function TSprints.ListarPorProjeto(AProjetoId: Integer): TArray<TSprint>;
var Q: TSQLQuery; Lista: TArray<TSprint>; Idx: Integer;
begin
  Q := TDBConnection.NewQuery;
  try
    Q.SQL.Text :=
      'SELECT id, projeto_id, numero, goal, capacidade_pts, status, data_inicio, data_fim ' +
      'FROM sprints WHERE projeto_id = :pid ORDER BY numero DESC';
    Q.Params.ParamByName('pid').AsInteger := AProjetoId;
    Q.Open;
    SetLength(Lista, 0); Idx := 0;
    while not Q.EOF do
    begin
      SetLength(Lista, Idx + 1);
      Lista[Idx].Id            := Q.FieldByName('id').AsInteger;
      Lista[Idx].ProjetoId     := Q.FieldByName('projeto_id').AsInteger;
      Lista[Idx].Numero        := Q.FieldByName('numero').AsInteger;
      Lista[Idx].Goal          := Q.FieldByName('goal').AsString;
      Lista[Idx].CapacidadePts := Q.FieldByName('capacidade_pts').AsInteger;
      Lista[Idx].Status        := Q.FieldByName('status').AsString;
      Lista[Idx].DataInicio    := Q.FieldByName('data_inicio').AsString;
      Lista[Idx].DataFim       := Q.FieldByName('data_fim').AsString;
      Inc(Idx); Q.Next;
    end;
    Result := Lista;
  finally
    Q.Close; Q.Free;
  end;
end;

class function TSprints.BuscarAtiva(AProjetoId: Integer): TSprint;
var Q: TSQLQuery;
begin
  Q := TDBConnection.NewQuery;
  try
    Q.SQL.Text :=
      'SELECT id, projeto_id, numero, goal, capacidade_pts, status, data_inicio, data_fim ' +
      'FROM sprints WHERE projeto_id = :pid AND status = ''ativa'' LIMIT 1';
    Q.Params.ParamByName('pid').AsInteger := AProjetoId;
    Q.Open;
    if Q.EOF then
    begin
      Result.Id := 0; // nenhuma sprint ativa
      Exit;
    end;
    Result.Id            := Q.FieldByName('id').AsInteger;
    Result.ProjetoId     := Q.FieldByName('projeto_id').AsInteger;
    Result.Numero        := Q.FieldByName('numero').AsInteger;
    Result.Goal          := Q.FieldByName('goal').AsString;
    Result.CapacidadePts := Q.FieldByName('capacidade_pts').AsInteger;
    Result.Status        := Q.FieldByName('status').AsString;
    Result.DataInicio    := Q.FieldByName('data_inicio').AsString;
    Result.DataFim       := Q.FieldByName('data_fim').AsString;
  finally
    Q.Close; Q.Free;
  end;
end;

class function TSprints.BuscarPorId(AId: Integer): TSprint;
var Q: TSQLQuery;
begin
  Q := TDBConnection.NewQuery;
  try
    Q.SQL.Text :=
      'SELECT id, projeto_id, numero, goal, capacidade_pts, status, data_inicio, data_fim ' +
      'FROM sprints WHERE id = :id';
    Q.Params.ParamByName('id').AsInteger := AId;
    Q.Open;
    if Q.EOF then raise Exception.CreateFmt('Sprint %d não encontrada', [AId]);
    Result.Id            := Q.FieldByName('id').AsInteger;
    Result.ProjetoId     := Q.FieldByName('projeto_id').AsInteger;
    Result.Numero        := Q.FieldByName('numero').AsInteger;
    Result.Goal          := Q.FieldByName('goal').AsString;
    Result.CapacidadePts := Q.FieldByName('capacidade_pts').AsInteger;
    Result.Status        := Q.FieldByName('status').AsString;
    Result.DataInicio    := Q.FieldByName('data_inicio').AsString;
    Result.DataFim       := Q.FieldByName('data_fim').AsString;
  finally
    Q.Close; Q.Free;
  end;
end;

class function TSprints.Inserir(const AS_: TSprint): Integer;
var Q: TSQLQuery;
begin
  Q := TDBConnection.NewQuery;
  try
    Q.SQL.Text :=
      'INSERT INTO sprints (projeto_id, numero, goal, capacidade_pts, data_inicio, data_fim) ' +
      'VALUES (:pid, :num, :goal, :cap, :inicio, :fim)';
    Q.Params.ParamByName('pid').AsInteger   := AS_.ProjetoId;
    Q.Params.ParamByName('num').AsInteger   := AS_.Numero;
    Q.Params.ParamByName('goal').AsString   := AS_.Goal;
    Q.Params.ParamByName('cap').AsInteger   := AS_.CapacidadePts;
    Q.Params.ParamByName('inicio').AsString := AS_.DataInicio;
    Q.Params.ParamByName('fim').AsString    := AS_.DataFim;
    Q.ExecSQL;
    TDBConnection.Commit;
    Q.SQL.Text := 'SELECT last_insert_rowid() AS id';
    Q.Open;
    Result := Q.FieldByName('id').AsInteger;
  finally
    Q.Close; Q.Free;
  end;
end;

class procedure TSprints.Atualizar(const AS_: TSprint);
var Q: TSQLQuery;
begin
  Q := TDBConnection.NewQuery;
  try
    Q.SQL.Text :=
      'UPDATE sprints SET goal=:goal, capacidade_pts=:cap, ' +
      'data_inicio=:inicio, data_fim=:fim WHERE id=:id';
    Q.Params.ParamByName('goal').AsString   := AS_.Goal;
    Q.Params.ParamByName('cap').AsInteger   := AS_.CapacidadePts;
    Q.Params.ParamByName('inicio').AsString := AS_.DataInicio;
    Q.Params.ParamByName('fim').AsString    := AS_.DataFim;
    Q.Params.ParamByName('id').AsInteger    := AS_.Id;
    Q.ExecSQL;
    TDBConnection.Commit;
  finally
    Q.Close; Q.Free;
  end;
end;

class procedure TSprints.IniciarSprint(AId: Integer);
var Q: TSQLQuery;
begin
  Q := TDBConnection.NewQuery;
  try
    Q.SQL.Text :=
      'UPDATE sprints SET status=''ativa'', data_inicio=date(''now'') WHERE id=:id';
    Q.Params.ParamByName('id').AsInteger := AId;
    Q.ExecSQL;
    TDBConnection.Commit;
  finally
    Q.Close; Q.Free;
  end;
end;

class procedure TSprints.EncerrarSprint(AId: Integer);
var Q: TSQLQuery;
begin
  Q := TDBConnection.NewQuery;
  try
    Q.SQL.Text :=
      'UPDATE sprints SET status=''encerrada'', data_fim=date(''now'') WHERE id=:id';
    Q.Params.ParamByName('id').AsInteger := AId;
    Q.ExecSQL;
    TDBConnection.Commit;
  finally
    Q.Close; Q.Free;
  end;
end;

end.
```

## FSprints — orientação de layout
- Dropdown de projeto no topo para filtrar sprints
- `TStringGrid`: Nº | Goal | Status | Capacidade | Início | Fim
- Botões: Nova Sprint, Iniciar, Encerrar
- Número da sprint preenchido automaticamente via `ProximoNumero`
