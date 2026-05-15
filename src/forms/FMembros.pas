unit FMembros;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs,
  StdCtrls, Grids, ExtCtrls, Buttons,
  UMembros;

type
  TFormMembros = class(TForm)
    PnlLista      : TPanel;
    SgMembros     : TStringGrid;
    PnlBotoes     : TPanel;
    BtnNovo       : TButton;
    BtnEditar     : TButton;
    BtnDesativar  : TButton;
    BtnFechar     : TButton;
    PnlEdicao     : TPanel;
    LblNome       : TLabel;
    EdtNome       : TEdit;
    LblEmail      : TLabel;
    EdtEmail      : TEdit;
    LblPapel      : TLabel;
    CmbPapel      : TComboBox;
    BtnSalvar     : TButton;
    BtnCancelar   : TButton;
    ChkInativos   : TCheckBox;
    procedure FormCreate(Sender: TObject);
    procedure BtnNovoClick(Sender: TObject);
    procedure BtnEditarClick(Sender: TObject);
    procedure BtnDesativarClick(Sender: TObject);
    procedure BtnFecharClick(Sender: TObject);
    procedure BtnSalvarClick(Sender: TObject);
    procedure BtnCancelarClick(Sender: TObject);
    procedure ChkInativosChange(Sender: TObject);
  private
    FEditandoId: Integer;
    procedure CarregarGrid;
    procedure AbrirEdicao(AId: Integer);
    procedure FecharEdicao;
    function  IdSelecionado: Integer;
  public
  end;

var
  FormMembros: TFormMembros;

implementation

{$R *.lfm}

procedure TFormMembros.FormCreate(Sender: TObject);
var
  Papeis: TStringArray;
  P: string;
begin
  Caption := 'Membros da Equipe';
  Width   := 720;
  Height  := 500;

  SgMembros.ColCount := 5;
  SgMembros.FixedRows := 1;
  SgMembros.Cells[0,0] := 'ID';
  SgMembros.Cells[1,0] := 'Nome';
  SgMembros.Cells[2,0] := 'Papel';
  SgMembros.Cells[3,0] := 'Email';
  SgMembros.Cells[4,0] := 'Ativo';
  SgMembros.ColWidths[0] := 40;
  SgMembros.ColWidths[1] := 180;
  SgMembros.ColWidths[2] := 90;
  SgMembros.ColWidths[3] := 200;
  SgMembros.ColWidths[4] := 50;

  Papeis := TMembros.PapeisValidos;
  for P in Papeis do
    CmbPapel.Items.Add(P);

  PnlEdicao.Visible := False;
  FEditandoId := 0;

  CarregarGrid;
end;

procedure TFormMembros.CarregarGrid;
var
  Lista: TArray<TMembro>;
  I: Integer;
begin
  Lista := TMembros.Listar(not ChkInativos.Checked);
  SgMembros.RowCount := Length(Lista) + 1;
  for I := 0 to High(Lista) do
  begin
    SgMembros.Cells[0, I+1] := IntToStr(Lista[I].Id);
    SgMembros.Cells[1, I+1] := Lista[I].Nome;
    SgMembros.Cells[2, I+1] := Lista[I].Papel;
    SgMembros.Cells[3, I+1] := Lista[I].Email;
    SgMembros.Cells[4, I+1] := BoolToStr(Lista[I].Ativo, 'Sim', 'Não');
  end;
end;

function TFormMembros.IdSelecionado: Integer;
var
  Row: Integer;
begin
  Row := SgMembros.Row;
  if Row < 1 then
  begin
    Result := 0;
    Exit;
  end;
  Result := StrToIntDef(SgMembros.Cells[0, Row], 0);
end;

procedure TFormMembros.AbrirEdicao(AId: Integer);
var
  M: TMembro;
  Idx: Integer;
begin
  FEditandoId := AId;
  if AId > 0 then
  begin
    M := TMembros.BuscarPorId(AId);
    EdtNome.Text  := M.Nome;
    EdtEmail.Text := M.Email;
    Idx := CmbPapel.Items.IndexOf(M.Papel);
    if Idx >= 0 then CmbPapel.ItemIndex := Idx;
  end else
  begin
    EdtNome.Text  := '';
    EdtEmail.Text := '';
    CmbPapel.ItemIndex := -1;
  end;
  PnlEdicao.Visible := True;
  EdtNome.SetFocus;
end;

procedure TFormMembros.FecharEdicao;
begin
  PnlEdicao.Visible := False;
  FEditandoId := 0;
end;

procedure TFormMembros.BtnNovoClick(Sender: TObject);
begin
  AbrirEdicao(0);
end;

procedure TFormMembros.BtnEditarClick(Sender: TObject);
var
  Id: Integer;
begin
  Id := IdSelecionado;
  if Id = 0 then
  begin
    ShowMessage('Selecione um membro na lista.');
    Exit;
  end;
  AbrirEdicao(Id);
end;

procedure TFormMembros.BtnDesativarClick(Sender: TObject);
var
  Id: Integer;
begin
  Id := IdSelecionado;
  if Id = 0 then
  begin
    ShowMessage('Selecione um membro na lista.');
    Exit;
  end;
  if MessageDlg('Desativar este membro?', mtConfirmation, [mbYes, mbNo], 0) = mrYes then
  begin
    try
      TMembros.Desativar(Id);
      CarregarGrid;
    except
      on E: Exception do
        ShowMessage('Erro ao desativar: ' + E.Message);
    end;
  end;
end;

procedure TFormMembros.BtnFecharClick(Sender: TObject);
begin
  Close;
end;

procedure TFormMembros.BtnSalvarClick(Sender: TObject);
var
  M: TMembro;
begin
  if Trim(EdtNome.Text) = '' then
  begin
    ShowMessage('Informe o nome do membro.');
    EdtNome.SetFocus;
    Exit;
  end;
  if CmbPapel.ItemIndex < 0 then
  begin
    ShowMessage('Selecione o papel do membro.');
    CmbPapel.SetFocus;
    Exit;
  end;

  M.Id    := FEditandoId;
  M.Nome  := Trim(EdtNome.Text);
  M.Email := Trim(EdtEmail.Text);
  M.Papel := CmbPapel.Items[CmbPapel.ItemIndex];
  M.Ativo := True;

  try
    if FEditandoId = 0 then
      TMembros.Inserir(M)
    else
      TMembros.Atualizar(M);
    FecharEdicao;
    CarregarGrid;
  except
    on E: Exception do
      ShowMessage('Erro ao salvar: ' + E.Message);
  end;
end;

procedure TFormMembros.BtnCancelarClick(Sender: TObject);
begin
  FecharEdicao;
end;

procedure TFormMembros.ChkInativosChange(Sender: TObject);
begin
  CarregarGrid;
end;

end.
