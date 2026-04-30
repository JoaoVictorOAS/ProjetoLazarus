program AgileLazarus;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Interfaces,  // LCL obrigatório
  Forms,
  UDBConnection,
  FMain        in 'forms/FMain.pas' {FormMain};

{$R *.res}

begin
  Application.Title := 'AgileLazarus';
  Application.Initialize;

  // Inicializa banco SQLite ao lado do executável
  TDBConnection.Initialize(ExtractFilePath(ParamStr(0)) + 'agile.db');

  Application.CreateForm(TFormMain, FormMain);
  Application.Run;

  TDBConnection.Finalize;
end.
