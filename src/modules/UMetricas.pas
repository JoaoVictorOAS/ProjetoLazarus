unit UMetricas;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, sqldb, UDBConnection;

type
  TVelocityItem = record
    SprintNumero   : Integer;
    CapacidadePts  : Integer;
    PontosEntregues: Integer;
  end;

  TBurndownItem = record
    Dia            : string;
    PontosRestantes: Integer;
  end;

  TMetricas = class
  public
    class function Velocity(AProjetoId: Integer): TArray<TVelocityItem>;
    class function Burndown(ASprintId: Integer): TArray<TBurndownItem>;
    class function HorasPorPonto(ASprintId: Integer): Double;
    class function LeadTimeMedio(ASprintId: Integer): Double;
    class function TotalBugs(ASprintId: Integer): Integer;
    class function TaxaBugs(ASprintId: Integer): Double;
  end;

implementation

class function TMetricas.Velocity(AProjetoId: Integer): TArray<TVelocityItem>;
var
  Q: TSQLQuery;
  Lista: TArray<TVelocityItem>;
  Idx: Integer;
begin
  Q := TDBConnection.NewQuery;
  try
    Q.SQL.Text :=
      'SELECT sprint_id, numero, capacidade_pts, pontos_entregues ' +
      'FROM v_velocity WHERE projeto_id = :pid ORDER BY numero';
    Q.Params.ParamByName('pid').AsInteger := AProjetoId;
    Q.Open;
    SetLength(Lista, 0);
    Idx := 0;
    while not Q.EOF do
    begin
      SetLength(Lista, Idx + 1);
      Lista[Idx].SprintNumero    := Q.FieldByName('numero').AsInteger;
      Lista[Idx].CapacidadePts   := Q.FieldByName('capacidade_pts').AsInteger;
      Lista[Idx].PontosEntregues := Q.FieldByName('pontos_entregues').AsInteger;
      Inc(Idx);
      Q.Next;
    end;
    Result := Lista;
  finally
    Q.Close;
    Q.Free;
  end;
end;

class function TMetricas.Burndown(ASprintId: Integer): TArray<TBurndownItem>;
var
  Q: TSQLQuery;
  Lista: TArray<TBurndownItem>;
  Idx: Integer;
begin
  Q := TDBConnection.NewQuery;
  try
    Q.SQL.Text :=
      'SELECT TO_CHAR(atualizado_em,''YYYY-MM-DD'') AS dia, SUM(pontos) AS restantes ' +
      'FROM tarefas ' +
      'WHERE sprint_id = :sid AND status <> ''done'' ' +
      'GROUP BY TO_CHAR(atualizado_em,''YYYY-MM-DD'') ORDER BY dia';
    Q.Params.ParamByName('sid').AsInteger := ASprintId;
    Q.Open;
    SetLength(Lista, 0);
    Idx := 0;
    while not Q.EOF do
    begin
      SetLength(Lista, Idx + 1);
      Lista[Idx].Dia             := Q.FieldByName('dia').AsString;
      Lista[Idx].PontosRestantes := Q.FieldByName('restantes').AsInteger;
      Inc(Idx);
      Q.Next;
    end;
    Result := Lista;
  finally
    Q.Close;
    Q.Free;
  end;
end;

class function TMetricas.HorasPorPonto(ASprintId: Integer): Double;
var
  Q: TSQLQuery;
  TotalMin, TotalPontos: Integer;
begin
  Result := 0;
  Q := TDBConnection.NewQuery;
  try
    Q.SQL.Text :=
      'SELECT COALESCE(SUM(h.total_min),0) AS total_min, ' +
      'COALESCE(SUM(t.pontos),0) AS total_pts ' +
      'FROM tarefas t ' +
      'LEFT JOIN horas_tecnicas h ON h.tarefa_id = t.id AND h.fim IS NOT NULL ' +
      'WHERE t.sprint_id = :sid AND t.status = ''done''';
    Q.Params.ParamByName('sid').AsInteger := ASprintId;
    Q.Open;
    TotalMin    := Q.FieldByName('total_min').AsInteger;
    TotalPontos := Q.FieldByName('total_pts').AsInteger;
    if TotalPontos > 0 then
      Result := (TotalMin / 60.0) / TotalPontos;
  finally
    Q.Close;
    Q.Free;
  end;
end;

class function TMetricas.LeadTimeMedio(ASprintId: Integer): Double;
var
  Q: TSQLQuery;
begin
  Result := 0;
  Q := TDBConnection.NewQuery;
  try
    Q.SQL.Text :=
      'SELECT AVG(EXTRACT(EPOCH FROM (atualizado_em - criado_em)) / 86400.0) AS lead ' +
      'FROM tarefas WHERE sprint_id = :sid AND status = ''done''';
    Q.Params.ParamByName('sid').AsInteger := ASprintId;
    Q.Open;
    if not Q.EOF then
      Result := Q.FieldByName('lead').AsFloat;
  finally
    Q.Close;
    Q.Free;
  end;
end;

class function TMetricas.TotalBugs(ASprintId: Integer): Integer;
var
  Q: TSQLQuery;
begin
  Q := TDBConnection.NewQuery;
  try
    Q.SQL.Text :=
      'SELECT COUNT(*) AS total FROM tarefas WHERE sprint_id=:sid AND tipo=''bug''';
    Q.Params.ParamByName('sid').AsInteger := ASprintId;
    Q.Open;
    Result := Q.FieldByName('total').AsInteger;
  finally
    Q.Close;
    Q.Free;
  end;
end;

class function TMetricas.TaxaBugs(ASprintId: Integer): Double;
var
  Q: TSQLQuery;
  Total, Bugs: Integer;
begin
  Result := 0;
  Q := TDBConnection.NewQuery;
  try
    Q.SQL.Text :=
      'SELECT COUNT(*) AS total, ' +
      'SUM(CASE WHEN tipo=''bug'' THEN 1 ELSE 0 END) AS bugs ' +
      'FROM tarefas WHERE sprint_id = :sid';
    Q.Params.ParamByName('sid').AsInteger := ASprintId;
    Q.Open;
    Total := Q.FieldByName('total').AsInteger;
    Bugs  := Q.FieldByName('bugs').AsInteger;
    if Total > 0 then
      Result := (Bugs / Total) * 100;
  finally
    Q.Close;
    Q.Free;
  end;
end;

end.
