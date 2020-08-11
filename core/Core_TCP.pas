unit Core_TCP;

interface

uses
  Windows, Sysutils, Classes, SyncObjs, ActiveX, IdBaseComponent,
  Generics.Collections, Winapi.Messages, Forms, System.IniFiles, IdTCPConnection,
  IdTCPClient, Contnrs, global, IdComponent, qjson, u_debug, IdGlobal,
  protocol_bas;

type
  TTCPClient = class;

  TTCPRecvThread = class(TThread)
  private
    FInLoop: boolean;
    FClient: TTCPClient;
  protected
    procedure Execute; override;
  public
    constructor Create(CreateSuspended: boolean);
    property Client: TTCPClient read FClient;
  end;

  Tdata_handler_Thread = class(TThread)
  private
    pp: tpush_pack;
  protected
    procedure Execute; override;
  public
    constructor Create(CreateSuspended: boolean);
    destructor Destroy; override;
  end;

  TTCPClient = class(TObject)
  private
    TCP: TIdTCPClient;
    FConnected: boolean;
    FRecvThread: TTCPRecvThread;
    data_handler_Thread: Tdata_handler_Thread;
    FOnDisconnect: TNotifyEvent;
    procedure SetConnected(const Value: boolean);
    procedure state(ASender: TObject; const AStatus: TIdStatus; const AStatusText: string);
    procedure tcpConnnected(Sender: TObject);
    procedure heart;
    procedure check_tcp_net;
  public
    FWindowHandle: HWND;
    FInterval: Cardinal;
    procedure UpdateTimer;
    procedure WndProc(var Msg: TMessage);
    procedure Timer;
  public
    constructor Create;
    destructor Destroy; override;
    function Connect(ATimeOut: Integer = 5000): boolean;
    procedure Disconnect;
    procedure SendData(bs: TIdBytes);
    procedure check_net_startHeart();
    property Connected: boolean read FConnected write SetConnected;
    property OnDisconnect: TNotifyEvent read FOnDisconnect write FOnDisconnect;
  end;

implementation

{ TTCPClient }
uses
  VarCoreUnit, core;

procedure TTCPClient.heart;
var
  Heartbeat: THeartbeat;
begin

  if g_global.g_communication.logined then
  begin
    Heartbeat := THeartbeat.Create;
    Heartbeat.prepare;
    try
      if (TCP <> nil) and TCP.Connected then
        Heartbeat.send_package;
    finally
      Heartbeat.Free;
    end;
  end;
end;

procedure TTCPClient.UpdateTimer;
begin
  KillTimer(FWindowHandle, 1);
  KillTimer(FWindowHandle, 2);
  Windows.SetTimer(FWindowHandle, 1, FInterval, nil);
  Windows.SetTimer(FWindowHandle, 2, 20 * 1000, nil)
end;

procedure TTCPClient.check_tcp_net;
begin

end;

procedure TTCPClient.Timer;
begin
  heart;
end;

procedure TTCPClient.WndProc(var Msg: TMessage);
begin
  if Msg.Msg = WM_TIMER then
  begin
    case Msg.WParam of
      1:

        try
          Timer;
        except
          Application.HandleException(Self);
        end;
      2:
        check_tcp_net;
    end;
  end
  else if Msg.Msg = WM_QUERYENDSESSION then
    Msg.Result := 1
  else
    Msg.Result := DefWindowProc(FWindowHandle, Msg.Msg, Msg.WParam, Msg.lParam);

end;

function TTCPClient.Connect(ATimeOut: Integer): boolean;
begin
  Result := false;
  FConnected := false;
  if TCP.Connected then
  begin
    if FRecvThread = nil then
    begin
      FRecvThread := TTCPRecvThread.Create(True);
      FRecvThread.FClient := Self;
      FRecvThread.Start();
    end;
    if data_handler_Thread = nil then
    begin
      data_handler_Thread := Tdata_handler_Thread.Create(True);
      data_handler_Thread.Start();
    end;

    Result := True;
    FConnected := True;
    exit;
  end;

  TCP.Host := tcp_host;
  TCP.Port := tcp_port;

  TCP.ConnectTimeout := ATimeOut;
  try
    TCP.Connect;

    FConnected := TCP.Connected;

    if FConnected then
    begin
      if FRecvThread = nil then
      begin
        FRecvThread := TTCPRecvThread.Create(True);
        FRecvThread.FClient := Self;
        FRecvThread.Start();
      end;

      if data_handler_Thread = nil then
      begin
        data_handler_Thread := Tdata_handler_Thread.Create(True);
        data_handler_Thread.Start();
      end;

      Result := True;
    end;
  except
    if FRecvThread <> nil then
    begin
      FRecvThread.Terminate();
      WaitForSingleObject(FRecvThread.Handle, INFINITE);
      FreeAndNil(FRecvThread);
    end;

    if data_handler_Thread <> nil then
    begin
      data_handler_Thread.Terminate();
      WaitForSingleObject(data_handler_Thread.Handle, INFINITE);
      FreeAndNil(data_handler_Thread);
    end;

    Result := false;
  end;
end;

