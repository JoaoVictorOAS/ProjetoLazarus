# AGENT_HORAS.md
> Leia CLAUDE.md + AGENT_DATABASE.md antes deste arquivo.

## Responsabilidade
Contagem de horas técnicas: timer start/stop, log manual, totais por tipo/membro/sprint.
Este é o módulo central do projeto.

## UHorasTecnicas.pas

```pascal
unit UHorasTecnicas;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, sqldb, DateUtils, UDBConnection;

type
  THoraTecnica = record
    Id        : Integer;
    TarefaId  : Integer;
    MembroId  : Integer;
    Tipo      : string; // ver TiposValidos
    Inicio    : TDateTime;
    Fim       : TDateTime;  // 0 = em andamento
    TotalMin  : Integer;    // calculado
    Obs       : string;
  end;

  TResumoHoras = record
    Tipo      : string;
    TotalMin  : Integer;
    TotalHoras: Double;
    Registros : Integer;
  end;

  TTimerStatus = record
    Ativo     : Boolean;
    RegistroId: Integer;
    Inicio    : TDateTime;
    TarefaId  : Integer;
    Tipo      : string;
  end;

  // Formato SQLite: 'YYYY-MM-DD HH:MM:SS'
  TDateTimeHelper = class
    class function ToSQLite(DT: TDateTime): string;
    class function FromSQLite(const S: string): TDateTime;
  end;

  THorasTecnicas = class
  public
    class function  Listar(ATarefaId: Integer): TArray<THoraTecnica>;
    class function  BuscarPorId(AId: Integer): THoraTecnica;
    class function  Inserir(const AH: THoraTecnica): Integer;
    class procedure Atualizar(const AH: THoraTecnica);
    class procedure Deletar(AId: Integer);

    // Timer
    class function  IniciarTimer(ATarefaId, AMembroId: Integer; const ATipo: string): Integer;
    class procedure PararTimer(ARegistroId: Integer);
    class function  TimerAtivo(AMembroId: Integer): TTimerStatus;

    // Totais
    class function  ResumoporTarefa(ATarefaId: Integer): TArray<TResumoHoras>;
    class function  TotalPorSprint(ASprintId: Integer): TArray<TResumoHoras>;
    class function  TotalMembroPorSprint(AMembroId, ASprintId: Integer): Integer; // em minutos

    class function  TiposValidos: TStringArray;
    class function  FormatarDuracao(ATotalMin: Integer): string;
  end;

implementation

class function TDateTimeHelper.ToSQLite(DT: TDateTime): string;
begin
  Result := FormatDateTime('yyyy-mm-dd hh:nn:ss', DT);
end;

class function TDateTimeHelper.FromSQLite(const S: string): TDateTime;
begin
  if S = '' then begin Result := 0; Exit; end;
  Result := EncodeDateTime(
    StrToInt(Copy(S,1,4)), StrToInt(Copy(S,6,2)),  StrToInt(Copy(S,9,2)),
    StrToInt(Copy(S,12,2)),StrToInt(Copy(S,15,2)), StrToInt(Copy(S,18,2)), 0);
end;

class function THorasTecnicas.TiposValidos: TStringArray;
begin
  Result := TStringArray.Create(
    'desenvolvimento','code_review','testes',
    'reuniao','documentacao','devops','suporte','arquitetura');
end;

class function THorasTecnicas.FormatarDuracao(ATotalMin: Integer): string;
var H, M: Integer;
begin
  H := ATotalMin div 60;
  M := ATotalMin mod 60;
  Result := Format('%dh %02dm', [H, M]);
end;

class function THorasTecnicas.Listar(ATarefaId: Integer): TArray<THoraTecnica>;
var Q: TSQLQuery; Lista: TArray<THoraTecnica>; Idx: Integer;
begin
  Q := TDBConnection.NewQuery;
  try
    Q.SQL.Text :=
      'SELECT id, tarefa_id, membro_id, tipo, inicio, fim, total_min, obs ' +
      'FROM horas_tecnicas WHERE tarefa_id = :tid ORDER BY inicio DESC';
    Q.Params.ParamByName('tid').AsInteger := ATarefaId;
    Q.Open;
    SetLength(Lista, 0); Idx := 0;
    while not Q.EOF do
    begin
      SetLength(Lista, Idx + 1);
      Lista[Idx].Id       := Q.FieldByName('id').AsInteger;
      Lista[Idx].TarefaId := Q.FieldByName('tarefa_id').AsInteger;
      Lista[Idx].MembroId := Q.FieldByName('membro_id').AsInteger;
      Lista[Idx].Tipo     := Q.FieldByName('tipo').AsString;
      Lista[Idx].Inicio   := TDateTimeHelper.FromSQLite(Q.FieldByName('inicio').AsString);
      Lista[Idx].Fim      := TDateTimeHelper.FromSQLite(Q.FieldByName('fim').AsString);
      Lista[Idx].TotalMin := Q.FieldByName('total_min').AsInteger;
      Lista[Idx].Obs      := Q.FieldByName('obs').AsString;
      Inc(Idx); Q.Next;
    end;
    Result := Lista;
  finally
    Q.Close; Q.Free;
  end;
end;

class function THorasTecnicas.BuscarPorId(AId: Integer): THoraTecnica;
var Q: TSQLQuery;
begin
  Q := TDBConnection.NewQuery;
  try
    Q.SQL.Text :=
      'SELECT id, tarefa_id, membro_id, tipo, inicio, fim, total_min, obs ' +
      'FROM horas_tecnicas WHERE id = :id';
    Q.Params.ParamByName('id').AsInteger := AId;
    Q.Open;
    if Q.EOF then raise Exception.CreateFmt('Registro de hora %d não encontrado', [AId]);
    Result.Id       := Q.FieldByName('id').AsInteger;
    Result.TarefaId := Q.FieldByName('tarefa_id').AsInteger;
    Result.MembroId := Q.FieldByName('membro_id').AsInteger;
    Result.Tipo     := Q.FieldByName('tipo').AsString;
    Result.Inicio   := TDateTimeHelper.FromSQLite(Q.FieldByName('inicio').AsString);
    Result.Fim      := TDateTimeHelper.FromSQLite(Q.FieldByName('fim').AsString);
    Result.TotalMin := Q.FieldByName('total_min').AsInteger;
    Result.Obs      := Q.FieldByName('obs').AsString;
  finally
    Q.Close; Q.Free;
  end;
end;

class function THorasTecnicas.Inserir(const AH: THoraTecnica): Integer;
var Q: TSQLQuery;
begin
  Q := TDBConnection.NewQuery;
  try
    Q.SQL.Text :=
      'INSERT INTO horas_tecnicas (tarefa_id, membro_id, tipo, inicio, fim, obs) ' +
      'VALUES (:tid, :mid, :tipo, :inicio, :fim, :obs)';
    Q.Params.ParamByName('tid').AsInteger   := AH.TarefaId;
    Q.Params.ParamByName('mid').AsInteger   := AH.MembroId;
    Q.Params.ParamByName('tipo').AsString   := AH.Tipo;
    Q.Params.ParamByName('inicio').AsString := TDateTimeHelper.ToSQLite(AH.Inicio);
    if AH.Fim > 0 then
      Q.Params.ParamByName('fim').AsString  := TDateTimeHelper.ToSQLite(AH.Fim)
    else
      Q.Params.ParamByName('fim').Clear;
    Q.Params.ParamByName('obs').AsString    := AH.Obs;
    Q.ExecSQL;
    TDBConnection.Commit;
    Q.SQL.Text := 'SELECT last_insert_rowid() AS id';
    Q.Open;
    Result := Q.FieldByName('id').AsInteger;
  finally
    Q.Close; Q.Free;
  end;
end;

class procedure THorasTecnicas.Atualizar(const AH: THoraTecnica);
var Q: TSQLQuery;
begin
  Q := TDBConnection.NewQuery;
  try
    Q.SQL.Text :=
      'UPDATE horas_tecnicas SET tipo=:tipo, inicio=:inicio, fim=:fim, obs=:obs WHERE id=:id';
    Q.Params.ParamByName('tipo').AsString   := AH.Tipo;
    Q.Params.ParamByName('inicio').AsString := TDateTimeHelper.ToSQLite(AH.Inicio);
    if AH.Fim > 0 then
      Q.Params.ParamByName('fim').AsString  := TDateTimeHelper.ToSQLite(AH.Fim)
    else
      Q.Params.ParamByName('fim').Clear;
    Q.Params.ParamByName('obs').AsString  := AH.Obs;
    Q.Params.ParamByName('id').AsInteger  := AH.Id;
    Q.ExecSQL;
    TDBConnection.Commit;
  finally
    Q.Close; Q.Free;
  end;
end;

class procedure THorasTecnicas.Deletar(AId: Integer);
var Q: TSQLQuery;
begin
  Q := TDBConnection.NewQuery;
  try
    Q.SQL.Text := 'DELETE FROM horas_tecnicas WHERE id=:id';
    Q.Params.ParamByName('id').AsInteger := AId;
    Q.ExecSQL;
    TDBConnection.Commit;
  finally
    Q.Close; Q.Free;
  end;
end;

// ── Timer ─────────────────────────────────────────────────────────────────

class function THorasTecnicas.IniciarTimer(
  ATarefaId, AMembroId: Integer; const ATipo: string): Integer;
var H: THoraTecnica;
begin
  // garante que não há timer aberto para esse membro
  PararTimer(TimerAtivo(AMembroId).RegistroId);

  H.Id       := 0;
  H.TarefaId := ATarefaId;
  H.MembroId := AMembroId;
  H.Tipo     := ATipo;
  H.Inicio   := Now;
  H.Fim      := 0;
  H.Obs      := '';
  Result := Inserir(H);
end;

class procedure THorasTecnicas.PararTimer(ARegistroId: Integer);
var Q: TSQLQuery;
begin
  if ARegistroId <= 0 then Exit;
  Q := TDBConnection.NewQuery;
  try
    Q.SQL.Text :=
      'UPDATE horas_tecnicas SET fim = datetime(''now'') WHERE id = :id AND fim IS NULL';
    Q.Params.ParamByName('id').AsInteger := ARegistroId;
    Q.ExecSQL;
    TDBConnection.Commit;
  finally
    Q.Close; Q.Free;
  end;
end;

class function THorasTecnicas.TimerAtivo(AMembroId: Integer): TTimerStatus;
var Q: TSQLQuery;
begin
  Result.Ativo := False;
  Result.RegistroId := 0;
  Q := TDBConnection.NewQuery;
  try
    Q.SQL.Text :=
      'SELECT id, tarefa_id, tipo, inicio FROM horas_tecnicas ' +
      'WHERE membro_id = :mid AND fim IS NULL LIMIT 1';
    Q.Params.ParamByName('mid').AsInteger := AMembroId;
    Q.Open;
    if not Q.EOF then
    begin
      Result.Ativo      := True;
      Result.RegistroId := Q.FieldByName('id').AsInteger;
      Result.TarefaId   := Q.FieldByName('tarefa_id').AsInteger;
      Result.Tipo       := Q.FieldByName('tipo').AsString;
      Result.Inicio     := TDateTimeHelper.FromSQLite(Q.FieldByName('inicio').AsString);
    end;
  finally
    Q.Close; Q.Free;
  end;
end;

// ── Totais ────────────────────────────────────────────────────────────────

class function THorasTecnicas.ResumoporTarefa(ATarefaId: Integer): TArray<TResumoHoras>;
var Q: TSQLQuery; Lista: TArray<TResumoHoras>; Idx: Integer;
begin
  Q := TDBConnection.NewQuery;
  try
    Q.SQL.Text :=
      'SELECT tipo, COUNT(*) AS registros, ' +
      'SUM(total_min) AS total_min, ROUND(SUM(total_min)/60.0,2) AS total_horas ' +
      'FROM horas_tecnicas WHERE tarefa_id = :tid AND fim IS NOT NULL ' +
      'GROUP BY tipo ORDER BY total_min DESC';
    Q.Params.ParamByName('tid').AsInteger := ATarefaId;
    Q.Open;
    SetLength(Lista, 0); Idx := 0;
    while not Q.EOF do
    begin
      SetLength(Lista, Idx + 1);
      Lista[Idx].Tipo       := Q.FieldByName('tipo').AsString;
      Lista[Idx].Registros  := Q.FieldByName('registros').AsInteger;
      Lista[Idx].TotalMin   := Q.FieldByName('total_min').AsInteger;
      Lista[Idx].TotalHoras := Q.FieldByName('total_horas').AsFloat;
      Inc(Idx); Q.Next;
    end;
    Result := Lista;
  finally
    Q.Close; Q.Free;
  end;
end;

class function THorasTecnicas.TotalPorSprint(ASprintId: Integer): TArray<TResumoHoras>;
var Q: TSQLQuery; Lista: TArray<TResumoHoras>; Idx: Integer;
begin
  Q := TDBConnection.NewQuery;
  try
    Q.SQL.Text :=
      'SELECT h.tipo, COUNT(*) AS registros, ' +
      'SUM(h.total_min) AS total_min, ROUND(SUM(h.total_min)/60.0,2) AS total_horas ' +
      'FROM horas_tecnicas h ' +
      'JOIN tarefas t ON t.id = h.tarefa_id ' +
      'WHERE t.sprint_id = :sid AND h.fim IS NOT NULL ' +
      'GROUP BY h.tipo ORDER BY total_min DESC';
    Q.Params.ParamByName('sid').AsInteger := ASprintId;
    Q.Open;
    SetLength(Lista, 0); Idx := 0;
    while not Q.EOF do
    begin
      SetLength(Lista, Idx + 1);
      Lista[Idx].Tipo       := Q.FieldByName('tipo').AsString;
      Lista[Idx].Registros  := Q.FieldByName('registros').AsInteger;
      Lista[Idx].TotalMin   := Q.FieldByName('total_min').AsInteger;
      Lista[Idx].TotalHoras := Q.FieldByName('total_horas').AsFloat;
      Inc(Idx); Q.Next;
    end;
    Result := Lista;
  finally
    Q.Close; Q.Free;
  end;
end;

class function THorasTecnicas.TotalMembroPorSprint(
  AMembroId, ASprintId: Integer): Integer;
var Q: TSQLQuery;
begin
  Q := TDBConnection.NewQuery;
  try
    Q.SQL.Text :=
      'SELECT COALESCE(SUM(h.total_min),0) AS total ' +
      'FROM horas_tecnicas h ' +
      'JOIN tarefas t ON t.id = h.tarefa_id ' +
      'WHERE h.membro_id = :mid AND t.sprint_id = :sid AND h.fim IS NOT NULL';
    Q.Params.ParamByName('mid').AsInteger := AMembroId;
    Q.Params.ParamByName('sid').AsInteger := ASprintId;
    Q.Open;
    Result := Q.FieldByName('total').AsInteger;
  finally
    Q.Close; Q.Free;
  end;
end;

end.
```

