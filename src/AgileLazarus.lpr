program AgileLazarus;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Interfaces,
  Forms,
  SysUtils,
  UDBConnection,
  FMain      in 'forms/FMain.pas'          {FormMain},
  FMembros   in 'forms/FMembros.pas'       {FormMembros},
  FProjetos  in 'forms/FProjetos.pas'      {FormProjetos},
  FSprints   in 'forms/FSprints.pas'       {FormSprints},
  FTarefas   in 'forms/FTarefas.pas'       {FormTarefas},
  FHorasTecnicas in 'forms/FHorasTecnicas.pas' {FormHorasTecnicas},
  FMetricas  in 'forms/FMetricas.pas'      {FormMetricas};

{$R *.res}

begin
  Application.Title := 'AgileLazarus';
  Application.Initialize;

  TDBConnection.Initialize(ExtractFilePath(ParamStr(0)) + 'config.ini');

  Application.CreateForm(TFormMain, FormMain);
  Application.Run;

  TDBConnection.Finalize;
end.
