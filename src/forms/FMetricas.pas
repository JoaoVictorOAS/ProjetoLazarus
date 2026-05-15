unit FMetricas;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs,
  StdCtrls, ExtCtrls, Grids,
  TAChart, TAChartAxis, TASeries,
  UMetricas, USprints, UProjetos;

type
  TFormMetricas = class(TForm)
    PnlTopo        : TPanel;
    LblProjeto     : TLabel;
    CmbProjeto     : TComboBox;
    LblSprint      : TLabel;
    CmbSprint      : TComboBox;
    BtnAtualizar   : TButton;
    BtnFechar      : TButton;
    PnlCards       : TPanel;
    PnlHorasPts    : TPanel;
    LblHorasPtsTit : TLabel;
    LblHorasPtsVal : TLabel;
    PnlLeadTime    : TPanel;
    LblLeadTimeTit : TLabel;
    LblLeadTimeVal : TLabel;
    PnlBugs        : TPanel;
    LblBugsTit     : TLabel;
    LblBugsVal     : TLabel;
    PnlTaxaBugs    : TPanel;
    LblTaxaBugsTit : TLabel;
    LblTaxaBugsVal : TLabel;
    PnlCharts      : TPanel;
    ChartVelocity  : TChart;
    ChartBurndown  : TChart;
    procedure FormCreate(Sender: TObject);
    procedure CmbProjetoChange(Sender: TObject);
    procedure BtnAtualizarClick(Sender: TObject);
    procedure BtnFecharClick(Sender: TObject);
  private
    FSerieVelocity : TBarSeries;
    FSerieBurndown : TLineSeries;
    procedure CarregarProjetos;
    procedure CarregarSprints;
    procedure AtualizarMetricas;
    procedure AtualizarVelocity;
    procedure AtualizarBurndown;
    procedure AtualizarCards;
    function  ProjetoIdSel: Integer;
    function  SprintIdSel: Integer;
  public
  end;

var
  FormMetricas: TFormMetricas;

implementation

{$R *.lfm}

procedure TFormMetricas.FormCreate(Sender: TObject);
begin
  Caption := 'Métricas do Projeto';
  Width   := 900;
  Height  := 620;

  FSerieVelocity := TBarSeries.Create(ChartVelocity);
  FSerieVelocity.Title := 'Pontos entregues';
  ChartVelocity.AddSeries(FSerieVelocity);
  ChartVelocity.Title.Text.Text := 'Velocity';

  FSerieBurndown := TLineSeries.Create(ChartBurndown);
  FSerieBurndown.Title := 'Pontos restantes';
  ChartBurndown.AddSeries(FSerieBurndown);
  ChartBurndown.Title.Text.Text := 'Burndown';

  CarregarProjetos;
end;

procedure TFormMetricas.CarregarProjetos;
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

procedure TFormMetricas.CarregarSprints;
var
  Lista: TArray<TSprint>;
  S: TSprint;
  ProjetoId: Integer;
begin
  CmbSprint.Clear;
  ProjetoId := ProjetoIdSel;
  if ProjetoId <= 0 then Exit;

  Lista := TSprints.ListarPorProjeto(ProjetoId);
  for S in Lista do
    CmbSprint.Items.AddObject('Sprint ' + IntToStr(S.Numero), TObject(PtrInt(S.Id)));

  if CmbSprint.Items.Count > 0 then
  begin
    CmbSprint.ItemIndex := 0;
    AtualizarMetricas;
  end;
end;

function TFormMetricas.ProjetoIdSel: Integer;
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

function TFormMetricas.SprintIdSel: Integer;
var
  Idx: Integer;
begin
  Idx := CmbSprint.ItemIndex;
  if Idx < 0 then
  begin
    Result := 0;
    Exit;
  end;
  Result := PtrInt(CmbSprint.Items.Objects[Idx]);
end;

procedure TFormMetricas.AtualizarMetricas;
begin
  AtualizarVelocity;
  AtualizarBurndown;
  AtualizarCards;
end;

procedure TFormMetricas.AtualizarVelocity;
var
  Items: TArray<TVelocityItem>;
  I: Integer;
begin
  FSerieVelocity.Clear;
  Items := TMetricas.Velocity(ProjetoIdSel);
  for I := 0 to High(Items) do
    FSerieVelocity.Add(Items[I].PontosEntregues,
      'Sprint ' + IntToStr(Items[I].SprintNumero));
end;

procedure TFormMetricas.AtualizarBurndown;
var
  Items: TArray<TBurndownItem>;
  I: Integer;
begin
  FSerieBurndown.Clear;
  Items := TMetricas.Burndown(SprintIdSel);
  for I := 0 to High(Items) do
    FSerieBurndown.AddXY(I, Items[I].PontosRestantes, Items[I].Dia);
end;

procedure TFormMetricas.AtualizarCards;
var
  SprintId: Integer;
  HorasPts, LeadTime, TaxaBugs: Double;
  TotalBugs: Integer;
begin
  SprintId := SprintIdSel;
  if SprintId <= 0 then Exit;

  try
    HorasPts := TMetricas.HorasPorPonto(SprintId);
    LblHorasPtsVal.Caption := Format('%.2f h/pt', [HorasPts]);
  except
    LblHorasPtsVal.Caption := 'N/D';
  end;

  try
    LeadTime := TMetricas.LeadTimeMedio(SprintId);
    LblLeadTimeVal.Caption := Format('%.1f dias', [LeadTime]);
  except
    LblLeadTimeVal.Caption := 'N/D';
  end;

  try
    TotalBugs := TMetricas.TotalBugs(SprintId);
    LblBugsVal.Caption := IntToStr(TotalBugs);
  except
    LblBugsVal.Caption := 'N/D';
  end;

  try
    TaxaBugs := TMetricas.TaxaBugs(SprintId);
    LblTaxaBugsVal.Caption := Format('%.1f%%', [TaxaBugs]);
  except
    LblTaxaBugsVal.Caption := 'N/D';
  end;
end;

procedure TFormMetricas.CmbProjetoChange(Sender: TObject);
begin
  CarregarSprints;
end;

procedure TFormMetricas.BtnAtualizarClick(Sender: TObject);
begin
  AtualizarMetricas;
end;

procedure TFormMetricas.BtnFecharClick(Sender: TObject);
begin
  Close;
end;

end.
