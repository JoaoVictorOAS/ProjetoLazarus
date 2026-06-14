unit FMetricas;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs,
  StdCtrls, ExtCtrls, Grids,
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
    PnlVelocity    : TPanel;
    LblVelocityTit : TLabel;
    SgVelocity     : TStringGrid;
    PnlBurndown    : TPanel;
    LblBurndownTit : TLabel;
    SgBurndown     : TStringGrid;
    procedure FormCreate(Sender: TObject);
    procedure CmbProjetoChange(Sender: TObject);
    procedure BtnAtualizarClick(Sender: TObject);
    procedure BtnFecharClick(Sender: TObject);
  private
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
  SgVelocity.ColCount  := 3;
  SgVelocity.RowCount  := 1;
  SgVelocity.FixedRows := 1;
  SgVelocity.FixedCols := 0;
  SgVelocity.Cells[0, 0] := 'Sprint';
  SgVelocity.Cells[1, 0] := 'Capacidade';
  SgVelocity.Cells[2, 0] := 'Entregues';

  SgBurndown.ColCount  := 2;
  SgBurndown.RowCount  := 1;
  SgBurndown.FixedRows := 1;
  SgBurndown.FixedCols := 0;
  SgBurndown.Cells[0, 0] := 'Dia';
  SgBurndown.Cells[1, 0] := 'Pts Restantes';

  CarregarProjetos;
end;

procedure TFormMetricas.CarregarProjetos;
var
  Lista: TArrayProjeto;
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
  Lista: TArraySprint;
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
  Items: TArrayVelocityItem;
  I: Integer;
begin
  Items := TMetricas.Velocity(ProjetoIdSel);
  SgVelocity.RowCount := Length(Items) + 1;
  for I := 0 to High(Items) do
  begin
    SgVelocity.Cells[0, I + 1] := 'Sprint ' + IntToStr(Items[I].SprintNumero);
    SgVelocity.Cells[1, I + 1] := IntToStr(Items[I].CapacidadePts);
    SgVelocity.Cells[2, I + 1] := IntToStr(Items[I].PontosEntregues);
  end;
end;

procedure TFormMetricas.AtualizarBurndown;
var
  Items: TArrayBurndownItem;
  I: Integer;
begin
  Items := TMetricas.Burndown(SprintIdSel);
  SgBurndown.RowCount := Length(Items) + 1;
  for I := 0 to High(Items) do
  begin
    SgBurndown.Cells[0, I + 1] := Items[I].Dia;
    SgBurndown.Cells[1, I + 1] := IntToStr(Items[I].PontosRestantes);
  end;
end;

procedure TFormMetricas.AtualizarCards;
var
  SprintId: Integer;
begin
  SprintId := SprintIdSel;
  if SprintId <= 0 then Exit;

  try
    LblHorasPtsVal.Caption := Format('%.2f h/pt', [TMetricas.HorasPorPonto(SprintId)]);
  except
    LblHorasPtsVal.Caption := 'N/D';
  end;

  try
    LblLeadTimeVal.Caption := Format('%.1f dias', [TMetricas.LeadTimeMedio(SprintId)]);
  except
    LblLeadTimeVal.Caption := 'N/D';
  end;

  try
    LblBugsVal.Caption := IntToStr(TMetricas.TotalBugs(SprintId));
  except
    LblBugsVal.Caption := 'N/D';
  end;

  try
    LblTaxaBugsVal.Caption := Format('%.1f%%', [TMetricas.TaxaBugs(SprintId)]);
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
