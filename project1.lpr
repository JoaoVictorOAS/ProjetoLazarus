program project1;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  {$IFDEF HASAMIGA}
  athreads,
  {$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Forms, SysUtils, Dialogs,
  UDBConnection,
  Unit1
  { you can add units after this };

{$R *.res}

begin
  RequireDerivedFormResource:=True;
  Application.Scaled:=True;
  {$PUSH}{$WARN 5044 OFF}
  Application.MainFormOnTaskbar:=True;
  {$POP}
  Application.Initialize;

  try
    TDBConnection.Initialize(ExtractFilePath(ParamStr(0)) + 'config.ini');
  except
    on E: Exception do
    begin
      MessageDlg('Erro ao conectar ao banco',
        'Não foi possível inicializar a conexão com o PostgreSQL.' + sLineBreak +
        'Verifique o config.ini na pasta do executável.' + sLineBreak + sLineBreak +
        E.ClassName + ': ' + E.Message,
        mtError, [mbOK], 0);
      Halt(1);
    end;
  end;

  try
    Application.CreateForm(TForm1, Form1);
    Application.Run;
  finally
    TDBConnection.Finalize;
  end;
end.
