# AGENT_MEMBROS.md
> Leia CLAUDE.md + AGENT_DATABASE.md antes deste arquivo.

## Responsabilidade
CRUD completo de membros da equipe. Entidade base — sem dependências externas.

## UMembros.pas

```pascal
unit UMembros;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, sqldb, UDBConnection;

type
  TMembro = record
    Id    : Integer;
    Nome  : string;
    Papel : string;  // 'dev','qa','po','sm','designer','outro'
    Email : string;
    Ativo : Boolean;
  end;

  TMembros = class
  public
    class function  Listar(ApenasAtivos: Boolean = True): TArray<TMembro>;
    class function  BuscarPorId(AId: Integer): TMembro;
    class function  Inserir(const AMembro: TMembro): Integer;
    class procedure Atualizar(const AMembro: TMembro);
    class procedure Desativar(AId: Integer);
    class function  PapeisValidos: TStringArray;
  end;

implementation

class function TMembros.PapeisValidos: TStringArray;
begin
  Result := TStringArray.Create('dev','qa','po','sm','designer','outro');
end;

class function TMembros.Listar(ApenasAtivos: Boolean): TArray<TMembro>;
var
  Q: TSQLQuery;
  Lista: TArray<TMembro>;
  Idx: Integer;
begin
  Q := TDBConnection.NewQuery;
  try
    if ApenasAtivos then
      Q.SQL.Text := 'SELECT id, nome, papel, email, ativo FROM membros WHERE ativo = 1 ORDER BY nome'
    else
      Q.SQL.Text := 'SELECT id, nome, papel, email, ativo FROM membros ORDER BY nome';
    Q.Open;
    SetLength(Lista, 0);
    Idx := 0;
    while not Q.EOF do
    begin
      SetLength(Lista, Idx + 1);
      Lista[Idx].Id    := Q.FieldByName('id').AsInteger;
      Lista[Idx].Nome  := Q.FieldByName('nome').AsString;
      Lista[Idx].Papel := Q.FieldByName('papel').AsString;
      Lista[Idx].Email := Q.FieldByName('email').AsString;
      Lista[Idx].Ativo := Q.FieldByName('ativo').AsInteger = 1;
      Inc(Idx);
      Q.Next;
    end;
    Result := Lista;
  finally
    Q.Close;
    Q.Free;
  end;
end;

class function TMembros.BuscarPorId(AId: Integer): TMembro;
var Q: TSQLQuery;
begin
  Q := TDBConnection.NewQuery;
  try
    Q.SQL.Text := 'SELECT id, nome, papel, email, ativo FROM membros WHERE id = :id';
    Q.Params.ParamByName('id').AsInteger := AId;
    Q.Open;
    if Q.EOF then raise Exception.CreateFmt('Membro %d não encontrado', [AId]);
    Result.Id    := Q.FieldByName('id').AsInteger;
    Result.Nome  := Q.FieldByName('nome').AsString;
    Result.Papel := Q.FieldByName('papel').AsString;
    Result.Email := Q.FieldByName('email').AsString;
    Result.Ativo := Q.FieldByName('ativo').AsInteger = 1;
  finally
    Q.Close;
    Q.Free;
  end;
end;

class function TMembros.Inserir(const AMembro: TMembro): Integer;
var Q: TSQLQuery;
begin
  Q := TDBConnection.NewQuery;
  try
    Q.SQL.Text :=
      'INSERT INTO membros (nome, papel, email) VALUES (:nome, :papel, :email)';
    Q.Params.ParamByName('nome').AsString  := AMembro.Nome;
    Q.Params.ParamByName('papel').AsString := AMembro.Papel;
    Q.Params.ParamByName('email').AsString := AMembro.Email;
    Q.ExecSQL;
    TDBConnection.Commit;
    Q.SQL.Text := 'SELECT last_insert_rowid() AS id';
    Q.Open;
    Result := Q.FieldByName('id').AsInteger;
  finally
    Q.Close;
    Q.Free;
  end;
end;

class procedure TMembros.Atualizar(const AMembro: TMembro);
var Q: TSQLQuery;
begin
  Q := TDBConnection.NewQuery;
  try
    Q.SQL.Text :=
      'UPDATE membros SET nome=:nome, papel=:papel, email=:email WHERE id=:id';
    Q.Params.ParamByName('nome').AsString  := AMembro.Nome;
    Q.Params.ParamByName('papel').AsString := AMembro.Papel;
    Q.Params.ParamByName('email').AsString := AMembro.Email;
    Q.Params.ParamByName('id').AsInteger   := AMembro.Id;
    Q.ExecSQL;
    TDBConnection.Commit;
  finally
    Q.Close;
    Q.Free;
  end;
end;

class procedure TMembros.Desativar(AId: Integer);
var Q: TSQLQuery;
begin
  Q := TDBConnection.NewQuery;
  try
    Q.SQL.Text := 'UPDATE membros SET ativo = 0 WHERE id = :id';
    Q.Params.ParamByName('id').AsInteger := AId;
    Q.ExecSQL;
    TDBConnection.Commit;
  finally
    Q.Close;
    Q.Free;
  end;
end;

end.
```

## FMembros — form de cadastro (orientação de layout)
- `TStringGrid` com colunas: ID | Nome | Papel | Email | Ativo
- Botões: Novo, Editar, Desativar, Fechar
- Ao clicar "Novo/Editar": abre painel lateral com `TEdit` (nome, email) + `TComboBox` (papel com PapeisValidos)
- Validação mínima: nome não vazio, papel selecionado
- Após salvar: recarregar StringGrid via `TMembros.Listar`
