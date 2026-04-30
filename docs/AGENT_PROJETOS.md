# AGENT_PROJETOS.md
> Leia CLAUDE.md + AGENT_DATABASE.md antes deste arquivo.

## Responsabilidade
CRUD de projetos e associação de membros ao projeto.

## UProjetos.pas

```pascal
unit UProjetos;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, sqldb, UDBConnection;

type
  TProjeto = record
    Id         : Integer;
    Nome       : string;
    Descricao  : string;
    Status     : string; // 'ativo','pausado','encerrado'
    DataInicio : string; // 'YYYY-MM-DD'
    DataFim    : string;
  end;

  TProjetos = class
  public
    class function  Listar: TArray<TProjeto>;
    class function  BuscarPorId(AId: Integer): TProjeto;
    class function  Inserir(const AP: TProjeto): Integer;
    class procedure Atualizar(const AP: TProjeto);
    class procedure Encerrar(AId: Integer);
    class procedure AssociarMembro(AProjetoId, AMembroId: Integer);
    class procedure RemoverMembro(AProjetoId, AMembroId: Integer);
    class function  ListarMembros(AProjetoId: Integer): TArray<Integer>;
    class function  StatusValidos: TStringArray;
  end;

implementation

class function TProjetos.StatusValidos: TStringArray;
begin
  Result := TStringArray.Create('ativo','pausado','encerrado');
end;

class function TProjetos.Listar: TArray<TProjeto>;
var
  Q: TSQLQuery;
  Lista: TArray<TProjeto>;
  Idx: Integer;
begin
  Q := TDBConnection.NewQuery;
  try
    Q.SQL.Text :=
      'SELECT id, nome, descricao, status, data_inicio, data_fim ' +
      'FROM projetos ORDER BY id DESC';
    Q.Open;
    SetLength(Lista, 0); Idx := 0;
    while not Q.EOF do
    begin
      SetLength(Lista, Idx + 1);
      Lista[Idx].Id         := Q.FieldByName('id').AsInteger;
      Lista[Idx].Nome       := Q.FieldByName('nome').AsString;
      Lista[Idx].Descricao  := Q.FieldByName('descricao').AsString;
      Lista[Idx].Status     := Q.FieldByName('status').AsString;
      Lista[Idx].DataInicio := Q.FieldByName('data_inicio').AsString;
      Lista[Idx].DataFim    := Q.FieldByName('data_fim').AsString;
      Inc(Idx); Q.Next;
    end;
    Result := Lista;
  finally
    Q.Close; Q.Free;
  end;
end;

class function TProjetos.BuscarPorId(AId: Integer): TProjeto;
var Q: TSQLQuery;
begin
  Q := TDBConnection.NewQuery;
  try
    Q.SQL.Text :=
      'SELECT id, nome, descricao, status, data_inicio, data_fim ' +
      'FROM projetos WHERE id = :id';
    Q.Params.ParamByName('id').AsInteger := AId;
    Q.Open;
    if Q.EOF then raise Exception.CreateFmt('Projeto %d não encontrado', [AId]);
    Result.Id         := Q.FieldByName('id').AsInteger;
    Result.Nome       := Q.FieldByName('nome').AsString;
    Result.Descricao  := Q.FieldByName('descricao').AsString;
    Result.Status     := Q.FieldByName('status').AsString;
    Result.DataInicio := Q.FieldByName('data_inicio').AsString;
    Result.DataFim    := Q.FieldByName('data_fim').AsString;
  finally
    Q.Close; Q.Free;
  end;
end;

class function TProjetos.Inserir(const AP: TProjeto): Integer;
var Q: TSQLQuery;
begin
  Q := TDBConnection.NewQuery;
  try
    Q.SQL.Text :=
      'INSERT INTO projetos (nome, descricao, data_inicio) ' +
      'VALUES (:nome, :desc, :inicio)';
    Q.Params.ParamByName('nome').AsString   := AP.Nome;
    Q.Params.ParamByName('desc').AsString   := AP.Descricao;
    Q.Params.ParamByName('inicio').AsString := AP.DataInicio;
    Q.ExecSQL;
    TDBConnection.Commit;
    Q.SQL.Text := 'SELECT last_insert_rowid() AS id';
    Q.Open;
    Result := Q.FieldByName('id').AsInteger;
  finally
    Q.Close; Q.Free;
  end;
end;

class procedure TProjetos.Atualizar(const AP: TProjeto);
var Q: TSQLQuery;
begin
  Q := TDBConnection.NewQuery;
  try
    Q.SQL.Text :=
      'UPDATE projetos SET nome=:nome, descricao=:desc, status=:status, ' +
      'data_inicio=:inicio, data_fim=:fim WHERE id=:id';
    Q.Params.ParamByName('nome').AsString   := AP.Nome;
    Q.Params.ParamByName('desc').AsString   := AP.Descricao;
    Q.Params.ParamByName('status').AsString := AP.Status;
    Q.Params.ParamByName('inicio').AsString := AP.DataInicio;
    Q.Params.ParamByName('fim').AsString    := AP.DataFim;
    Q.Params.ParamByName('id').AsInteger    := AP.Id;
    Q.ExecSQL;
    TDBConnection.Commit;
  finally
    Q.Close; Q.Free;
  end;
end;

class procedure TProjetos.Encerrar(AId: Integer);
var Q: TSQLQuery;
begin
  Q := TDBConnection.NewQuery;
  try
    Q.SQL.Text :=
      'UPDATE projetos SET status=''encerrado'', data_fim=date(''now'') WHERE id=:id';
    Q.Params.ParamByName('id').AsInteger := AId;
    Q.ExecSQL;
    TDBConnection.Commit;
  finally
    Q.Close; Q.Free;
  end;
end;

class procedure TProjetos.AssociarMembro(AProjetoId, AMembroId: Integer);
var Q: TSQLQuery;
begin
  Q := TDBConnection.NewQuery;
  try
    Q.SQL.Text :=
      'INSERT OR IGNORE INTO projeto_membros (projeto_id, membro_id) VALUES (:pid, :mid)';
    Q.Params.ParamByName('pid').AsInteger := AProjetoId;
    Q.Params.ParamByName('mid').AsInteger := AMembroId;
    Q.ExecSQL;
    TDBConnection.Commit;
  finally
    Q.Close; Q.Free;
  end;
end;

class procedure TProjetos.RemoverMembro(AProjetoId, AMembroId: Integer);
var Q: TSQLQuery;
begin
  Q := TDBConnection.NewQuery;
  try
    Q.SQL.Text :=
      'DELETE FROM projeto_membros WHERE projeto_id=:pid AND membro_id=:mid';
    Q.Params.ParamByName('pid').AsInteger := AProjetoId;
    Q.Params.ParamByName('mid').AsInteger := AMembroId;
    Q.ExecSQL;
    TDBConnection.Commit;
  finally
    Q.Close; Q.Free;
  end;
end;

class function TProjetos.ListarMembros(AProjetoId: Integer): TArray<Integer>;
var Q: TSQLQuery; Lista: TArray<Integer>; Idx: Integer;
begin
  Q := TDBConnection.NewQuery;
  try
    Q.SQL.Text := 'SELECT membro_id FROM projeto_membros WHERE projeto_id=:pid';
    Q.Params.ParamByName('pid').AsInteger := AProjetoId;
    Q.Open;
    SetLength(Lista, 0); Idx := 0;
    while not Q.EOF do
    begin
      SetLength(Lista, Idx + 1);
      Lista[Idx] := Q.FieldByName('membro_id').AsInteger;
      Inc(Idx); Q.Next;
    end;
    Result := Lista;
  finally
    Q.Close; Q.Free;
  end;
end;

end.
```

## FProjetos — orientação de layout
- Lista de projetos em `TStringGrid`: ID | Nome | Status | Início | Fim
- Badge de status colorido via `OnDrawCell` do StringGrid (verde=ativo, cinza=encerrado)
- Painel de edição com: `TEdit` nome, `TMemo` descrição, `TComboBox` status, `TDateEdit` datas
- Aba "Membros" com dois `TListBox`: disponíveis (esquerda) ↔ no projeto (direita), botões >> e <<
