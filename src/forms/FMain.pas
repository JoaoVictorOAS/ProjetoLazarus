unit FMain;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, Menus, ComCtrls,
  StdCtrls, ExtCtrls,
  FMembros, FProjetos, FSprints, FTarefas, FHorasTecnicas, FMetricas;

type
  TFormMain = class(TForm)
    MainMenu1    : TMainMenu;
    MnuCadastros : TMenuItem;
    MnuMembros   : TMenuItem;
    MnuProjetos  : TMenuItem;
    MnuSprints   : TMenuItem;
    MnuTarefas   : TMenuItem;
    MnuHoras     : TMenuItem;
    MnuMetricas  : TMenuItem;
    MnuSep1      : TMenuItem;
    MnuSair      : TMenuItem;
    PnlStatus    : TPanel;
    LblStatus    : TLabel;
    procedure MnuMembrosClick(Sender: TObject);
    procedure MnuProjetosClick(Sender: TObject);
    procedure MnuSprintsClick(Sender: TObject);
    procedure MnuTarefasClick(Sender: TObject);
    procedure MnuHorasClick(Sender: TObject);
    procedure MnuMetricasClick(Sender: TObject);
    procedure MnuSairClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
  public
  end;

var
  FormMain: TFormMain;

implementation

{$R *.lfm}

procedure TFormMain.FormCreate(Sender: TObject);
begin
  Caption := 'AgileLazarus — Gestão Ágil';
  LblStatus.Caption := 'Pronto';
end;

procedure TFormMain.MnuMembrosClick(Sender: TObject);
var
  F: TFormMembros;
begin
  F := TFormMembros.Create(Self);
  try
    F.ShowModal;
  finally
    F.Free;
  end;
end;

procedure TFormMain.MnuProjetosClick(Sender: TObject);
var
  F: TFormProjetos;
begin
  F := TFormProjetos.Create(Self);
  try
    F.ShowModal;
  finally
    F.Free;
  end;
end;

procedure TFormMain.MnuSprintsClick(Sender: TObject);
var
  F: TFormSprints;
begin
  F := TFormSprints.Create(Self);
  try
    F.ShowModal;
  finally
    F.Free;
  end;
end;

procedure TFormMain.MnuTarefasClick(Sender: TObject);
var
  F: TFormTarefas;
begin
  F := TFormTarefas.Create(Self);
  try
    F.ShowModal;
  finally
    F.Free;
  end;
end;

procedure TFormMain.MnuHorasClick(Sender: TObject);
var
  F: TFormHorasTecnicas;
begin
  F := TFormHorasTecnicas.Create(Self);
  try
    F.ShowModal;
  finally
    F.Free;
  end;
end;

procedure TFormMain.MnuMetricasClick(Sender: TObject);
var
  F: TFormMetricas;
begin
  F := TFormMetricas.Create(Self);
  try
    F.ShowModal;
  finally
    F.Free;
  end;
end;

procedure TFormMain.MnuSairClick(Sender: TObject);
begin
  Close;
end;

end.
