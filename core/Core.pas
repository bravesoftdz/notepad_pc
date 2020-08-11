unit Core;

interface

uses
  windows, sysutils, classes, variants, activex, vcl.graphics, messages,
  vcl.forms, xmldoc, xmlintf, contnrs, syncobjs, shellapi, registry, math,
  dateutils,  core_tcp, idglobal, qjson, u_debug, generics.collections,
  httpapp, global, uEvent, System.Notification, System.Net.HttpClient, db_helper,
  protocol_bas;

const
  wm_forceoffline = wm_user + 101;
  wm_maincmddisconnect = wm_user + 102;

const
  timerid_loginstatusautochange = 1;

type
  tcommunication = class;

  tsession_manager = class;

  // 接收数据处理
  TBaseReceivePackage = class
  private
    json: tqjson;
    fclient: tcommunication;
  public
    procedure dispose_receive(data: string);
    procedure group_dispose_receive(data: string);
    constructor create(client: tcommunication);
    destructor destroy; override;
  end;

{$ENDREGION}

  tsession_manager = class(tcomponent)
  private
    fclient: tcommunication;
  private
    procedure group_msg_send(room_id, content: string);
    procedure msg_send(to_user_id, msgid, content: string);
    procedure callback_group_post_result(sender: tobject; json_value: string; thread_index: integer; params: array of string);
  public
    // 群组消息
    procedure ready_send_group_message(agroupid: string; group_name: string; acontent: string);
    // 群组文件
    procedure ready_send_groupmessage_type_file(agroupid: string; file_path: string; file_type: string);
  public
    // 个人消息
    procedure ready_send_message(toid: string; uuid: string; acontent: string);
    // 文件类型
    procedure ready_send_type_file(toid: string; uuid: string; img_path: string; type_file: string);
  end;

{$ENDREGION}

  tcommunication = class(tcomponent)
  public
    send_event_filo: TQueue<TCallPro>;
    tcp_login: Boolean;
  private
    hw: thandle;
    tcp: ttcpclient;
    fisloging: Boolean;
    flogined: Boolean;
    procedure wndproc(var msg: tmessage);
    procedure get_fail_state_login(sender: tobject; json_value: string; thread_index: integer);
    procedure get_succ_state_login(sender: tobject; json_value: string; thread_index: integer; params: array of string);
  public
    s_m: tsession_manager;
    bp: TBaseReceivePackage;
    procedure on_tcp_disconnect;
    procedure tcp_reday_login;
  public
    procedure send_tcp_data(bs: tidbytes);
  public
    constructor create(aowner: tcomponent); override;
    destructor destroy; override;
    procedure login;
    procedure logout;
    property logined: Boolean read flogined write flogined;
    property isloging: Boolean read fisloging;
  public
  end;

implementation

uses
  varcoreunit;

var
  NotificationCenter1: TNotificationCenter;

constructor tcommunication.create(aowner: tcomponent);
begin
  NotificationCenter1 := TNotificationCenter.Create(nil);
  inherited create(aowner);
  hw := allocatehwnd(wndproc);

  tcp := ttcpclient.create();

  s_m := tsession_manager.create(self);
  s_m.fclient := self;

  bp := TBaseReceivePackage.create(self);
  send_event_filo := TQueue<TCallPro>.create;

end;

destructor tcommunication.destroy;
begin
  freeandnil(NotificationCenter1);
  freeandnil(send_event_filo);
  freeandnil(bp);
  logout();

  freeandnil(s_m);

  freeandnil(tcp);
  deallocatehwnd(hw);

  inherited;
end;

var
  try_count: integer = 0;

procedure tcommunication.get_fail_state_login(sender: tobject; json_value: string; thread_index: integer);
begin
  if try_count = 3 then
    exit;
  Sleep(1000);
  login;
  Inc(try_count);
end;

