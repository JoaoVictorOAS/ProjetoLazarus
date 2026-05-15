unit FSprints;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs,
  StdCtrls, Grids, ExtCtrls,
  USprints, UProjetos;

type
  TFormSprints = class(TForm)
    PnlTopo      : TPanel;
    LblProjeto   : TLabel;
    CmbProjeto   : TComboBox;
    SgSprints    : TStringGrid;
    PnlBotoes    : TPanel;
    BtnNova      : TButton;
    BtnIniciar   : TButton;
    BtnEncerrar  : TButton;
    BtnFechar    : TButton;
    PnlEdicao    : TPanel;
    LblGoal      : TLabel;
    EdtGoal      : TEdit;
    LblCap       : TLabel;
    EdtCap       : TEdit;
    LblInicio    : TLabel;
    EdtInicio    : TEdit;
    LblFim       : TLabel;
    EdtFim       : TEdit;
    BtnSalvar    : TButton;
    BtnCancelar  : TButton;
    procedure FormCreate(Sender: TObject);
    procedure CmbProjetoChange(Sender: TObject);
    procedure BtnNovaClick(Sender: TObject);
    procedure BtnIniciarClick(Sender: TObject);
    procedure BtnEncerrarClick(Sender: TObject);
    procedure BtnFecharClick(Sender: TObject);
    procedure BtnSalvarClick(Sender: TObject);
    procedure BtnCancelarClick(Sender: TObject);
  private
    FEditandoId: Integer;
    procedure CarregarProjetos;
    procedure CarregarSprints;
    function  ProjetoIdSelecionado: Integer;
    function  SprintIdSelecionada: Integer;
    procedure AbrirEdicao;
    procedure FecharEdicao;
  public
  end;

var
  FormSprints: TFormSprints;

implementation

{$R *.lfm}

procedure TFormSprints.FormCreate(Sender: TObject);
begin
  Caption := 'Sprints';
  Width   := 760;
  Height  := 500;

  SgSprints.ColCount := 6;
  SgSprints.FixedRows := 1;
  SgSprints.Cells[0,0] := 'ID';
  SgSprints.Cells[1,0] := 'Nº';
  SgSprints.Cells[2,0] := 'Goal';
  SgSprints.Cells[3,0] := 'Status';
  SgSprints.Cells[4,0] := 'Início';
  SgSprints.Cells[5,0] := 'Fim';
  SgSprints.ColWidths[0] := 40;
  SgSprints.ColWidths[1] := 30;
  SgSprints.ColWidths[2] := 220;
  SgSprints.ColWidths[3] := 80;
  SgSprints.ColWidths[4] := 90;
  SgSprints.ColWidths[5] := 90;

  PnlEdicao.Visible := False;
  FEditandoId := 0;
  CarregarProjetos;
end;

procedure TFormSprints.CarregarProjetos;
var
  Lista: TArray<TProjeto>;
  P: TProjeto;
begin
  CmbProjeto.Clear;
  Lista := TProjetos.Listar;
  for P in Lista do
    CmbProjeto.Items.AddObject(P.Nome, TObject(PtrInt(P.Id)));
  if CmbProjeto.Items.Count > 0 then
  begin
    CmbProjeto.ItemIndex := 0;
    CarregarSprints;
  end;
end;

procedure TFormSprints.CarregarSprints;
var
  Lista: TArray<TSprint>;
  ProjetoId, I: Integer;
begin
  ProjetoId := ProjetoIdSelecionado;
  if ProjetoId <= 0 then Exit;

  Lista := TSprints.ListarPorProjeto(ProjetoId);
  SgSprints.RowCount := Length(Lista) + 1;
  for I := 0 to High(Lista) do
  begin
    SgSprints.Cells[0, I+1] := IntToStr(Lista[I].Id);
    SgSprints.Cells[1, I+1] := IntToStr(Lista[I].Numero);
    SgSprints.Cells[2, I+1] := Lista[I].Goal;
    SgSprints.Cells[3, I+1] := Lista[I].Status;
    SgSprints.Cells[4, I+1] := Lista[I].DataInicio;
    SgSprints.Cells[5, I+1] := Lista[I].DataFim;
  end;
end;

