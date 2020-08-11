unit db_helper;

interface

uses
  System.SysUtils, SQLiteTable3, forms, Classes, u_debug;

type
  tg_dbhelper = record
    var
      sldb: TSQLiteDatabase;
      sltb: TSQLIteTable;
    procedure create_msg_table();
    function exist_table(ownerId: string): Boolean;
    procedure get_chats(user_id: string; dt: string; vv: TStringList);
    procedure del_chats(user_id: string; today: Boolean);

    procedure get_chats_dt_all(user_id, dt: string; vv: TStringList);
  end;

var
  g_dbhelper: tg_dbhelper;

implementation

{ tg_dbhelper }

procedure tg_dbhelper.create_msg_table();
var
  ssql: string;
begin
//  ssql := ' CREATE TABLE IF NOT EXISTS   msg_' + ownerId + ' (_id INTEGER PRIMARY KEY AUTOINCREMENT,'
//  + 'itype VARCHAR NOT NULL,time_send VARCHAR NOT NULL,msgid VARCHAR NOT NULL,'
//  + 'from_userid VARCHAR,from_user_nickname VARCHAR,is_my_send VARCHAR,content VARCHAR,is_read VARCHAR,'
//   + 'room_flag VARCHAR,room_id VARCHAR,room_name VARCHAR)';


  ssql := 'CREATE TABLE IF NOT EXISTS   msg_account (_id INTEGER PRIMARY KEY AUTOINCREMENT,k varchar,v varchar)';
  sldb.ExecSQL(ssql);
end;




function tg_dbhelper.exist_table(ownerId: string): Boolean;
begin
  Result := g_dbhelper.sldb.TableExists('msg_' + ownerId);
end;

procedure tg_dbhelper.del_chats(user_id: string; today: Boolean);
var
  ssql: string;
begin
  if exist_table(user_id) then
  begin
    if today then
      ssql := 'DELETE FROM   msg_' + user_id + ' where dt=' + FormatDateTime('yyyymmdd', now)
    else
      ssql := 'DELETE FROM   msg_' + user_id;
    sldb.ExecSQL(ssql);
  end;
end;
                           //FormatDateTime('yyyymmdd', now)
procedure tg_dbhelper.get_chats(user_id,  dt: string; vv: TStringList);
begin
  if exist_table(user_id) then
  begin
//    if today then
//    begin
//      sltb := slDb.GetTable('SELECT content FROM msg_' + user_id + ' where is_read=' + unreaded + ' and dt=' +dt );
sldb.ExecSQL('update msg_'+user_id+' set is_read=''1''');
       sltb := slDb.GetTable('SELECT content FROM msg_' + user_id + ' where dt=' +dt );
//    end
//    else
//      sltb := slDb.GetTable('SELECT content FROM msg_' + user_id + ' where is_read=' + unreaded);
    while not sltb.EOF do
    begin
      vv.Add(sltb.FieldAsString(sltb.FieldIndex['content']));
      sltb.Next;
    end;

  end;
  sltb.Free;

end;



procedure tg_dbhelper.get_chats_dt_all(user_id,  dt: string; vv: TStringList);
begin
  if exist_table(user_id) then
  begin
    sltb := slDb.GetTable('SELECT k FROM msg_' + user_id  );

    while not sltb.EOF do
    begin
      vv.Add(sltb.FieldAsString(sltb.FieldIndex['k']));
      sltb.Next;
    end;

  end;
  sltb.Free;

end;

initialization

finalization
  if g_dbhelper.sldb <> nil then
    g_dbhelper.sldb.free;

end.