## FHorasTecnicas — orientação de layout

### Área de timer (topo)
```
[Tarefa: ▼ Combo]  [Tipo: ▼ Combo]  [▶ INICIAR]  [■ PARAR]
Tempo decorrido: 00:32:15   (TLabel atualizado por TTimer a cada segundo)
```
- `TTimer` com `Interval = 1000`, no evento `OnTimer`:
  ```pascal
  procedure TFormHoras.TimerTick(Sender: TObject);
  var Status: TTimerStatus; Decorrido: TDateTime; Min, Seg: Integer;
  begin
    Status := THorasTecnicas.TimerAtivo(MembroIdAtual);
    if Status.Ativo then
    begin
      Decorrido := Now - Status.Inicio;
      Min := Trunc(Decorrido * 1440);
      Seg := Trunc(Decorrido * 86400) mod 60;
      LblTempo.Caption := Format('%02d:%02d', [Min, Seg]);
    end;
  end;
  ```

### Área de log (centro)
- `TStringGrid`: Data | Tipo | Duração | Membro | Obs
- Botão "Lançar manual" abre form com início/fim manuais + ComboBox tipo

### Resumo por tipo (rodapé)
- `TStringGrid` somente-leitura: Tipo | Registros | Total
- Alimentado por `THorasTecnicas.ResumoporTarefa`
