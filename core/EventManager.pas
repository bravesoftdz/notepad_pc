unit EventManager;

interface

uses Winapi.Windows, forms,
  System.SysUtils, Messages, Graphics, SyncObjs, Classes, u_debug, uEvent;

type

  PEventListenData = ^TEventListenData;

  TEventListenData = packed record
    EventID: integer;
    ParName: string[100];
    Event: TOnInternalEvent;
  end;

  // 执行监听的线程
  TJobThread = class(TThread)
  private
    FCanTerminated: boolean;
    FEvent: TCallPro;
    FBeforTerminate: TNotifyEvent;
    procedure PExecute();
    procedure SetCanTerminated(const Value: boolean);
    procedure SetBeforTerminate(const Value: TNotifyEvent);
  public
    property CanTerminated: boolean read FCanTerminated write SetCanTerminated;
    property BeforTerminate: TNotifyEvent read FBeforTerminate write SetBeforTerminate;

    procedure Execute(); override;
  public
    constructor Create(); overload;
  end;

  TdispatchEventThread = class(TThread)
  private
    FParam1, FParam2: integer;
    FUUID: string;
    FEventID: integer;
    FEvent: TOnInternalEvent;
    procedure PExecute();
  protected
    procedure Execute(); override;
  public
    constructor Create(AEventID: integer; UUID: string; AParam1, AParam2: integer; AEvent: TOnInternalEvent); overload;
  end;

  tevent_manager = class
  private
    gLock: TCriticalSection;
    FEventListen: TList;
    procedure ClearListen;
  public
    constructor Create();
    destructor Destroy(); override;
    // 事件 监听
    procedure addListener(AParentName: string; AEventID: integer; AEvent: TOnInternalEvent);
    procedure removeListener(AParentName: string; AEvent: TOnInternalEvent);
    procedure dispatchEvent(AEventID: integer; UUID: string; AParam1, AParam2: integer);
  end;

var
  JobThread: TJobThread;

implementation

{ tevent_manager }
uses VarCoreUnit, global;

procedure tevent_manager.removeListener(AParentName: string; AEvent: TOnInternalEvent);
var
  i: integer;
  P: PEventListenData;
begin
  i := 0;
  // gLock.Enter;
  while i < FEventListen.Count do
  begin
    P := FEventListen[i];
    if P.ParName = AParentName then
      if @P.Event = @AEvent then
      begin
//        Debug.Show('移除监听:--------------->' + AParentName);
        FreeMem(P);
        FEventListen.Delete(i);
        continue;
      end;
    Inc(i);

  end;
  // gLock.Leave;
end;

procedure tevent_manager.addListener(AParentName: string; AEventID: integer; AEvent: TOnInternalEvent);
var
  P: PEventListenData;

  function InList(iParentName: string; iEventID: integer): boolean;
  var
    i: integer;
  begin
    Result := false;
    for i := 0 to FEventListen.Count - 1 do
    begin
      P := FEventListen[i];

      Result := (P.EventID = iEventID) and (P.ParName = iParentName);
      if Result then
        break;
    end;
  end;

begin

  if InList(AParentName, AEventID) then
  begin
    Debug.Show('Already in addListener :' + AParentName);
    exit;
  end;
//  Debug.Show('加入监听:------------->' + AParentName);
  GetMem(P, SizeOf(TEventListenData));
  P.EventID := AEventID;
  P.Event := AEvent;
  P.ParName := AParentName;
  // gLock.Enter;
  FEventListen.Add(P);
  // gLock.Leave;

end;

constructor tevent_manager.Create;
begin
  inherited;
  FEventListen := TList.Create;
  gLock := TCriticalSection.Create;
end;

destructor tevent_manager.Destroy;
begin
  gLock.Free;
  ClearListen;
  inherited;
end;

procedure tevent_manager.ClearListen;
var
  i: integer;
begin
  // for i := 0 to FListen.Count - 1 do
  // FreeMem(FListen[i]);
  // FListen.Clear;
  for i := 0 to FEventListen.Count - 1 do
    FreeMem(FEventListen[i]);
  FEventListen.Clear;
  // for i := 0 to FTcpListen.Count - 1 do
  // FreeMem(FTcpListen[i]);
  // FTcpListen.Clear;

end;

procedure tevent_manager.dispatchEvent(AEventID: integer; UUID: string; AParam1, AParam2: integer);
var
  i: integer;
  P: PEventListenData;
begin

  // gLock.Enter;
  for i := 0 to FEventListen.Count - 1 do
  begin

    P := FEventListen[i];

    if P.EventID = AEventID then
    begin
//      Debug.Show('执行------------->' + P.ParName);
      TdispatchEventThread.Create(P.EventID, UUID, AParam1, AParam2, P.Event).Start;

    end;
  end;
  // gLock.Leave;
end;

{ TdispatchEventThread }

constructor TdispatchEventThread.Create(AEventID: integer; UUID: string; AParam1, AParam2: integer; AEvent: TOnInternalEvent);
begin
  inherited Create(true);
  FEventID := AEventID;
  FUUID := UUID;
  FParam1 := AParam1;
  FParam2 := AParam2;
  FEvent := AEvent;
  FreeOnTerminate := true;
end;

procedure TdispatchEventThread.Execute;
begin
  inherited;
  Synchronize(PExecute);

end;

procedure TdispatchEventThread.PExecute;
begin
  if Assigned(FEvent) then
    FEvent(FEventID, FUUID, FParam1, FParam2);
end;

/// //////////////////////////////////////////////////////////////////
constructor TJobThread.Create();
begin
  inherited Create(true);
  FreeOnTerminate := true;
end;

procedure TJobThread.Execute;
begin
  inherited;
  while (not CanTerminated and not Terminated) do
  begin
    if Application = nil then
      break;
    if Application.Terminated then
      exit;
    if (g_global.g_communication = nil) then
      continue;
    if g_global.g_communication.send_event_filo.Count > 0 then
    begin
      g_global.imp.g_pulldata_lock.Enter;
      try
        FEvent := g_global.g_communication.send_event_filo.Dequeue();
      finally
        g_global.imp.g_pulldata_lock.Leave;
      end;
      try
        Synchronize(PExecute);
//                (PExecute);
      except

      end;
    end
    else
    begin
      if (g_global.g_communication.send_event_filo.Count = 0) then
        self.Suspended := true;
    end;
//    Debug.Show('----------------************----');
    Sleep(1);

    Application.ProcessMessages;

  end;
end;

procedure TJobThread.PExecute;
begin

  if Assigned(FEvent) then
    FEvent();

end;

procedure TJobThread.SetBeforTerminate(const Value: TNotifyEvent);
begin
  FBeforTerminate := Value;
end;

procedure TJobThread.SetCanTerminated(const Value: boolean);
begin
  FCanTerminated := Value;
end;


end.
