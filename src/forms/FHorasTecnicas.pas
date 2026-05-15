unit FHorasTecnicas;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs,
  StdCtrls, Grids, ExtCtrls,
  UHorasTecnicas, UTarefas, UMembros;

type
  TFormHorasTecnicas = class(TForm)
    PnlTimer       : TPanel;
    LblTarefa      : TLabel;
    CmbTarefa      : TComboBox;
    LblTipo        : TLabel;
    CmbTipo        : TComboBox;
    LblMembro      : TLabel;
    CmbMembro      : TComboBox;
    BtnIniciar     : TButton;
    BtnParar       : TButton;
    LblTempo       : TLabel;
    TimerTick      : TTimer;
    PnlLog         : TPanel;
    SgHoras        : TStringGrid;
    PnlBotLog      : TPanel;
    BtnManual      : TButton;
    BtnDeletarH    : TButton;
    BtnFechar      : TButton;
    PnlResumo      : TPanel;
    LblResumoTit   : TLabel;
    SgResumo       : TStringGrid;
    PnlEdicaoManual: TPanel;
    LblInicioM     : TLabel;
    EdtInicio      : TEdit;
    LblFimM        : TLabel;
    EdtFim         : TEdit;
    LblTipoM       : TLabel;
    CmbTipoM       : TComboBox;
    LblObsM        : TLabel;
    EdtObs         : TEdit;
    BtnSalvarM     : TButton;
    BtnCancelarM   : TButton;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure BtnIniciarClick(Sender: TObject);
    procedure BtnPararClick(Sender: TObject);
    procedure TimerTickTimer(Sender: TObject);
    procedure BtnManualClick(Sender: TObject);
    procedure BtnDeletarHClick(Sender: TObject);
    procedure BtnFecharClick(Sender: TObject);
    procedure BtnSalvarMClick(Sender: TObject);
    procedure BtnCancelarMClick(Sender: TObject);
    procedure CmbTarefaChange(Sender: TObject);
    procedure CmbMembroChange(Sender: TObject);
  private
    FTimerRegistroId: Integer;
    procedure CarregarTarefas;
    procedure CarregarMembros;
    procedure CarregarLog;
    procedure CarregarResumo;
    function  TarefaIdSel: Integer;
    function  MembroIdSel: Integer;
    procedure AtualizarBotoesTimer;
  public
  end;

var
  FormHorasTecnicas: TFormHorasTecnicas;

implementation

{$R *.lfm}

procedure TFormHorasTecnicas.FormCreate(Sender: TObject);
var
  T: string;
begin
  Caption := 'Horas Técnicas';
  Width   := 800;
  Height  := 580;

  for T in THorasTecnicas.TiposValidos do
  begin
    CmbTipo.Items.Add(T);
    CmbTipoM.Items.Add(T);
  end;
  CmbTipo.ItemIndex := 0;
  CmbTipoM.ItemIndex := 0;

  SgHoras.ColCount := 5;
  SgHoras.FixedRows := 1;
  SgHoras.Cells[0,0] := 'ID';
  SgHoras.Cells[1,0] := 'Tipo';
  SgHoras.Cells[2,0] := 'Início';
  SgHoras.Cells[3,0] := 'Duração';
  SgHoras.Cells[4,0] := 'Obs';
  SgHoras.ColWidths[0] := 40;
  SgHoras.ColWidths[1] := 120;
  SgHoras.ColWidths[2] := 140;
  SgHoras.ColWidths[3] := 80;
  SgHoras.ColWidths[4] := 200;

  SgResumo.ColCount := 3;
  SgResumo.FixedRows := 1;
  SgResumo.Cells[0,0] := 'Tipo';
  SgResumo.Cells[1,0] := 'Registros';
  SgResumo.Cells[2,0] := 'Total';
  SgResumo.ColWidths[0] := 140;
  SgResumo.ColWidths[1] := 80;
  SgResumo.ColWidths[2] := 90;

  LblTempo.Caption := '00:00';
  TimerTick.Interval := 1000;
  TimerTick.Enabled := False;

  PnlEdicaoManual.Visible := False;
  FTimerRegistroId := 0;

  CarregarMembros;
  CarregarTarefas;
end;

procedure TFormHorasTecnicas.FormDestroy(Sender: TObject);
begin
  TimerTick.Enabled := False;
end;

procedure TFormHorasTecnicas.CarregarMembros;
var
  Lista: TArray<TMembro>;
  M: TMembro;
