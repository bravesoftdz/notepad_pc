unit protocol_bas;

interface

uses
  global, winapi.windows, system.sysutils, idglobal, u_debug, system.classes,
  qjson;

const
  mod_player = $1;

type
  tprotocol = class
  private
    function hextoint(str: ansistring): word;
  protected
    json: tqjson;
    protocolby: tarray<byte>;
    bs: tidbytes;
    fcommand: byte;
    fdata: pansichar;
    flen: integer;
    fposition: integer;
    function fill_head(i: integer): tarray<byte>;
    procedure writebufdata(var buf; alen: integer; writehead: boolean = false);
    procedure writestr(value: ansistring);
    procedure writestrdata(tmp: ansistring);
    function datalen(arrby: array of byte): dword;
    procedure prepare; virtual;
    constructor create; virtual;
    destructor destroy; override;
  public
    procedure send_package;
  end;

  // $ff
  theartbeat = class(tprotocol)
    procedure prepare(); override;
    constructor create; override;
  end;


  // $12   推送协议    单用户推送对话

  tprotocol_chat_pull = class(tprotocol)
  public
    fromid, toid: string;
    pulldata: tpush_pack;
    procedure prepare(); override;
    constructor create; override;
  end;



  // $01   登录
  tprotocol_login = class(tprotocol)
    procedure prepare(); override;
    constructor create; override;
  end;


  // $0c   群聊  推送
  tprotocol_room_pull = class(tprotocol)
    groupid: string;
    pulldata: tpush_pack;
    procedure prepare(); override;
    constructor create; override;
  end;




  tprotocol_room_create = class(tprotocol)
    dstemployeesid: string;
    pulldata: tpush_pack;
    procedure prepare(); override;
    constructor create; override;
  end;



  // 退出群组
  tprotocol_room_exit = class(tprotocol)
    exit_groupid: string;
    exit_members: string;
    exit_id: string;
    procedure prepare(); override;
    constructor create; override;
  end;

implementation

uses
  varcoreunit, core;

function tprotocol.hextoint(str: ansistring): word;
var
  i, value: word;
  pos: word;
begin
  result := 0;
  value := 0;
  pos := length(str);
  for i := 1 to pos do
  begin
    case str[i] of
      'f', 'F':
        value := value * 16 + 15;
      'e', 'E':
        value := value * 16 + 14;
      'd', 'D':
        value := value * 16 + 13;
      'c', 'C':
        value := value * 16 + 12;
      'b', 'B':
        value := value * 16 + 11;
      'a', 'A':
        value := value * 16 + 10;
      '0'..'9':
        value := value * 16 + ord(str[i]) - ord('0');
    else
      result := value;
      exit;
    end;
    result := value;
  end;

end;

procedure tprotocol.prepare;
var
  l: byte;
begin
  freemem(fdata);
  fdata := nil;
  // 登录数据写入内存
  // 协议
  l := mod_player;
  writebufdata(l, sizeof(byte));
end;

procedure tprotocol.send_package;
begin
  if length(bs) > 65530 then
    exit;

  g_global.g_communication.send_tcp_data(bs);

end;

constructor tprotocol.create;
begin
  json := tqjson.create;
end;

function tprotocol.datalen(arrby: array of byte): dword;
begin
  result := hextoint(inttohex(arrby[0], 2) + inttohex(arrby[1], 2) + inttohex(arrby[2], 2) + inttohex(arrby[3], 2));

end;

procedure tprotocol.writebufdata(var buf; alen: integer; writehead: boolean);
begin
  if not writehead then
  begin
    if fdata = nil then
    begin
      getmem(fdata, alen + 4);
      move(buf, (fdata + 4)^, alen);

      // GetMem(FData, ALen);
      // Move(buf, (FData)^, ALen);
      fposition := 4 + alen;
      flen := fposition;
      exit;
    end;
    reallocmem(fdata, fposition + alen);
    move(buf, (fdata + fposition)^, alen);
    fposition := fposition + alen;
    flen := fposition;
  end
  else
  begin
    move(protocolby[0], fdata[0], alen);

    move(buf, fdata^, alen);
    flen := fposition;
  end;
