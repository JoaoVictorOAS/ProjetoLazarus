unit FProjetos;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs,
  StdCtrls, Grids, ExtCtrls, ComCtrls,
  UProjetos, UMembros;

type
  TFormProjetos = class(TForm)
    PnlLista     : TPanel;
    SgProjetos   : TStringGrid;
    PnlAcoes     : TPanel;
    BtnNovo      : TButton;
    BtnEditar    : TButton;
    BtnEncerrar  : TButton;
    BtnFechar    : TButton;
    PcEdicao     : TPageControl;
    TabDados     : TTabSheet;
    TabMembros   : TTabSheet;
    LblNome      : TLabel;
    EdtNome      : TEdit;
    LblDesc      : TLabel;
    MmoDesc      : TMemo;
    LblStatus    : TLabel;
    CmbStatus    : TComboBox;
    LblInicio    : TLabel;
    EdtInicio    : TEdit;
    LblFim       : TLabel;
    EdtFim       : TEdit;
    BtnSalvar    : TButton;
    BtnCancelar  : TButton;
    LbDisponiveis: TListBox;
    LblDisp      : TLabel;
    LbNoProjeto  : TListBox;
    LblNoPrj     : TLabel;
    BtnAdd       : TButton;
    BtnRemover   : TButton;
    procedure FormCreate(Sender: TObject);
    procedure BtnNovoClick(Sender: TObject);
    procedure BtnEditarClick(Sender: TObject);
    procedure BtnEncerrarClick(Sender: TObject);
    procedure BtnFecharClick(Sender: TObject);
    procedure BtnSalvarClick(Sender: TObject);
    procedure BtnCancelarClick(Sender: TObject);
    procedure BtnAddClick(Sender: TObject);
    procedure BtnRemoverClick(Sender: TObject);
    procedure SgProjetosSelectCell(Sender: TObject; aCol, aRow: Integer;
      var CanSelect: Boolean);
  private
    FEditandoId : Integer;
    procedure CarregarGrid;
    procedure AbrirEdicao(AId: Integer);
    procedure FecharEdicao;
    procedure CarregarMembros(AProjetoId: Integer);
    function  IdSelecionado: Integer;
  public
  end;

var
  FormProjetos: TFormProjetos;

implementation

{$R *.lfm}

procedure TFormProjetos.FormCreate(Sender: TObject);
var
  S: string;
begin
  Caption := 'Projetos';
  Width   := 820;
  Height  := 540;

  SgProjetos.ColCount := 5;
  SgProjetos.FixedRows := 1;
  SgProjetos.Cells[0,0] := 'ID';
  SgProjetos.Cells[1,0] := 'Nome';
  SgProjetos.Cells[2,0] := 'Status';
  SgProjetos.Cells[3,0] := 'Início';
  SgProjetos.Cells[4,0] := 'Fim';
  SgProjetos.ColWidths[0] := 40;
  SgProjetos.ColWidths[1] := 200;
  SgProjetos.ColWidths[2] := 90;
  SgProjetos.ColWidths[3] := 90;
  SgProjetos.ColWidths[4] := 90;

  for S in TProjetos.StatusValidos do
    CmbStatus.Items.Add(S);

  PcEdicao.Visible := False;
  FEditandoId := 0;
  CarregarGrid;
end;

procedure TFormProjetos.CarregarGrid;
var
  Lista: TArray<TProjeto>;
  I: Integer;
begin
  Lista := TProjetos.Listar;
  SgProjetos.RowCount := Length(Lista) + 1;
  for I := 0 to High(Lista) do
  begin
    SgProjetos.Cells[0, I+1] := IntToStr(Lista[I].Id);
    SgProjetos.Cells[1, I+1] := Lista[I].Nome;
    SgProjetos.Cells[2, I+1] := Lista[I].Status;
    SgProjetos.Cells[3, I+1] := Lista[I].DataInicio;
    SgProjetos.Cells[4, I+1] := Lista[I].DataFim;
  end;
end;

function TFormProjetos.IdSelecionado: Integer;
var
  Row: Integer;
begin
  Row := SgProjetos.Row;
  if Row < 1 then
  begin
    Result := 0;
    Exit;
  end;
  Result := StrToIntDef(SgProjetos.Cells[0, Row], 0);
end;

procedure TFormProjetos.CarregarMembros(AProjetoId: Integer);
var
  TodosMembros: TArray<TMembro>;
  NoProjeto: TArray<Integer>;
  M: TMembro;
  Id: Integer;
  EstaNoProj: Boolean;
begin
  LbDisponiveis.Clear;
  LbNoProjeto.Clear;

  TodosMembros := TMembros.Listar(True);
  NoProjeto := TProjetos.ListarMembros(AProjetoId);

  for M in TodosMembros do
  begin
    EstaNoProj := False;
    for Id in NoProjeto do
      if Id = M.Id then
      begin
        EstaNoProj := True;
        Break;
      end;

    if EstaNoProj then
      LbNoProjeto.Items.AddObject(M.Nome + ' (' + M.Papel + ')', TObject(PtrInt(M.Id)))
    else
      LbDisponiveis.Items.AddObject(M.Nome + ' (' + M.Papel + ')', TObject(PtrInt(M.Id)));
  end;