begin
  CmbMembro.Clear;
  Lista := TMembros.Listar(True);
  for M in Lista do
    CmbMembro.Items.AddObject(M.Nome, TObject(PtrInt(M.Id)));
  if CmbMembro.Items.Count > 0 then
    CmbMembro.ItemIndex := 0;
end;

procedure TFormHorasTecnicas.CarregarTarefas;
var
  Lista: TArray<TTarefa>;
  T: TTarefa;
begin
  CmbTarefa.Clear;
  CmbTarefa.Items.AddObject('(selecione)', TObject(PtrInt(0)));
  Lista := TTarefas.ListarPorSprint(0);
  for T in Lista do
    CmbTarefa.Items.AddObject('[' + T.Status + '] ' + T.Titulo,
      TObject(PtrInt(T.Id)));
  if CmbTarefa.Items.Count > 0 then
    CmbTarefa.ItemIndex := 0;
end;

procedure TFormHorasTecnicas.CarregarLog;
var
  Lista: TArray<THoraTecnica>;
  I: Integer;
  TarefaId: Integer;
begin
  TarefaId := TarefaIdSel;
  if TarefaId <= 0 then
  begin
    SgHoras.RowCount := 1;
    Exit;
  end;
  Lista := THorasTecnicas.Listar(TarefaId);
  SgHoras.RowCount := Length(Lista) + 1;
  for I := 0 to High(Lista) do
  begin
    SgHoras.Cells[0, I+1] := IntToStr(Lista[I].Id);
    SgHoras.Cells[1, I+1] := Lista[I].Tipo;
    SgHoras.Cells[2, I+1] := FormatDateTime('dd/mm/yyyy hh:nn', Lista[I].Inicio);
    SgHoras.Cells[3, I+1] := THorasTecnicas.FormatarDuracao(Lista[I].TotalMin);
    SgHoras.Cells[4, I+1] := Lista[I].Obs;
  end;
end;

procedure TFormHorasTecnicas.CarregarResumo;
var
  Lista: TArray<TResumoHoras>;
  I: Integer;
  TarefaId: Integer;
begin
  TarefaId := TarefaIdSel;
  if TarefaId <= 0 then
  begin
    SgResumo.RowCount := 1;
    Exit;
  end;
  Lista := THorasTecnicas.ResumoPorTarefa(TarefaId);
  SgResumo.RowCount := Length(Lista) + 1;
  for I := 0 to High(Lista) do
  begin
    SgResumo.Cells[0, I+1] := Lista[I].Tipo;
    SgResumo.Cells[1, I+1] := IntToStr(Lista[I].Registros);
    SgResumo.Cells[2, I+1] := THorasTecnicas.FormatarDuracao(Lista[I].TotalMin);
  end;
end;

function TFormHorasTecnicas.TarefaIdSel: Integer;
var
  Idx: Integer;
begin
  Idx := CmbTarefa.ItemIndex;
  if Idx < 0 then
  begin
    Result := 0;
    Exit;
  end;
  Result := PtrInt(CmbTarefa.Items.Objects[Idx]);
end;

function TFormHorasTecnicas.MembroIdSel: Integer;
var
  Idx: Integer;
begin
  Idx := CmbMembro.ItemIndex;
  if Idx < 0 then
  begin
    Result := 0;
    Exit;
  end;
  Result := PtrInt(CmbMembro.Items.Objects[Idx]);
end;

procedure TFormHorasTecnicas.AtualizarBotoesTimer;
var
  Status: TTimerStatus;
  Mid: Integer;
begin
  Mid := MembroIdSel;
  if Mid <= 0 then Exit;
  Status := THorasTecnicas.TimerAtivo(Mid);
  BtnIniciar.Enabled := not Status.Ativo;
  BtnParar.Enabled   := Status.Ativo;
  TimerTick.Enabled  := Status.Ativo;
  if Status.Ativo then
    FTimerRegistroId := Status.RegistroId
  else
  begin
    FTimerRegistroId := 0;
    LblTempo.Caption := '00:00';
  end;
end;

procedure TFormHorasTecnicas.BtnIniciarClick(Sender: TObject);
var
  TarefaId, MembroId: Integer;
  Tipo: string;