function TFormSprints.ProjetoIdSelecionado: Integer;
var
  Idx: Integer;
begin
  Idx := CmbProjeto.ItemIndex;
  if Idx < 0 then
  begin
    Result := 0;
    Exit;
  end;
  Result := PtrInt(CmbProjeto.Items.Objects[Idx]);
end;

function TFormSprints.SprintIdSelecionada: Integer;
var
  Row: Integer;
begin
  Row := SgSprints.Row;
  if Row < 1 then
  begin
    Result := 0;
    Exit;
  end;
  Result := StrToIntDef(SgSprints.Cells[0, Row], 0);
end;

procedure TFormSprints.AbrirEdicao;
var
  ProjetoId, ProxNum: Integer;
  DataFim: TDateTime;
begin
  FEditandoId := 0;
  ProjetoId := ProjetoIdSelecionado;
  ProxNum := TSprints.ProximoNumero(ProjetoId);
  EdtGoal.Text   := 'Sprint ' + IntToStr(ProxNum);
  EdtCap.Text    := '20';
  EdtInicio.Text := FormatDateTime('yyyy-mm-dd', Now);
  DataFim := IncDay(Now, 14);
  EdtFim.Text    := FormatDateTime('yyyy-mm-dd', DataFim);
  PnlEdicao.Visible := True;
  EdtGoal.SetFocus;
end;

procedure TFormSprints.FecharEdicao;
begin
  PnlEdicao.Visible := False;
  FEditandoId := 0;
end;

procedure TFormSprints.CmbProjetoChange(Sender: TObject);
begin
  CarregarSprints;
end;

procedure TFormSprints.BtnNovaClick(Sender: TObject);
begin
  if ProjetoIdSelecionado <= 0 then
  begin
    ShowMessage('Selecione um projeto.');
    Exit;
  end;
  AbrirEdicao;
end;

procedure TFormSprints.BtnIniciarClick(Sender: TObject);
var
  Id: Integer;
begin
  Id := SprintIdSelecionada;
  if Id = 0 then
  begin
    ShowMessage('Selecione uma sprint.');
    Exit;
  end;
  if MessageDlg('Iniciar esta sprint?', mtConfirmation, [mbYes, mbNo], 0) = mrYes then
  begin
    try
      TSprints.IniciarSprint(Id);
      CarregarSprints;
    except
      on E: Exception do
        ShowMessage('Erro: ' + E.Message);
    end;
  end;
end;

procedure TFormSprints.BtnEncerrarClick(Sender: TObject);
var
  Id: Integer;
begin
  Id := SprintIdSelecionada;
  if Id = 0 then
  begin
    ShowMessage('Selecione uma sprint.');
    Exit;
  end;
  if MessageDlg('Encerrar esta sprint?', mtConfirmation, [mbYes, mbNo], 0) = mrYes then
  begin
    try
      TSprints.EncerrarSprint(Id);
      CarregarSprints;
    except
      on E: Exception do
        ShowMessage('Erro: ' + E.Message);
    end;
  end;
end;

procedure TFormSprints.BtnFecharClick(Sender: TObject);
begin
  Close;
end;

procedure TFormSprints.BtnSalvarClick(Sender: TObject);
var
  S: TSprint;
begin
  if Trim(EdtGoal.Text) = '' then
  begin
    ShowMessage('Informe o goal da sprint.');
    EdtGoal.SetFocus;
    Exit;
  end;

  S.Id            := 0;
  S.ProjetoId     := ProjetoIdSelecionado;
  S.Numero        := TSprints.ProximoNumero(S.ProjetoId);
  S.Goal          := Trim(EdtGoal.Text);
  S.CapacidadePts := StrToIntDef(Trim(EdtCap.Text), 0);
  S.Status        := 'planejada';
  S.DataInicio    := Trim(EdtInicio.Text);
  S.DataFim       := Trim(EdtFim.Text);

  try
    TSprints.Inserir(S);
    FecharEdicao;
    CarregarSprints;
  except
    on E: Exception do
      ShowMessage('Erro ao salvar: ' + E.Message);
  end;
end;

procedure TFormSprints.BtnCancelarClick(Sender: TObject);
begin
  FecharEdicao;
end;

end.