end;

procedure TFormProjetos.AbrirEdicao(AId: Integer);
var
  P: TProjeto;
  Idx: Integer;
begin
  FEditandoId := AId;
  if AId > 0 then
  begin
    P := TProjetos.BuscarPorId(AId);
    EdtNome.Text  := P.Nome;
    MmoDesc.Text  := P.Descricao;
    Idx := CmbStatus.Items.IndexOf(P.Status);
    if Idx >= 0 then CmbStatus.ItemIndex := Idx;
    EdtInicio.Text := P.DataInicio;
    EdtFim.Text    := P.DataFim;
    CarregarMembros(AId);
  end else
  begin
    EdtNome.Text   := '';
    MmoDesc.Text   := '';
    CmbStatus.ItemIndex := 0;
    EdtInicio.Text := FormatDateTime('yyyy-mm-dd', Now);
    EdtFim.Text    := '';
    LbDisponiveis.Clear;
    LbNoProjeto.Clear;
  end;
  PcEdicao.Visible := True;
  EdtNome.SetFocus;
end;

procedure TFormProjetos.FecharEdicao;
begin
  PcEdicao.Visible := False;
  FEditandoId := 0;
end;

procedure TFormProjetos.BtnNovoClick(Sender: TObject);
begin
  AbrirEdicao(0);
end;

procedure TFormProjetos.BtnEditarClick(Sender: TObject);
var
  Id: Integer;
begin
  Id := IdSelecionado;
  if Id = 0 then
  begin
    ShowMessage('Selecione um projeto na lista.');
    Exit;
  end;
  AbrirEdicao(Id);
end;

procedure TFormProjetos.BtnEncerrarClick(Sender: TObject);
var
  Id: Integer;
begin
  Id := IdSelecionado;
  if Id = 0 then
  begin
    ShowMessage('Selecione um projeto na lista.');
    Exit;
  end;
  if MessageDlg('Encerrar este projeto?', mtConfirmation, [mbYes, mbNo], 0) = mrYes then
  begin
    try
      TProjetos.Encerrar(Id);
      CarregarGrid;
    except
      on E: Exception do
        ShowMessage('Erro ao encerrar: ' + E.Message);
    end;
  end;
end;

procedure TFormProjetos.BtnFecharClick(Sender: TObject);
begin
  Close;
end;

procedure TFormProjetos.BtnSalvarClick(Sender: TObject);
var
  P: TProjeto;
  NovoId: Integer;
begin
  if Trim(EdtNome.Text) = '' then
  begin
    ShowMessage('Informe o nome do projeto.');
    EdtNome.SetFocus;
    Exit;
  end;

  P.Id        := FEditandoId;
  P.Nome      := Trim(EdtNome.Text);
  P.Descricao := Trim(MmoDesc.Text);
  if CmbStatus.ItemIndex >= 0 then
    P.Status := CmbStatus.Items[CmbStatus.ItemIndex]
  else
    P.Status := 'ativo';
  P.DataInicio := Trim(EdtInicio.Text);
  P.DataFim    := Trim(EdtFim.Text);

  try
    if FEditandoId = 0 then
    begin
      NovoId := TProjetos.Inserir(P);
      FEditandoId := NovoId;
    end else
      TProjetos.Atualizar(P);
    FecharEdicao;
    CarregarGrid;
  except
    on E: Exception do
      ShowMessage('Erro ao salvar: ' + E.Message);
  end;
end;

procedure TFormProjetos.BtnCancelarClick(Sender: TObject);
begin
  FecharEdicao;
end;

procedure TFormProjetos.BtnAddClick(Sender: TObject);
var
  Idx, MembroId: Integer;
begin
  if FEditandoId <= 0 then
  begin
    ShowMessage('Salve o projeto antes de associar membros.');
    Exit;
  end;
  Idx := LbDisponiveis.ItemIndex;
  if Idx < 0 then
  begin
    ShowMessage('Selecione um membro disponível.');
    Exit;
  end;
  MembroId := PtrInt(LbDisponiveis.Items.Objects[Idx]);
  try
    TProjetos.AssociarMembro(FEditandoId, MembroId);
    CarregarMembros(FEditandoId);
  except
    on E: Exception do
      ShowMessage('Erro ao associar: ' + E.Message);
  end;
end;

procedure TFormProjetos.BtnRemoverClick(Sender: TObject);
var
  Idx, MembroId: Integer;
begin
  if FEditandoId <= 0 then Exit;
  Idx := LbNoProjeto.ItemIndex;
  if Idx < 0 then
  begin
    ShowMessage('Selecione um membro do projeto.');
    Exit;
  end;
  MembroId := PtrInt(LbNoProjeto.Items.Objects[Idx]);
  try
    TProjetos.RemoverMembro(FEditandoId, MembroId);
    CarregarMembros(FEditandoId);
  except
    on E: Exception do
      ShowMessage('Erro ao remover: ' + E.Message);
  end;
end;

procedure TFormProjetos.SgProjetosSelectCell(Sender: TObject; aCol,
  aRow: Integer; var CanSelect: Boolean);
begin
  CanSelect := True;
end;

end.
