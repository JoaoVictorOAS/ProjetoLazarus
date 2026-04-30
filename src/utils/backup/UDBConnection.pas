unit UDBConnection;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, IniFiles, pqconnection, sqldb;

type
  TDBConnection = class
  private
    class var FConn : TPQConnection;
    class var FTrans: TSQLTransaction;
  public
    class procedure Initialize(const AConfigPath: string);
    class procedure Finalize;
    class function  Connection: TPQConnection;
    class function  Transaction: TSQLTransaction;
    class function  NewQuery: TSQLQuery;
    class procedure Commit;
    class procedure Rollback;
  end;

implementation

class procedure TDBConnection.Initialize(const AConfigPath: string);
var
  Ini: TIniFile;
begin
  Ini := TIniFile.Create(AConfigPath);
  try
    FConn  := TPQConnection.Create(nil);
    FTrans := TSQLTransaction.Create(nil);
    FConn.Transaction := FTrans;
    FTrans.DataBase   := FConn;
    FConn.HostName     := Ini.ReadString('database', 'host',     'localhost');
    FConn.DatabaseName := Ini.ReadString('database', 'database', 'agile_db');
    FConn.UserName     := Ini.ReadString('database', 'user',     'agile');
    FConn.Password     := Ini.ReadString('database', 'password', '');
    FConn.Params.Values['port'] := Ini.ReadString('database', 'port', '5432');
    FConn.Open;
  finally
    Ini.Free;
  end;
end;

class procedure TDBConnection.Finalize;
begin
  if Assigned(FTrans) and FTrans.Active then
    FTrans.Commit;
  if Assigned(FConn) and FConn.Connected then
    FConn.Close;
  FreeAndNil(FTrans);
  FreeAndNil(FConn);
end;

class function TDBConnection.Connection: TPQConnection;
begin
  Result := FConn;
end;

class function TDBConnection.Transaction: TSQLTransaction;
begin
  Result := FTrans;
end;

class function TDBConnection.NewQuery: TSQLQuery;
begin
  Result := TSQLQuery.Create(nil);
  Result.DataBase    := FConn;
  Result.Transaction := FTrans;
end;

class procedure TDBConnection.Commit;
begin
  FTrans.Commit;
end;

class procedure TDBConnection.Rollback;
begin
  FTrans.Rollback;
end;

end.