end;

procedure tprotocol.writestr(value: ansistring);
var
  l: integer;
begin
  l := length(value);
  writebufdata(value[1], l);
end;

procedure tprotocol.writestrdata(tmp: ansistring);
var
  l, zero: word;
begin
  l := length(tmp);
  if l > $ff then
  begin
    writebufdata(wordrec(l).hi, sizeof(byte));
    writebufdata(wordrec(l).lo, sizeof(byte));
  end
  else
  begin
    zero := 0;
    writebufdata(zero, sizeof(byte));
    writebufdata(l, sizeof(byte))
  end;
  writestr(tmp);
end;

destructor tprotocol.destroy;
begin
  json.free;
  freemem(fdata);
  inherited;
end;

function tprotocol.fill_head(i: integer): tarray<byte>;
begin
  setlength(result, 4);

  result[3] := ($ff and i);
  result[2] := ($ff00 and i) shr 8;
  result[1] := ($ff0000 and i) shr 16;
  result[0] := ($ff000000 and i) shr 24;

end;

{ tprotocol_login }

constructor tprotocol_login.create;
begin
  inherited;
  fcommand := $01;
end;

procedure tprotocol_login.prepare;
var
  l: byte;
  datalen: integer;
begin
  inherited;
  // 登录数据写入内存
  // 协议
  writebufdata(fcommand, sizeof(byte));
  writestrdata(g_global.imp.mLoginUser.user_id);

  // 登录类型 0 windows 1 android 2 iphone
  l := 0;
  writebufdata(l, sizeof(byte));

  datalen := sizeof(byte) * 2 + sizeof(byte) * 2 + length(g_global.imp.mLoginUser.user_id) + sizeof(byte);

  // 写数据长度
  protocolby := fill_head(sizeof(byte) * datalen);
  writebufdata(protocolby[0], 4, true);

  bs := rawtobytes(fdata[0], flen);

end;

{ THeartbeat }
// 心跳包
constructor theartbeat.create;
begin
  inherited;
  fcommand := $ff;
end;

procedure theartbeat.prepare;
var
  datalen: integer;
begin
  inherited;
  writebufdata(fcommand, sizeof(byte));

  // 数据长度写入包头
  datalen := sizeof(byte) * 2;

  // 写数据长度
  protocolby := fill_head(sizeof(byte) * datalen);
  writebufdata(protocolby[0], 4, true);

  bs := rawtobytes(fdata[0], flen);
end;

{ TChat0C }

constructor tprotocol_room_pull.create;
begin
  inherited;
  fcommand := $0c;
end;

procedure tprotocol_room_pull.prepare;
var
  datalen: integer;
  jsdata: string;
begin
  inherited;

  writebufdata(fcommand, sizeof(byte));
  writestrdata(groupid);
  json.fromrecord(pulldata);
  jsdata := json.asjson;
  writestrdata(jsdata);

  // 数据长度写入包头
  datalen := sizeof(byte) * 2 + sizeof(byte) * 2 + length(groupid) + sizeof(byte) * 2 + length(jsdata);

  // 写数据长度
  protocolby := fill_head(sizeof(byte) * datalen);
  writebufdata(protocolby[0], 4, true);
  bs := rawtobytes(fdata[0], flen);

end;


{ TProtocolPush }

constructor tprotocol_chat_pull.create;
begin
  inherited;
  fcommand := $12;

end;

procedure tprotocol_chat_pull.prepare;
var
  datalen: integer;
  jsdata: string;
