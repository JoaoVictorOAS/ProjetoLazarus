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
    Status     : string;
    DataInicio : string;
    DataFim    : string;
  end;

  TArrayProjeto  = array of TProjeto;
  TArrayInteger  = array of Integer;

  TProjetos = class
  public
    class function  Listar: TArrayProjeto;
    class function  BuscarPorId(AId: Integer): TProjeto;
    class function  Inserir(const AP: TProjeto): Integer;
    class procedure Atualizar(const AP: TProjeto);
    class procedure Encerrar(AId: Integer);
    class procedure AssociarMembro(AProjetoId, AMembroId: Integer);
    class procedure RemoverMembro(AProjetoId, AMembroId: Integer);
    class function  ListarMembros(AProjetoId: Integer): TArrayInteger;
    class function  StatusValidos: TStringArray;
  end;

implementation

class function TProjetos.StatusValidos: TStringArray;
begin
  Result := TStringArray.Create('ativo','pausado','encerrado');
end;

class function TProjetos.Listar: TArrayProjeto;
var
  Q: TSQLQuery;
  Lista: TArrayProjeto;
  Idx: Integer;
begin
  Q := TDBConnection.NewQuery;
  try
    Q.SQL.Text :=
      'SELECT id, nome, descricao, status, ' +
      'TO_CHAR(data_inicio,''YYYY-MM-DD'') AS data_inicio, ' +
      'TO_CHAR(data_fim,''YYYY-MM-DD'') AS data_fim ' +
      'FROM projetos ORDER BY id DESC';
    Q.Open;
    SetLength(Lista, 0);
    Idx := 0;
    while not Q.EOF do
    begin
      SetLength(Lista, Idx + 1);
      Lista[Idx].Id         := Q.FieldByName('id').AsInteger;
      Lista[Idx].Nome       := Q.FieldByName('nome').AsString;
      Lista[Idx].Descricao  := Q.FieldByName('descricao').AsString;
      Lista[Idx].Status     := Q.FieldByName('status').AsString;
      Lista[Idx].DataInicio := Q.FieldByName('data_inicio').AsString;
      Lista[Idx].DataFim    := Q.FieldByName('data_fim').AsString;
      Inc(Idx);
      Q.Next;
    end;
    Result := Lista;
  finally
    Q.Close;
    Q.Free;
  end;
end;

class function TProjetos.BuscarPorId(AId: Integer): TProjeto;
var
  Q: TSQLQuery;
begin
  Q := TDBConnection.NewQuery;
  try
    Q.SQL.Text :=
      'SELECT id, nome, descricao, status, ' +
      'TO_CHAR(data_inicio,''YYYY-MM-DD'') AS data_inicio, ' +
      'TO_CHAR(data_fim,''YYYY-MM-DD'') AS data_fim ' +
      'FROM projetos WHERE id = :id';
    Q.Params.ParamByName('id').AsInteger := AId;
    Q.Open;
    if Q.EOF then
      raise Exception.CreateFmt('Projeto %d não encontrado', [AId]);
    Result.Id         := Q.FieldByName('id').AsInteger;
    Result.Nome       := Q.FieldByName('nome').AsString;
    Result.Descricao  := Q.FieldByName('descricao').AsString;
    Result.Status     := Q.FieldByName('status').AsString;
    Result.DataInicio := Q.FieldByName('data_inicio').AsString;
    Result.DataFim    := Q.FieldByName('data_fim').AsString;
  finally
    Q.Close;
    Q.Free;
  end;
end;

class function TProjetos.Inserir(const AP: TProjeto): Integer;
var
  Q: TSQLQuery;
begin
  Q := TDBConnection.NewQuery;
  try
    Q.SQL.Text :=
      'INSERT INTO projetos (nome, descricao, data_inicio) ' +
      'VALUES (:nome, :desc, :inicio::DATE) RETURNING id';
    Q.Params.ParamByName('nome').AsString   := AP.Nome;
    Q.Params.ParamByName('desc').AsString   := AP.Descricao;
    Q.Params.ParamByName('inicio').AsString := AP.DataInicio;
    Q.Open;
    Result := Q.FieldByName('id').AsInteger;
    TDBConnection.Commit;
  finally
    Q.Close;
    Q.Free;
  end;
end;

class procedure TProjetos.Atualizar(const AP: TProjeto);
var
  Q: TSQLQuery;
begin
  Q := TDBConnection.NewQuery;
  try
    Q.SQL.Text :=
      'UPDATE projetos SET nome=:nome, descricao=:desc, status=:status, ' +
      'data_inicio=:inicio::DATE, data_fim=:fim::DATE WHERE id=:id';
    Q.Params.ParamByName('nome').AsString   := AP.Nome;
    Q.Params.ParamByName('desc').AsString   := AP.Descricao;
    Q.Params.ParamByName('status').AsString := AP.Status;
    Q.Params.ParamByName('inicio').AsString := AP.DataInicio;
    Q.Params.ParamByName('fim').AsString    := AP.DataFim;
    Q.Params.ParamByName('id').AsInteger    := AP.Id;
    Q.ExecSQL;
    TDBConnection.Commit;
  finally
    Q.Close;
    Q.Free;
  end;
end;

class procedure TProjetos.Encerrar(AId: Integer);
var
  Q: TSQLQuery;
begin
  Q := TDBConnection.NewQuery;
  try
    Q.SQL.Text :=
      'UPDATE projetos SET status=''encerrado'', data_fim=CURRENT_DATE WHERE id=:id';
    Q.Params.ParamByName('id').AsInteger := AId;
    Q.ExecSQL;
    TDBConnection.Commit;
  finally
    Q.Close;
    Q.Free;
  end;
end;

class procedure TProjetos.AssociarMembro(AProjetoId, AMembroId: Integer);
var
  Q: TSQLQuery;
begin
  Q := TDBConnection.NewQuery;
  try
    Q.SQL.Text :=
      'INSERT INTO projeto_membros (projeto_id, membro_id) VALUES (:pid, :mid) ' +
      'ON CONFLICT DO NOTHING';
    Q.Params.ParamByName('pid').AsInteger := AProjetoId;
    Q.Params.ParamByName('mid').AsInteger := AMembroId;
    Q.ExecSQL;
    TDBConnection.Commit;
  finally
    Q.Close;
    Q.Free;
  end;
end;

class procedure TProjetos.RemoverMembro(AProjetoId, AMembroId: Integer);
var
  Q: TSQLQuery;
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
    Q.Close;
    Q.Free;
  end;
end;

class function TProjetos.ListarMembros(AProjetoId: Integer): TArrayInteger;
var
  Q: TSQLQuery;
  Lista: TArrayInteger;
  Idx: Integer;
begin
  Q := TDBConnection.NewQuery;
  try
    Q.SQL.Text :=
      'SELECT membro_id FROM projeto_membros WHERE projeto_id=:pid';
    Q.Params.ParamByName('pid').AsInteger := AProjetoId;
    Q.Open;
    SetLength(Lista, 0);
    Idx := 0;
    while not Q.EOF do
    begin
      SetLength(Lista, Idx + 1);
      Lista[Idx] := Q.FieldByName('membro_id').AsInteger;
      Inc(Idx);
      Q.Next;
    end;
    Result := Lista;
  finally
    Q.Close;
    Q.Free;
  end;
end;

end.