procedure TTCPClient.state(ASender: TObject; const AStatus: TIdStatus; const AStatusText: string);
begin

end;

procedure TTCPClient.tcpConnnected(Sender: TObject);
begin
  FConnected := True;
end;

constructor TTCPClient.Create;
begin
  inherited;

  FWindowHandle := Classes.AllocateHWnd(WndProc);
  FInterval := 60 * 1000;

  FConnected := false;
  if TCP = nil then
    TCP := TIdTCPClient.Create;

  TCP.OnStatus := state;

  TCP.OnConnected := tcpConnnected;

end;

destructor TTCPClient.Destroy;
begin
  KillTimer(FWindowHandle, 1);
  KillTimer(FWindowHandle, 2);
  Classes.DeallocateHWnd(FWindowHandle);
  try
    if TCP <> nil then
    begin
      Disconnect();
      FreeAndNil(TCP);
    end;
    if FRecvThread <> nil then
    begin
      FRecvThread.Terminate();
      WaitForSingleObject(FRecvThread.Handle, INFINITE);
      FRecvThread := nil;
    end;

    if data_handler_Thread <> nil then
    begin
      data_handler_Thread.Terminate();
      WaitForSingleObject(data_handler_Thread.Handle, INFINITE);
      data_handler_Thread := nil;
    end;

  except

  end;
end;

procedure TTCPClient.Disconnect;
begin
  try
    FConnected := false;
    if (TCP <> nil) and TCP.Connected then
      TCP.Disconnect;

    if FRecvThread <> nil then
    begin
      FRecvThread.Terminate();
      FRecvThread := nil;

    end;
  except

  end;
end;

procedure TTCPClient.SendData(bs: TIdBytes);
begin
  if TCP.Connected then
    TCP.IOHandler.write(bs);

end;

procedure TTCPClient.check_net_startHeart();
begin
  UpdateTimer;
end;

procedure TTCPClient.SetConnected(const Value: boolean);
begin
  if Value then
    Connect()
  else
    Disconnect();

end;

{ TTCPRecvThread }

constructor TTCPRecvThread.Create(CreateSuspended: boolean);
begin
  inherited Create(CreateSuspended);
  FClient := nil;
  FInLoop := false;
end;

procedure TTCPRecvThread.Execute;
var
  bye: byte;
  p2_code: TArray<byte>;
  PushData: tpush_pack;
  json: TQJson;
  tmp: string;
  sm: tstringstream;

  function HexToInt(str: ansistring): word;
  var
    i, Value: word;
    pos: word;
  begin
    Result := 0;
    Value := 0;
    pos := length(str);
    for i := 1 to pos do
    begin
      case str[i] of
        'f', 'F':
          Value := Value * 16 + 15;
        'e', 'E':
          Value := Value * 16 + 14;
        'd', 'D':
          Value := Value * 16 + 13;
        'c', 'C':
          Value := Value * 16 + 12;
        'b', 'B':
          Value := Value * 16 + 11;
        'a', 'A':
          Value := Value * 16 + 10;
        '0'..'9':
          Value := Value * 16 + ord(str[i]) - ord('0');
      else
        Result := Value;
        exit;
      end;
      Result := Value;
    end;

  end;

  function Pack2byteData(): TArray<byte>;
  begin
    SetLength(Result, 2);
    Result[0] := 0;
    Result[1] := 0;
    sm.ReadBuffer(Result, 2);
  end;

  function Pack2byteLen(): DWORD;
  var
    pp: array[0..1] of byte;
  begin
    pp[0] := 0;
    pp[1] := 0;
    sm.ReadBuffer(pp, 2); // 读取数据同时移动指针
    Result := HexToInt(IntToHex(pp[0], 2) + IntToHex(pp[1], 2));
  end;

  function Pack1byteData(): byte;
  begin
    sm.ReadBuffer(Result, 1);
  end;

  function Pack1byteLen(): DWORD;
  var
    pp: array[0..0] of byte;
  begin
    pp[0] := 0;
    ZeroMemory(@pp[0], 1);
    sm.ReadBuffer(pp, 1);
    Result := HexToInt(IntToHex(pp[0], 2));
  end;