procedure tcommunication.tcp_reday_login;
begin
  // 连接推送服务器

  tcp.disconnect;
  if not tcp.connected then
  begin
    if not tcp.connect() then
    begin
      fisloging := false;
      g_global.imp.event_manager.dispatchEvent(g_global.imp.cconst.event_const.connectError, '', 0, 0);
      exit;
    end;
  end;

  // 登录推送服务器
  var llg := tprotocol_login.create;
  llg.prepare;
  llg.send_package;
  llg.free;

  // 启动心跳包
  tcp.check_net_startHeart;
  flogined := true;
end;

procedure tcommunication.get_succ_state_login(sender: tobject; json_value: string; thread_index: integer; params: array of string);
type
  lgresult = record
    code: integer;
    msg: string;
    data: array[0..0] of temploye;
  end;

  tjbase = record
    mod_player: record
      mod_player_login_c2s: record
        user_id: string;
        device_type: string;
      end;
    end;
  end;
var
  bb: lgresult;
  json: tqjson;
var
  v1: tqjson;
  bxb: tjbase;
  txt: string;
begin
  json := tqjson.create;
  try
    json.parse(json_value);

    // 返回个人信息 加载
    json.torecord<lgresult>(bb);

    if bb.code <> 0 then
    begin

      // 'Client:OnLoginError',
      g_global.imp.event_manager.dispatchEvent(g_global.imp.cconst.event_const.LoginError, '', g_global.imp.cconst.ERRORCODE_NOACCOUNT, 0);
      exit;
    end;
    g_global.imp.mLoginUser := bb.data[0];
    g_global.g_communication.tcp_login := false;
    tcp_reday_login();
    g_global.g_communication.tcp_login := true;

  finally
    if json <> nil then
      freeandnil(json);
  end;
end;

procedure tcommunication.login;
var
  json: tqjson;
  vS: TStringStream;
type
  tlogn_ = record
    user_id, pwd: string;
    ver: integer;
  end;
var
  logn_: tlogn_;
begin
  json := tqjson.create;
  vS := TStringStream.create('', TEncoding.UTF8);
  try

    logn_.user_id := g_global.imp.mLoginUser.user_id;
    logn_.pwd := g_global.imp.mLoginUser.pwd;
    logn_.ver := 1;
    json.FromRecord(logn_);

    vS.WriteString(json.AsJson);
    vS.Position := 0;
    g_global.imp.http_pools.execute_post('api_user_login', vS, get_succ_state_login, get_fail_state_login, []);
  finally

    if json <> nil then
      freeandnil(json);
  end;

end;

procedure tcommunication.logout;
begin

  if not flogined then
    exit;

  flogined := false;
  fisloging := false;
end;

procedure tcommunication.on_tcp_disconnect;
begin
  // if (not g_global.im.g_close) then
  postmessage(hw, wm_maincmddisconnect, 0, 0);

end;

procedure tcommunication.send_tcp_data(bs: tidbytes);
begin
  try
    tcp.senddata(bs);

  except
  end;
end;

procedure tcommunication.wndproc(var msg: tmessage);
begin

  case msg.msg of
    wm_maincmddisconnect:
      begin
        try
          // 重新登录
          Debug.Show('已经断线.........................');
          g_global.imp.event_manager.dispatchEvent(g_global.imp.cconst.event_const.reUserLogin, '', 0, 0);
        except
          application.handleexception(self);
        end
      end;

  else
    msg.result := defwindowproc(hw, msg.msg, msg.wparam, msg.lparam);

  end;
end;

procedure tsession_manager.ready_send_type_file(toid: string; uuid: string; img_path: string; type_file: string);
var
  retrunV: string;
  json: tqjson;
  new_filename, tmp: string;