begin
  inherited;
  writebufdata(fcommand, sizeof(byte));
  writestrdata(fromid); // 谁发的

  writestrdata(toid); // 谁发的

  json.fromrecord(pulldata);
  jsdata := json.asjson;
  writestrdata(jsdata); // 谁发的

  datalen := sizeof(byte) * 2 + sizeof(byte) * 2 + length(fromid) + sizeof(byte) * 2 + length(toid) + sizeof(byte) * 2 + length(jsdata); // + sizeof(byte);
  // 写数据长度
  protocolby := fill_head(sizeof(byte) * datalen);
  writebufdata(protocolby[0], 4, true);

  bs := rawtobytes(fdata[0], flen);

end;

{ TGroupCreate17 }

constructor tprotocol_room_create.create;
begin
  inherited;
  fcommand := 9;
end;

procedure tprotocol_room_create.prepare;
var
  datalen: integer;
  jsdata: ansistring; // 注意 ansi
begin
  inherited;
  writebufdata(fcommand, sizeof(byte));
  writestrdata(dstemployeesid); // 目标人群

  json.fromrecord(pulldata);
  jsdata := json.asjson;
  writestrdata(jsdata); // 谁发的

  datalen := sizeof(byte) * 2 + sizeof(byte) * 2 + length(dstemployeesid) + sizeof(byte) * 2 + length(jsdata); // + sizeof(byte);
  // 写数据长度
  protocolby := fill_head(sizeof(byte) * datalen);
  writebufdata(protocolby[0], 4, true);

  bs := rawtobytes(fdata[0], flen);

end;

{ tprotocol_room_dis }
//
//constructor tprotocol_room_dis.create;
//begin
//  inherited;
//  fcommand := 19;
//end;
//
//procedure tprotocol_room_dis.prepare;
//var
//  datalen: integer;
//begin
//  inherited;
//  writebufdata(fcommand, sizeof(byte));
//  writestrdata(dis_groupid); // 群组中的人员列表
//
//  writestrdata(dis_members); // 群组中的人员列表
//
//  datalen := sizeof(byte) * 2 + sizeof(byte) * 2 + length(dis_groupid) + sizeof(byte) * 2 + length(dis_members);
//
//  // 写数据长度
//  protocolby := fill_head(sizeof(byte) * datalen);
//  writebufdata(protocolby[0], 4, true);
//
//  bs := rawtobytes(fdata[0], flen);
//
//end;

{ tprotocol_room_exit }

constructor tprotocol_room_exit.create;
begin
  inherited;
  fcommand := 20;
end;

procedure tprotocol_room_exit.prepare;
var
  datalen: integer;
begin
  inherited;
  writebufdata(fcommand, sizeof(byte));
  writestrdata(exit_groupid); // 群组中的人员列表

  writestrdata(exit_members); // 群组中的人员列表
  writestrdata(exit_id); // 退出的人员id
  datalen := sizeof(byte) * 2 + sizeof(byte) * 2 + length(exit_groupid) + sizeof(byte) * 2 + length(exit_members) + sizeof(byte) * 2 + length(exit_id);

  // 写数据长度
  protocolby := fill_head(sizeof(byte) * datalen);
  writebufdata(protocolby[0], 4, true);

  bs := rawtobytes(fdata[0], flen);

end;

//{ tprotocol_14 }
//
//constructor tprotocol_14.create;
//begin
//  inherited;
//  fcommand := $15;
//end;
//
//procedure tprotocol_14.prepare;
//var
//  datalen: integer;
//  l: word;
//begin
//  inherited;
//
//  writebufdata(fcommand, sizeof(byte));
//
//  writestrdata(touser);
//  writestrdata(roomid);
//
//  datalen := sizeof(byte) * 2 + sizeof(byte) * 2 + length(touser) + sizeof(byte) * 2 + length(roomid);
//
//  // 写数据长度
//  protocolby := fill_head(sizeof(byte) * datalen);
//  writebufdata(protocolby[0], 4, true);
//
//  bs := rawtobytes(fdata[0], flen);
//
//end;

end.

