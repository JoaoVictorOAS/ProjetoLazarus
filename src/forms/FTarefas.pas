unit FTarefas;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs,
  StdCtrls, ExtCtrls,
  UTarefas, USprints, UProjetos, UMembros;

type
  TFormTarefas = class(TForm)
    PnlTopo       : TPanel;
    LblProjeto    : TLabel;
    CmbProjeto    : TComboBox;
    LblSprint     : TLabel;
    CmbSprint     : TComboBox;
    BtnAtualizar  : TButton;
    PnlKanban     : TPanel;
    PnlBacklog    : TPanel;
    LblBacklog    : TLabel;
    LbBacklog     : TListBox;
    PnlTodo       : TPanel;
    LblTodo       : TLabel;
    LbTodo        : TListBox;
    PnlDoing      : TPanel;
    LblDoing      : TLabel;
    LbDoing       : TListBox;
    PnlReview     : TPanel;
    LblReview     : TLabel;
    LbReview      : TListBox;
    PnlDone       : TPanel;
    LblDone       : TLabel;
    LbDone        : TListBox;
    PnlAcoes      : TPanel;
    BtnNova       : TButton;
    BtnAvancar    : TButton;
    BtnVoltar     : TButton;
    BtnEditar     : TButton;
    BtnDeletar    : TButton;
    BtnFechar     : TButton;
    PnlEdicao     : TPanel;
    LblTitulo     : TLabel;
    EdtTitulo     : TEdit;
    LblTipo       : TLabel;
    CmbTipo       : TComboBox;
    LblPts        : TLabel;
    EdtPts        : TEdit;
    LblPrio       : TLabel;
    EdtPrio       : TEdit;
    LblMembro     : TLabel;
    CmbMembro     : TComboBox;
    LblDescTarefa : TLabel;
    MmoDesc       : TMemo;
    BtnSalvarT    : TButton;
    BtnCancelarT  : TButton;
    procedure FormCreate(Sender: TObject);
    procedure CmbProjetoChange(Sender: TObject);
    procedure CmbSprintChange(Sender: TObject);
    procedure BtnAtualizarClick(Sender: TObject);
    procedure BtnNovaClick(Sender: TObject);
    procedure BtnAvancarClick(Sender: TObject);
    procedure BtnVoltarClick(Sender: TObject);
    procedure BtnEditarClick(Sender: TObject);
    procedure BtnDeletarClick(Sender: TObject);
    procedure BtnFecharClick(Sender: TObject);
    procedure BtnSalvarTClick(Sender: TObject);
    procedure BtnCancelarTClick(Sender: TObject);
    procedure LbDblClick(Sender: TObject);
  private
    FEditandoId: Integer;
    procedure CarregarProjetos;
    procedure CarregarSprints;
    procedure CarregarMembros;
    procedure CarregarKanban;
    function  TarefaIdFocada: Integer;
    function  ListBoxFocada: TListBox;
    procedure AbrirEdicao(AId: Integer);
    procedure FecharEdicao;
    function  ProjetoIdSel: Integer;
    function  SprintIdSel: Integer;
    function  StatusDaColuna(ALb: TListBox): string;
    function  ProxStatus(const AAtual: string): string;
    function  AntStatus(const AAtual: string): string;
  public
  end;

var
  FormTarefas: TFormTarefas;

implementation

{$R *.lfm}

procedure TFormTarefas.FormCreate(Sender: TObject);
var
  T: string;
begin
  Caption := 'Tarefas / Kanban';
  Width   := 1100;
  Height  := 600;

  LbBacklog.OnDblClick := @LbDblClick;
  LbTodo.OnDblClick    := @LbDblClick;
  LbDoing.OnDblClick   := @LbDblClick;
  LbReview.OnDblClick  := @LbDblClick;
  LbDone.OnDblClick    := @LbDblClick;

  for T in TTarefas.TiposValidos do
    CmbTipo.Items.Add(T);

  PnlEdicao.Visible := False;
  FEditandoId := 0;
  CarregarProjetos;
end;

procedure TFormTarefas.CarregarProjetos;
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

procedure TFormTarefas.CarregarSprints;
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
    CmbSprint.Items.AddObject('Sprint ' + IntToStr(S.Numero) + ' — ' + S.Goal,
      TObject(PtrInt(S.Id)));

  if CmbSprint.Items.Count > 0 then
  begin
    CmbSprint.ItemIndex := 0;
    CarregarKanban;
  end;
end;

procedure TFormTarefas.CarregarMembros;
var
  Lista: TArray<TMembro>;
  M: TMembro;
begin
  CmbMembro.Clear;
  CmbMembro.Items.AddObject('(nenhum)', TObject(PtrInt(0)));
  Lista := TMembros.Listar(True);
  for M in Lista do
    CmbMembro.Items.AddObject(M.Nome, TObject(PtrInt(M.Id)));
end;

procedure TFormTarefas.CarregarKanban;
var
  Lista: TArray<TTarefa>;
  T: TTarefa;