begin
  var arr := img_path.Split(['\']);
  new_filename := arr[Length(arr) - 1];
  json := tqjson.create;
  json.AddVariant('senderid', g_global.imp.mLoginUser.user_id);
  json.AddVariant('nick', g_global.imp.mLoginUser.nickname);

  json.AddVariant('msgtype', type_file);
  json.AddVariant('content', g_global.imp.cconst.oss + new_filename);

  json.AddVariant('sendtime', FormatDateTime('yyyy-MM-dd hh:mm', now));
  json.AddVariant('msgid', uuid);

  var jsonv := json.AsJson;
  json.free;
  msg_send(toid, uuid, jsonv);

end;

procedure tsession_manager.msg_send(to_user_id, msgid, content: string);
var
  json: tqjson;
  vS: TStringStream;
type
  tsend_ = record
    user_id: string;
    toid: string;
    msg_detail: string;
    msgid: string;
    ver: integer;
  end;
var
  send_: tsend_;
type
  tjbase = record
    mod_player: record
      mod_player_chat_c2c: record
        fromid: string;
        toid: string;
        pulldata: tpush_pack;
      end;
    end;
  end;
var
  bxb: tjbase;
  v1: tqjson;
  txt: string;
begin
  json := tqjson.create;
  vS := TStringStream.create('', TEncoding.UTF8);
  try
    send_.user_id := g_global.imp.mLoginUser.user_id;
    send_.toid := to_user_id;
    send_.msg_detail := content;
    send_.msgid := msgid;
    send_.ver := 1;

    json.FromRecord(send_);

    vS.WriteString(json.AsJson);
    vS.Position := 0;
    g_global.imp.http_pools.execute_post('api_c2c_save', vS, nil, nil, []);
  finally

    if json <> nil then
      freeandnil(json);
  end;

  TThread.CreateAnonymousThread(
    procedure
    begin
      // tcp推送消息   给对方
      var ll := tprotocol_chat_pull.create;
      ll.fromid := g_global.imp.mLoginUser.user_id;
      ll.toid := to_user_id;
      ll.pulldata.pullcode := $1;

      ll.pulldata.msg_detail := g_global.imp.cloud.encode(content);
      ll.pulldata.fromid := g_global.imp.mLoginUser.user_id;
      try
        ll.prepare;
        ll.send_package;
        ll.free;

      except
        ll.free;

      end;

    end).Start;

end;

procedure tsession_manager.ready_send_message(toid: string; uuid: string; acontent: string);
var
  json: tqjson;
  t: Double;
var
  txt: string;
  yxx: record
    senderid: string;
    nick: string;
    msgtype: string;
    content: string;
    sendtime: string;
    msgid: string;
  end;
  v1: tqjson;
begin
  if not fclient.logined then
    exit;

  yxx.senderid := g_global.imp.mLoginUser.user_id;
  yxx.nick := g_global.imp.mLoginUser.nickname;
  yxx.msgtype := g_global.imp.cconst.type_text;
  yxx.content := acontent;
  yxx.sendtime := FormatDateTime('hh:mm', now);
  yxx.msgid := uuid;

  v1 := tqjson.create;
  v1.FromRecord(yxx);
  txt := v1.AsJson;
  freeandnil(v1);
  msg_send(toid, uuid, txt);

end;

procedure tsession_manager.ready_send_groupmessage_type_file(agroupid: string; file_path: string; file_type: string);
var
  new_filename, tmp: string;
  jsonv: string;
begin
  if file_path = '' then
    exit;

  if not fclient.logined then
    exit;

  var arr := file_path.Split(['\']);
  new_filename := arr[Length(arr) - 1];

  var json := tqjson.create;
  json.AddVariant('room_id', agroupid);
  json.AddVariant('senderid', g_global.imp.mLoginUser.user_id);
  json.AddVariant('nick', g_global.imp.mLoginUser.nickname);

  json.AddVariant('sendtime', FormatDateTime('yyyy-MM-dd hh:mm', now));

  json.AddVariant('content', g_global.imp.cconst.oss + new_filename);
  json.AddVariant('msgtype', file_type);

  jsonv := json.AsJson;
  json.free;
  group_msg_send(agroupid, jsonv);

end;

procedure tsession_manager.callback_group_post_result(sender: tobject; json_value: string; thread_index: integer; params: array of string);
var
  json: tqjson;
  aa: txxjj;
  i: integer;
  groupid: string;
  content: string;
begin
  if json_value = '' then
    exit;
  groupid := params[0];
  content := params[1];
  json := tqjson.create;
  json.parse(json_value);
  try
    json.torecord<txxjj>(aa);
    if aa.code = 0 then
    begin

      TThread.CreateAnonymousThread(
        procedure
        begin
          // tcp推送消息   给群
          var ll := tprotocol_room_pull.create;
          ll.groupid := groupid;
          ll.pulldata.pullcode := 2;
          ll.pulldata.msg_detail := g_global.imp.cloud.encode(content);

          ll.pulldata.fromid := g_global.imp.mLoginUser.user_id;
          ll.prepare;
          ll.send_package;
          ll.free;

        end).Start;

      for i := Low(aa.data) to High(aa.data) do
        g_global.imp.event_manager.dispatchEvent(g_global.imp.cconst.event_const.unread_msg, aa.data[i].fromid, 0, 0);
    end
    else

//      SendMessage(g_global.im.MainFrm_Handle, wm_Non_room_members, 0, 0);
  finally
    json.free;
  end;
end;

procedure tsession_manager.group_msg_send(room_id: string; content: string);
var
  json: tqjson;
  vS: TStringStream;
type
  tsend_ = record
    room_id: string;
    user_id: string;
    msg_detail: string;
    ver: integer;
  end;
var // url := 'c2g_save?groupId=' + groupid + '&content=' + content + '&user_id=' + g_global.imp.mLoginUser.user_id;
  send_: tsend_;
type
  kep = record
    mems: string;
    base_data: tpush_pack;
  end;

  bx = record
    mod_player_room_chat_c2s: kep
  end;

  tjbase = record
    mod_player: bx
  end;
var
  bxb: tjbase;
  v1: tqjson;
  txt: string;
  ttt: tpush_pack;
begin
  json := tqjson.create;
  vS := TStringStream.create('', TEncoding.UTF8);
  try
    send_.room_id := room_id;
    send_.user_id := g_global.imp.mLoginUser.user_id;
    send_.msg_detail := content;
    send_.ver := 1;
    json.FromRecord(send_);

    vS.WriteString(json.AsJson);
    vS.Position := 0;
    g_global.imp.http_pools.execute_post('api_c2g_save', vS, callback_group_post_result, nil, [room_id, content]);
  finally

    if json <> nil then
      freeandnil(json);
  end;

end;

procedure tsession_manager.ready_send_group_message(agroupid: string; group_name: string; acontent: string);
begin
  if not fclient.logined then
    exit;
  var json := tqjson.create;
  json.AddVariant('room_id', agroupid);
  json.AddVariant('room_name', group_name);

  json.AddVariant('senderid', g_global.imp.mLoginUser.user_id);
  json.AddVariant('nick', g_global.imp.mLoginUser.nickname);
  json.AddVariant('msgtype', g_global.imp.cconst.type_text);
  json.AddVariant('content', acontent);

  json.AddVariant('sendtime', FormatDateTime('yyyy-MM-dd hh:mm', now));

  var jsonv := json.AsJson;
  json.free;
  group_msg_send(agroupid, jsonv);

end;

constructor TBaseReceivePackage.create(client: tcommunication);
begin
  fclient := client;
  json := tqjson.create;
end;

destructor TBaseReceivePackage.destroy;
begin
  json.free;
  inherited;
end;

procedure TBaseReceivePackage.dispose_receive(data: string);
begin


end;

procedure TBaseReceivePackage.group_dispose_receive(data: string);
var
  pullunpack: tpull_room_msg_unpack;
begin



end;

end.