begin

  if json = nil then
    json := TQJson.Create;
  if sm = nil then
    sm := tstringstream.Create;
  try
  try
    while not Terminated do
    begin
      if (FClient.TCP = nil) or ((FClient.TCP <> nil) and (not FClient.TCP.Connected)) then
        Continue;
      if sm = nil then
        sm := tstringstream.Create;
      if FClient.TCP = nil then
        Break;
      if FClient = nil then
        Break;
      if sm = nil then
        Break;
      sm.Clear;
      if not FClient.TCP.IOHandler.Connected then
        Continue;

      FClient.TCP.IOHandler.ReadStream(sm);
      if sm = nil then
        Continue;

      if (sm.Size < 3) then
        Continue;
      if FInLoop then
        Continue;

      sm.Position := 0;
      p2_code := Pack2byteData;
      FInLoop := True;
      if p2_code[0] = 1 then
        case p2_code[1] of
          $1:

                    g_global.imp.event_manager.dispatchEvent(g_global.imp.cconst.event_const.succ_login, '', 0, 0);

          $12: // $12=18对话 消息
            begin
              json.Clear;
              var ssss := sm.ReadString(Pack2byteLen);
              Debug.Show(ssss);
              json.Parse(g_global.imp.cloud.decode(ssss));
              json.ToRecord<tpush_pack>(PushData);
              g_global.imp.g_pulldata_lock.Enter;
              g_global.imp.g_pulldata.Enqueue(PushData);
              g_global.imp.g_pulldata_lock.Leave;
            end;

          $0C: // room 消息
            begin
              json.Clear;
              var ss := sm.ReadString(Pack2byteLen);
              var bb := g_global.imp.cloud.decode(ss);
              json.Parse(bb);

              json.ToRecord<tpush_pack>(PushData);
             // if PushData.fromid <> g_global.imp.mLoginUser.user_id then
              begin
                g_global.imp.g_pulldata_lock.Enter;
                g_global.imp.g_pulldata.Enqueue(PushData);
                g_global.imp.g_pulldata_lock.Leave;

              end;

            end;
          $9: // $9 room创建
            begin
              json.Clear;
              json.Parse(g_global.imp.cloud.decode(sm.ReadString(Pack2byteLen)));
              json.ToRecord<tpush_pack>(PushData);
              g_global.imp.g_pulldata_lock.Enter;
              g_global.imp.g_pulldata.Enqueue(PushData);
              g_global.imp.g_pulldata_lock.Leave;
            end;
          $13: // room解散消息
            begin
              var dis_groupid := sm.ReadString(Pack2byteLen);

              g_global.imp.event_manager.dispatchEvent(g_global.imp.cconst.event_const.dis_group, dis_groupid, Integer(PChar(dis_groupid)), 0);
            end;

          $14: // 退出群组消息
            begin
              Debug.Show('退出群组消息-==========================-------------');
              var exit_groupid := sm.ReadString(Pack2byteLen);
              var exit_id := sm.ReadString(Pack2byteLen);

              g_global.imp.event_manager.dispatchEvent(g_global.imp.cconst.event_const.exit_room, '', Integer(PChar(exit_groupid)), Integer(PChar(exit_id)));
              Debug.Show('收到退出消息 ' + exit_id + '   ' + exit_groupid);
            end;

          5:
            begin

            end;
          10: // 其他用户下线
            begin

            end;
          253:
            begin
              var groupid := sm.ReadString(Pack2byteLen);

              var kkk := g_global.imp.rawdata.rooms_list.Items[groupid]; //.is_enable:=1;
              kkk.is_enable := -1;
              g_global.imp.rawdata.rooms_list.AddOrSetValue(groupid, kkk);
              Debug.Show('房间已经解散  ' + groupid);

            end;
          $FE: // 错误汇总
            begin
              bye := Pack1byteData;
              if bye = 1 then
              begin
                // 请检查账号与密码
                FClient.TCP.Disconnect;
                g_global.imp.login_state.tcp_connected := false;
                g_global.imp.login_state.logined := false;
                g_global.imp.event_manager.dispatchEvent(g_global.imp.cconst.event_const.loginError, '', g_global.imp.cconst.ERRORCODE_NOACCOUNT, 0);

              end
              else if bye = 2 then
              begin

                g_global.imp.event_manager.dispatchEvent(g_global.imp.cconst.event_const.loginTimeOut, '', 0, 0);

              end
              else if bye = 5 then
              begin
                // 其他地方登录 账号  强制离线消息
                FClient.TCP.Disconnect;
                g_global.imp.login_state.tcp_connected := false;
                g_global.imp.login_state.logined := false;
                g_global.imp.event_manager.dispatchEvent(g_global.imp.cconst.event_const.forceOffline, '', 0, 0);

              end;
            end;
        end;

      FInLoop := false;
    end;
    except

    end;
  finally
    g_global.g_communication.logined := false;

    g_global.imp.login_state.tcp_connected := false;
    g_global.imp.login_state.logined := false;

    if sm <> nil then
      FreeAndNil(sm);
    if json <> nil then
      FreeAndNil(json);

    // if (not g_global.im.g_close) then
    g_global.g_communication.on_tcp_disconnect;

    if FClient <> nil then
      FClient.FConnected := false;
  end;
end;

{ Tdata_handler_Thread }

constructor Tdata_handler_Thread.Create(CreateSuspended: boolean);
begin
  inherited Create(CreateSuspended);
end;

destructor Tdata_handler_Thread.Destroy;
begin
  inherited;
end;

var
  g_pp: tpush_pack;

procedure protocol_handle();
var
  json_data: tpush_pack;
begin


end;

procedure Tdata_handler_Thread.Execute;
begin
  while not Terminated do
  begin
    if g_global.imp.g_pulldata = nil then
      Continue;

    if g_global.imp.g_pulldata.Count > 0 then
    begin
      g_global.imp.g_pulldata_lock.Enter;
      g_pp := g_global.imp.g_pulldata.Dequeue;
      g_global.imp.g_pulldata_lock.Leave;
      Synchronize(protocol_handle);
    end;
    Sleep(1);
  end;

end;

end.