begin
  TarefaId := TarefaIdSel;
  MembroId := MembroIdSel;
  if TarefaId <= 0 then
  begin
    ShowMessage('Selecione uma tarefa.');
    Exit;
  end;
  if MembroId <= 0 then
  begin
    ShowMessage('Selecione um membro.');
    Exit;
  end;
  Tipo := CmbTipo.Items[CmbTipo.ItemIndex];
  try
    FTimerRegistroId := THorasTecnicas.IniciarTimer(TarefaId, MembroId, Tipo);
    AtualizarBotoesTimer;
    CarregarLog;
  except
    on E: Exception do
      ShowMessage('Erro ao iniciar: ' + E.Message);
  end;
end;

procedure TFormHorasTecnicas.BtnPararClick(Sender: TObject);
begin
  if FTimerRegistroId <= 0 then Exit;
  try
    THorasTecnicas.PararTimer(FTimerRegistroId);
    AtualizarBotoesTimer;
    CarregarLog;
    CarregarResumo;
  except
    on E: Exception do
      ShowMessage('Erro ao parar: ' + E.Message);
  end;
end;

procedure TFormHorasTecnicas.TimerTickTimer(Sender: TObject);
var
  Status: TTimerStatus;
  Decorrido: TDateTime;
  Min, Seg: Integer;
begin
  Status := THorasTecnicas.TimerAtivo(MembroIdSel);
  if Status.Ativo then
  begin
    Decorrido := Now - Status.Inicio;
    Min := Trunc(Decorrido * 1440);
    Seg := Trunc(Decorrido * 86400) mod 60;
    LblTempo.Caption := Format('%02d:%02d', [Min, Seg]);
  end else
  begin
    TimerTick.Enabled := False;
    LblTempo.Caption  := '00:00';
    BtnIniciar.Enabled := True;
    BtnParar.Enabled   := False;
  end;
end;

procedure TFormHorasTecnicas.BtnManualClick(Sender: TObject);
begin
  EdtInicio.Text := FormatDateTime('yyyy-mm-dd hh:nn:ss', Now - (1/24));
  EdtFim.Text    := FormatDateTime('yyyy-mm-dd hh:nn:ss', Now);
  EdtObs.Text    := '';
  CmbTipoM.ItemIndex := 0;
  PnlEdicaoManual.Visible := True;
  EdtInicio.SetFocus;
end;

procedure TFormHorasTecnicas.BtnDeletarHClick(Sender: TObject);
var
  Row, Id: Integer;
begin
  Row := SgHoras.Row;
  if Row < 1 then
  begin
    ShowMessage('Selecione um registro.');
    Exit;
  end;
  Id := StrToIntDef(SgHoras.Cells[0, Row], 0);
  if Id = 0 then Exit;
  if MessageDlg('Excluir este registro?', mtConfirmation, [mbYes, mbNo], 0) = mrYes then
  begin
    try
      THorasTecnicas.Deletar(Id);
      CarregarLog;
      CarregarResumo;
    except
      on E: Exception do
        ShowMessage('Erro ao excluir: ' + E.Message);
    end;
  end;
end;

procedure TFormHorasTecnicas.BtnFecharClick(Sender: TObject);
begin
  Close;
end;

procedure TFormHorasTecnicas.BtnSalvarMClick(Sender: TObject);
var
  H: THoraTecnica;
begin
  if Trim(EdtInicio.Text) = '' then
  begin
    ShowMessage('Informe a data/hora de início.');
    Exit;
  end;
  if Trim(EdtFim.Text) = '' then
  begin
    ShowMessage('Informe a data/hora de fim.');
    Exit;
  end;

  H.Id       := 0;
  H.TarefaId := TarefaIdSel;
  H.MembroId := MembroIdSel;
  H.Tipo     := CmbTipoM.Items[CmbTipoM.ItemIndex];
  H.Inicio   := TDateTimeHelper.FromPG(EdtInicio.Text);
  H.Fim      := TDateTimeHelper.FromPG(EdtFim.Text);
  H.Obs      := Trim(EdtObs.Text);

  try
    THorasTecnicas.Inserir(H);
    PnlEdicaoManual.Visible := False;
    CarregarLog;
    CarregarResumo;
  except
    on E: Exception do
      ShowMessage('Erro ao salvar: ' + E.Message);
  end;
end;

procedure TFormHorasTecnicas.BtnCancelarMClick(Sender: TObject);
begin
  PnlEdicaoManual.Visible := False;
end;

procedure TFormHorasTecnicas.CmbTarefaChange(Sender: TObject);
begin
  CarregarLog;
  CarregarResumo;
end;

procedure TFormHorasTecnicas.CmbMembroChange(Sender: TObject);
begin
  AtualizarBotoesTimer;
end;

end.