begin
  LbBacklog.Clear;
  LbTodo.Clear;
  LbDoing.Clear;
  LbReview.Clear;
  LbDone.Clear;

  if SprintIdSel <= 0 then Exit;

  Lista := TTarefas.ListarPorSprint(SprintIdSel);
  for T in Lista do
  begin
    if T.Status = 'backlog' then
      LbBacklog.Items.AddObject('[' + IntToStr(T.Pontos) + 'pt] ' + T.Titulo,
        TObject(PtrInt(T.Id)))
    else if T.Status = 'todo' then
      LbTodo.Items.AddObject('[' + IntToStr(T.Pontos) + 'pt] ' + T.Titulo,
        TObject(PtrInt(T.Id)))
    else if T.Status = 'doing' then
      LbDoing.Items.AddObject('[' + IntToStr(T.Pontos) + 'pt] ' + T.Titulo,
        TObject(PtrInt(T.Id)))
    else if T.Status = 'review' then
      LbReview.Items.AddObject('[' + IntToStr(T.Pontos) + 'pt] ' + T.Titulo,
        TObject(PtrInt(T.Id)))
    else if T.Status = 'done' then
      LbDone.Items.AddObject('[' + IntToStr(T.Pontos) + 'pt] ' + T.Titulo,
        TObject(PtrInt(T.Id)));
  end;
end;

function TFormTarefas.ProjetoIdSel: Integer;
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

function TFormTarefas.SprintIdSel: Integer;
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

function TFormTarefas.ListBoxFocada: TListBox;
begin
  if LbBacklog.Focused then Result := LbBacklog
  else if LbTodo.Focused then Result := LbTodo
  else if LbDoing.Focused then Result := LbDoing
  else if LbReview.Focused then Result := LbReview
  else if LbDone.Focused then Result := LbDone
  else Result := nil;
end;

function TFormTarefas.TarefaIdFocada: Integer;
var
  Lb: TListBox;
  Idx: Integer;
begin
  Lb := ListBoxFocada;
  if Lb = nil then
  begin
    Result := 0;
    Exit;
  end;
  Idx := Lb.ItemIndex;
  if Idx < 0 then
  begin
    Result := 0;
    Exit;
  end;
  Result := PtrInt(Lb.Items.Objects[Idx]);
end;

function TFormTarefas.StatusDaColuna(ALb: TListBox): string;
begin
  if ALb = LbBacklog then Result := 'backlog'
  else if ALb = LbTodo then Result := 'todo'
  else if ALb = LbDoing then Result := 'doing'
  else if ALb = LbReview then Result := 'review'
  else if ALb = LbDone then Result := 'done'
  else Result := '';
end;

function TFormTarefas.ProxStatus(const AAtual: string): string;
begin
  if AAtual = 'backlog' then Result := 'todo'
  else if AAtual = 'todo' then Result := 'doing'
  else if AAtual = 'doing' then Result := 'review'
  else if AAtual = 'review' then Result := 'done'
  else Result := AAtual;
end;

function TFormTarefas.AntStatus(const AAtual: string): string;
begin
  if AAtual = 'done' then Result := 'review'
  else if AAtual = 'review' then Result := 'doing'
  else if AAtual = 'doing' then Result := 'todo'
  else if AAtual = 'todo' then Result := 'backlog'
  else Result := AAtual;
end;

procedure TFormTarefas.AbrirEdicao(AId: Integer);
var
  T: TTarefa;
  Idx: Integer;
begin
  FEditandoId := AId;
  CarregarMembros;
  if AId > 0 then
  begin
    T := TTarefas.BuscarPorId(AId);
    EdtTitulo.Text := T.Titulo;
    MmoDesc.Text   := T.Descricao;
    Idx := CmbTipo.Items.IndexOf(T.Tipo);
    if Idx >= 0 then CmbTipo.ItemIndex := Idx;
    EdtPts.Text    := IntToStr(T.Pontos);
    EdtPrio.Text   := IntToStr(T.Prioridade);
    Idx := CmbMembro.Items.IndexOf(IntToStr(T.MembroId));
    if Idx >= 0 then CmbMembro.ItemIndex := Idx
    else CmbMembro.ItemIndex := 0;
  end else
  begin
    EdtTitulo.Text := '';
    MmoDesc.Text   := '';
    CmbTipo.ItemIndex := 0;
    EdtPts.Text    := '1';
    EdtPrio.Text   := '2';
    CmbMembro.ItemIndex := 0;
  end;
  PnlEdicao.Visible := True;
  EdtTitulo.SetFocus;
end;

procedure TFormTarefas.FecharEdicao;
begin
  PnlEdicao.Visible := False;
  FEditandoId := 0;
end;

procedure TFormTarefas.CmbProjetoChange(Sender: TObject);
begin
  CarregarSprints;
end;

procedure TFormTarefas.CmbSprintChange(Sender: TObject);
begin
  CarregarKanban;
end;

procedure TFormTarefas.BtnAtualizarClick(Sender: TObject);
begin
  CarregarKanban;
