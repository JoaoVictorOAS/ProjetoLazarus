# AGENT_TAREFAS.md
> Leia CLAUDE.md + AGENT_DATABASE.md antes deste arquivo.

## Responsabilidade
CRUD de tarefas, backlog e kanban (mudança de status).

## UTarefas.pas

```pascal
unit UTarefas;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, sqldb, UDBConnection;

type
  TTarefa = record
    Id        : Integer;
    SprintId  : Integer; // 0 = backlog
    MembroId  : Integer; // 0 = não atribuído
    Titulo    : string;
    Descricao : string;
    Tipo      : string; // 'story','bug','task','spike'
    Status    : string; // 'backlog','todo','doing','review','done'
    Pontos    : Integer;
    Prioridade: Integer; // 1-5
  end;

  TTarefas = class
  public
    class function  ListarPorSprint(ASprintId: Integer): TArray<TTarefa>;
    class function  ListarBacklog(AProjetoId: Integer): TArray<TTarefa>;
    class function  BuscarPorId(AId: Integer): TTarefa;
    class function  Inserir(const AT: TTarefa): Integer;
    class procedure Atualizar(const AT: TTarefa);
    class procedure MoverStatus(AId: Integer; const ANovoStatus: string);
    class procedure AtribuirSprint(ATarefaId, ASprintId: Integer);
    class procedure Deletar(AId: Integer);
    class function  StatusValidos: TStringArray;
    class function  TiposValidos: TStringArray;
  end;

implementation

class function TTarefas.StatusValidos: TStringArray;
begin
  Result := TStringArray.Create('backlog','todo','doing','review','done');
end;

class function TTarefas.TiposValidos: TStringArray;
begin
  Result := TStringArray.Create('story','bug','task','spike');
end;

class function TTarefas.ListarPorSprint(ASprintId: Integer): TArray<TTarefa>;
var Q: TSQLQuery; Lista: TArray<TTarefa>; Idx: Integer;
begin
  Q := TDBConnection.NewQuery;
  try
    Q.SQL.Text :=
      'SELECT id, sprint_id, membro_id, titulo, descricao, tipo, status, pontos, prioridade ' +
      'FROM tarefas WHERE sprint_id = :sid ORDER BY prioridade DESC, id';
    Q.Params.ParamByName('sid').AsInteger := ASprintId;
    Q.Open;
    SetLength(Lista, 0); Idx := 0;
    while not Q.EOF do
    begin
      SetLength(Lista, Idx + 1);
      Lista[Idx].Id         := Q.FieldByName('id').AsInteger;
      Lista[Idx].SprintId   := Q.FieldByName('sprint_id').AsInteger;
      Lista[Idx].MembroId   := Q.FieldByName('membro_id').AsInteger;
      Lista[Idx].Titulo     := Q.FieldByName('titulo').AsString;
      Lista[Idx].Descricao  := Q.FieldByName('descricao').AsString;
      Lista[Idx].Tipo       := Q.FieldByName('tipo').AsString;
      Lista[Idx].Status     := Q.FieldByName('status').AsString;
      Lista[Idx].Pontos     := Q.FieldByName('pontos').AsInteger;
      Lista[Idx].Prioridade := Q.FieldByName('prioridade').AsInteger;
      Inc(Idx); Q.Next;
    end;
    Result := Lista;
  finally
    Q.Close; Q.Free;
  end;
end;

class function TTarefas.ListarBacklog(AProjetoId: Integer): TArray<TTarefa>;
var Q: TSQLQuery; Lista: TArray<TTarefa>; Idx: Integer;
begin
  Q := TDBConnection.NewQuery;
  try
    // tarefas sem sprint que pertencem ao projeto via sprints
    Q.SQL.Text :=
      'SELECT t.id, t.sprint_id, t.membro_id, t.titulo, t.descricao, ' +
      't.tipo, t.status, t.pontos, t.prioridade ' +
      'FROM tarefas t ' +
      'LEFT JOIN sprints s ON s.id = t.sprint_id ' +
      'WHERE (t.sprint_id IS NULL OR s.projeto_id = :pid) ' +
      'AND t.status = ''backlog'' ' +
      'ORDER BY t.prioridade DESC, t.id';
    Q.Params.ParamByName('pid').AsInteger := AProjetoId;
    Q.Open;
    SetLength(Lista, 0); Idx := 0;
    while not Q.EOF do
    begin
      SetLength(Lista, Idx + 1);
      Lista[Idx].Id         := Q.FieldByName('id').AsInteger;
      Lista[Idx].SprintId   := Q.FieldByName('sprint_id').AsInteger;
      Lista[Idx].MembroId   := Q.FieldByName('membro_id').AsInteger;
      Lista[Idx].Titulo     := Q.FieldByName('titulo').AsString;
      Lista[Idx].Descricao  := Q.FieldByName('descricao').AsString;
      Lista[Idx].Tipo       := Q.FieldByName('tipo').AsString;
      Lista[Idx].Status     := Q.FieldByName('status').AsString;
      Lista[Idx].Pontos     := Q.FieldByName('pontos').AsInteger;
      Lista[Idx].Prioridade := Q.FieldByName('prioridade').AsInteger;
      Inc(Idx); Q.Next;
    end;
    Result := Lista;
  finally
    Q.Close; Q.Free;
  end;
end;

class function TTarefas.BuscarPorId(AId: Integer): TTarefa;
var Q: TSQLQuery;
begin
  Q := TDBConnection.NewQuery;
  try
    Q.SQL.Text :=
      'SELECT id, sprint_id, membro_id, titulo, descricao, tipo, status, pontos, prioridade ' +
      'FROM tarefas WHERE id = :id';
    Q.Params.ParamByName('id').AsInteger := AId;
    Q.Open;
    if Q.EOF then raise Exception.CreateFmt('Tarefa %d não encontrada', [AId]);
    Result.Id         := Q.FieldByName('id').AsInteger;
    Result.SprintId   := Q.FieldByName('sprint_id').AsInteger;
    Result.MembroId   := Q.FieldByName('membro_id').AsInteger;
    Result.Titulo     := Q.FieldByName('titulo').AsString;
    Result.Descricao  := Q.FieldByName('descricao').AsString;
    Result.Tipo       := Q.FieldByName('tipo').AsString;
    Result.Status     := Q.FieldByName('status').AsString;
    Result.Pontos     := Q.FieldByName('pontos').AsInteger;
    Result.Prioridade := Q.FieldByName('prioridade').AsInteger;
  finally
    Q.Close; Q.Free;
  end;
end;

class function TTarefas.Inserir(const AT: TTarefa): Integer;
var Q: TSQLQuery;
begin
  Q := TDBConnection.NewQuery;
  try
    Q.SQL.Text :=
      'INSERT INTO tarefas (sprint_id, membro_id, titulo, descricao, tipo, status, pontos, prioridade) ' +
      'VALUES (:sid, :mid, :titulo, :desc, :tipo, :status, :pts, :prio)';
    if AT.SprintId > 0 then
      Q.Params.ParamByName('sid').AsInteger := AT.SprintId
    else
      Q.Params.ParamByName('sid').Clear;
    if AT.MembroId > 0 then
      Q.Params.ParamByName('mid').AsInteger := AT.MembroId
    else
      Q.Params.ParamByName('mid').Clear;
    Q.Params.ParamByName('titulo').AsString  := AT.Titulo;
    Q.Params.ParamByName('desc').AsString    := AT.Descricao;
    Q.Params.ParamByName('tipo').AsString    := AT.Tipo;
    Q.Params.ParamByName('status').AsString  := AT.Status;
    Q.Params.ParamByName('pts').AsInteger    := AT.Pontos;
    Q.Params.ParamByName('prio').AsInteger   := AT.Prioridade;
    Q.ExecSQL;
    TDBConnection.Commit;
    Q.SQL.Text := 'SELECT last_insert_rowid() AS id';
    Q.Open;
    Result := Q.FieldByName('id').AsInteger;
  finally
    Q.Close; Q.Free;
  end;
end;

class procedure TTarefas.Atualizar(const AT: TTarefa);
var Q: TSQLQuery;
begin
  Q := TDBConnection.NewQuery;
  try
    Q.SQL.Text :=
      'UPDATE tarefas SET titulo=:titulo, descricao=:desc, tipo=:tipo, status=:status, ' +
      'pontos=:pts, prioridade=:prio, membro_id=:mid, ' +
      'atualizado_em=datetime(''now'') WHERE id=:id';
    Q.Params.ParamByName('titulo').AsString  := AT.Titulo;
    Q.Params.ParamByName('desc').AsString    := AT.Descricao;
    Q.Params.ParamByName('tipo').AsString    := AT.Tipo;
    Q.Params.ParamByName('status').AsString  := AT.Status;
    Q.Params.ParamByName('pts').AsInteger    := AT.Pontos;
    Q.Params.ParamByName('prio').AsInteger   := AT.Prioridade;
    if AT.MembroId > 0 then
      Q.Params.ParamByName('mid').AsInteger := AT.MembroId
    else
      Q.Params.ParamByName('mid').Clear;
    Q.Params.ParamByName('id').AsInteger := AT.Id;
    Q.ExecSQL;
    TDBConnection.Commit;
  finally
    Q.Close; Q.Free;
  end;
end;

class procedure TTarefas.MoverStatus(AId: Integer; const ANovoStatus: string);
var Q: TSQLQuery;
begin
  Q := TDBConnection.NewQuery;
  try
    Q.SQL.Text :=
      'UPDATE tarefas SET status=:status, atualizado_em=datetime(''now'') WHERE id=:id';
    Q.Params.ParamByName('status').AsString := ANovoStatus;
    Q.Params.ParamByName('id').AsInteger    := AId;
    Q.ExecSQL;
    TDBConnection.Commit;
  finally
    Q.Close; Q.Free;
  end;
end;

class procedure TTarefas.AtribuirSprint(ATarefaId, ASprintId: Integer);
var Q: TSQLQuery;
begin
  Q := TDBConnection.NewQuery;
  try
    Q.SQL.Text := 'UPDATE tarefas SET sprint_id=:sid WHERE id=:id';
    Q.Params.ParamByName('sid').AsInteger := ASprintId;
    Q.Params.ParamByName('id').AsInteger  := ATarefaId;
    Q.ExecSQL;
    TDBConnection.Commit;
  finally
    Q.Close; Q.Free;
  end;
end;

class procedure TTarefas.Deletar(AId: Integer);
var Q: TSQLQuery;
begin
  Q := TDBConnection.NewQuery;
  try
    Q.SQL.Text := 'DELETE FROM tarefas WHERE id=:id';
    Q.Params.ParamByName('id').AsInteger := AId;
    Q.ExecSQL;
    TDBConnection.Commit;
  finally
    Q.Close; Q.Free;
  end;
end;

end.
```

## FTarefas — orientação de layout
- Kanban simplificado: 5 `TPanel` lado a lado (backlog | todo | doing | review | done)
- Cada coluna = `TListBox` com títulos das tarefas
- Botões → e ← para mover status
- Duplo-clique abre form de detalhe/edição da tarefa
- Filtro por sprint via dropdown no topo
