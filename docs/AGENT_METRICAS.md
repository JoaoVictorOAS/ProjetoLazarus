# AGENT_METRICAS.md
> Leia CLAUDE.md + AGENT_DATABASE.md antes deste arquivo.

## Responsabilidade
Cálculo e exibição de métricas ágeis: velocity, burndown, lead time, horas/story point.
Depende de todos os outros módulos — implemente por último.

## UMetricas.pas

```pascal
unit UMetricas;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, sqldb, UDBConnection;

type
  TVelocityItem = record
    SprintNumero  : Integer;
    CapacidadePts : Integer;
    PontosEntregues: Integer;
  end;

  TBurndownItem = record
    Dia           : string;
    PontosRestantes: Integer;
  end;

  TMetricas = class
  public
    // Velocity: pontos entregues por sprint
    class function Velocity(AProjetoId: Integer): TArray<TVelocityItem>;

    // Burndown: pontos restantes dia a dia na sprint ativa
    class function Burndown(ASprintId: Integer): TArray<TBurndownItem>;

    // Horas por story point na sprint
    class function HorasPorPonto(ASprintId: Integer): Double;

    // Lead time médio (dias entre criação e done) na sprint
    class function LeadTimeMedio(ASprintId: Integer): Double;

    // Total de bugs na sprint
    class function TotalBugs(ASprintId: Integer): Integer;

    // Taxa de bugs (bugs / total tarefas * 100)
    class function TaxaBugs(ASprintId: Integer): Double;
  end;

implementation

class function TMetricas.Velocity(AProjetoId: Integer): TArray<TVelocityItem>;
var Q: TSQLQuery; Lista: TArray<TVelocityItem>; Idx: Integer;
begin
  Q := TDBConnection.NewQuery;
  try
    // usa a view v_velocity
    Q.SQL.Text :=
      'SELECT sprint_id, numero, capacidade_pts, pontos_entregues ' +
      'FROM v_velocity WHERE projeto_id = :pid ORDER BY numero';
    Q.Params.ParamByName('pid').AsInteger := AProjetoId;
    Q.Open;
    SetLength(Lista, 0); Idx := 0;
    while not Q.EOF do
    begin
      SetLength(Lista, Idx + 1);
      Lista[Idx].SprintNumero   := Q.FieldByName('numero').AsInteger;
      Lista[Idx].CapacidadePts  := Q.FieldByName('capacidade_pts').AsInteger;
      Lista[Idx].PontosEntregues := Q.FieldByName('pontos_entregues').AsInteger;
      Inc(Idx); Q.Next;
    end;
    Result := Lista;
  finally
    Q.Close; Q.Free;
  end;
end;

class function TMetricas.Burndown(ASprintId: Integer): TArray<TBurndownItem>;
var Q: TSQLQuery; Lista: TArray<TBurndownItem>; Idx: Integer;
begin
  // Burndown simplificado: total de pontos não-done agrupado por dia de atualização
  Q := TDBConnection.NewQuery;
  try
    Q.SQL.Text :=
      'SELECT date(atualizado_em) AS dia, SUM(pontos) AS restantes ' +
      'FROM tarefas ' +
      'WHERE sprint_id = :sid AND status != ''done'' ' +
      'GROUP BY date(atualizado_em) ORDER BY dia';
    Q.Params.ParamByName('sid').AsInteger := ASprintId;
    Q.Open;
    SetLength(Lista, 0); Idx := 0;
    while not Q.EOF do
    begin
      SetLength(Lista, Idx + 1);
      Lista[Idx].Dia             := Q.FieldByName('dia').AsString;
      Lista[Idx].PontosRestantes := Q.FieldByName('restantes').AsInteger;
      Inc(Idx); Q.Next;
    end;
    Result := Lista;
  finally
    Q.Close; Q.Free;
  end;
end;

class function TMetricas.HorasPorPonto(ASprintId: Integer): Double;
var Q: TSQLQuery; TotalMin, TotalPontos: Integer;
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
    Q.Close; Q.Free;
  end;
end;

class function TMetricas.LeadTimeMedio(ASprintId: Integer): Double;
var Q: TSQLQuery;
begin
  Result := 0;
  Q := TDBConnection.NewQuery;
  try
    Q.SQL.Text :=
      'SELECT AVG(julianday(atualizado_em) - julianday(criado_em)) AS lead ' +
      'FROM tarefas WHERE sprint_id = :sid AND status = ''done''';
    Q.Params.ParamByName('sid').AsInteger := ASprintId;
    Q.Open;
    if not Q.EOF then
      Result := Q.FieldByName('lead').AsFloat;
  finally
    Q.Close; Q.Free;
  end;
end;

class function TMetricas.TotalBugs(ASprintId: Integer): Integer;
var Q: TSQLQuery;
begin
  Q := TDBConnection.NewQuery;
  try
    Q.SQL.Text :=
      'SELECT COUNT(*) AS total FROM tarefas WHERE sprint_id=:sid AND tipo=''bug''';
    Q.Params.ParamByName('sid').AsInteger := ASprintId;
    Q.Open;
    Result := Q.FieldByName('total').AsInteger;
  finally
    Q.Close; Q.Free;
  end;
end;

class function TMetricas.TaxaBugs(ASprintId: Integer): Double;
var Q: TSQLQuery; Total, Bugs: Integer;
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
    if Total > 0 then Result := (Bugs / Total) * 100;
  finally
    Q.Close; Q.Free;
  end;
end;

end.
```

## FMetricas — orientação de layout

### Seção Velocity
- `TChart` (TAChart) com `TBarSeries`
- X = número da sprint, Y = pontos entregues
- Linha de referência horizontal = média de velocity
- Preencher assim:
  ```pascal
  var Items: TArray<TVelocityItem>; I: Integer;
  begin
    Items := TMetricas.Velocity(ProjetoIdAtual);
    ChartVelocity.Series[0].Clear;
    for I := 0 to High(Items) do
      ChartVelocity.Series[0].Add(Items[I].PontosEntregues,
        'Sprint ' + IntToStr(Items[I].SprintNumero));
  end;
  ```

### Seção Burndown
- `TChart` com `TLineSeries`
- X = dia (string), Y = pontos restantes

### Cards de métricas rápidas
Quatro `TPanel` lado a lado com `TLabel` grande:
| Card | Fonte |
|---|---|
| Horas/Story Point | `TMetricas.HorasPorPonto` |
| Lead Time Médio | `TMetricas.LeadTimeMedio` |
| Total Bugs | `TMetricas.TotalBugs` |
| Taxa de Bugs | `TMetricas.TaxaBugs` |