end;

procedure TFormTarefas.BtnNovaClick(Sender: TObject);
begin
  AbrirEdicao(0);
end;

procedure TFormTarefas.BtnAvancarClick(Sender: TObject);
var
  Id: Integer;
  Lb: TListBox;
  StatusAtual, Prox: string;
begin
  Lb := ListBoxFocada;
  if Lb = nil then
  begin
    ShowMessage('Selecione uma tarefa em alguma coluna.');
    Exit;
  end;
  Id := TarefaIdFocada;
  if Id = 0 then
  begin
    ShowMessage('Selecione uma tarefa.');
    Exit;
  end;
  StatusAtual := StatusDaColuna(Lb);
  Prox := ProxStatus(StatusAtual);
  if Prox = StatusAtual then
  begin
    ShowMessage('A tarefa já está em "done".');
    Exit;
  end;
  try
    TTarefas.MoverStatus(Id, Prox);
    CarregarKanban;
  except
    on E: Exception do
      ShowMessage('Erro: ' + E.Message);
  end;
end;

procedure TFormTarefas.BtnVoltarClick(Sender: TObject);
var
  Id: Integer;
  Lb: TListBox;
  StatusAtual, Ant: string;
begin
  Lb := ListBoxFocada;
  if Lb = nil then
  begin
    ShowMessage('Selecione uma tarefa em alguma coluna.');
    Exit;
  end;
  Id := TarefaIdFocada;
  if Id = 0 then
  begin
    ShowMessage('Selecione uma tarefa.');
    Exit;
  end;
  StatusAtual := StatusDaColuna(Lb);
  Ant := AntStatus(StatusAtual);
  if Ant = StatusAtual then
  begin
    ShowMessage('A tarefa já está em "backlog".');
    Exit;
  end;
  try
    TTarefas.MoverStatus(Id, Ant);
    CarregarKanban;
  except
    on E: Exception do
      ShowMessage('Erro: ' + E.Message);
  end;
end;

procedure TFormTarefas.BtnEditarClick(Sender: TObject);
var
  Id: Integer;
begin
  Id := TarefaIdFocada;
  if Id = 0 then
  begin
    ShowMessage('Selecione uma tarefa.');
    Exit;
  end;
  AbrirEdicao(Id);
end;

procedure TFormTarefas.BtnDeletarClick(Sender: TObject);
var
  Id: Integer;
begin
  Id := TarefaIdFocada;
  if Id = 0 then
  begin
    ShowMessage('Selecione uma tarefa.');
    Exit;
  end;
  if MessageDlg('Excluir esta tarefa?', mtConfirmation, [mbYes, mbNo], 0) = mrYes then
  begin
    try
      TTarefas.Deletar(Id);
      CarregarKanban;
    except
      on E: Exception do
        ShowMessage('Erro ao excluir: ' + E.Message);
    end;
  end;
end;

procedure TFormTarefas.BtnFecharClick(Sender: TObject);
begin
  Close;
end;

procedure TFormTarefas.BtnSalvarTClick(Sender: TObject);
var
  T: TTarefa;
  MemIdx: Integer;
begin
  if Trim(EdtTitulo.Text) = '' then
  begin
    ShowMessage('Informe o título da tarefa.');
    EdtTitulo.SetFocus;
    Exit;
  end;

  T.Id        := FEditandoId;
  T.SprintId  := SprintIdSel;
  T.Titulo    := Trim(EdtTitulo.Text);
  T.Descricao := Trim(MmoDesc.Text);
  if CmbTipo.ItemIndex >= 0 then
    T.Tipo := CmbTipo.Items[CmbTipo.ItemIndex]
  else
    T.Tipo := 'task';
  T.Status    := 'backlog';
  T.Pontos    := StrToIntDef(Trim(EdtPts.Text), 1);
  T.Prioridade := StrToIntDef(Trim(EdtPrio.Text), 2);

  MemIdx := CmbMembro.ItemIndex;
  if MemIdx > 0 then
    T.MembroId := PtrInt(CmbMembro.Items.Objects[MemIdx])
  else
    T.MembroId := 0;

  try
    if FEditandoId = 0 then
      TTarefas.Inserir(T)
    else
    begin
      T.Status := TTarefas.BuscarPorId(FEditandoId).Status;
      TTarefas.Atualizar(T);
    end;
    FecharEdicao;
    CarregarKanban;
  except
    on E: Exception do
      ShowMessage('Erro ao salvar: ' + E.Message);
  end;
end;

procedure TFormTarefas.BtnCancelarTClick(Sender: TObject);
begin
  FecharEdicao;
end;

procedure TFormTarefas.LbDblClick(Sender: TObject);
var
  Lb: TListBox;
  Idx, Id: Integer;
begin
  Lb := Sender as TListBox;
  Idx := Lb.ItemIndex;
  if Idx < 0 then Exit;
  Id := PtrInt(Lb.Items.Objects[Idx]);
  AbrirEdicao(Id);
end;

end.
