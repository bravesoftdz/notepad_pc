unit httpPools;

interface

uses Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes,
  Vcl.Graphics, System.Generics.Collections, Vcl.Controls, Vcl.Forms,
  Vcl.Dialogs,
//  u_Debug,
  System.Net.HttpClientComponent, System.Net.httpclient,
  SyncObjs, uEvent, qjson;

type
  thttp_thread = class(tthread)
  private

    response: ihttpresponse;
    fsuc: TNotifySucc;
    ffail: TNotifyFail;
  public
    procedure Execute; override;
  public
    url: string;
    constructor Create();
    destructor Destroy; override;
    function GetSuc: TNotifySucc;
    procedure SetSuc(v: TNotifySucc);
    function Getfail: TNotifyFail;
    procedure Setfail(v: TNotifyFail);
    property onSuc: TNotifySucc read GetSuc write SetSuc;
    property onFail: TNotifyFail read Getfail write Setfail;
  end;

  tthttps_mgr = record
  private
  var
    http_pools_fifo: TQueue<tnethttpclient>;
    lock: TCriticalSection;
  public
    procedure init;
    procedure dis;
    function pop: tnethttpclient;
    procedure push(v: tnethttpclient);

  end;

  Thttp_pools = record
  public
    pools: tthttps_mgr;
    function CreateThread(): tthread;

    function execute_get(data_utf8: string; succ: TNotifySucc; fail: TNotifyFail): THandle;
    function execute_post(data_utf8: string; paramStream: TStringStream; succ: TNotifySucc; fail: TNotifyFail;params:array   of string): THandle;
  public
    procedure init;
    procedure http_pools_dispose;
  end;

implementation

uses global, VarCoreUnit;

constructor thttp_thread.Create();
begin
  inherited Create(false);
  FreeOnTerminate := True;
end;

destructor thttp_thread.Destroy;
begin

  fsuc := nil;
  ffail := nil;
  inherited;
end;

procedure thttp_thread.Execute;
var
  value: string;
  hp: tnethttpclient;
begin
  try

    hp := g_global.imp.http_pools.pools.pop;
    response := hp.get(url);
    g_global.imp.http_pools.pools.push(hp);
    value := response.contentasstring();
    if (value.Trim = '') and Assigned(ffail) then
      ffail(nil, '-1', 0)
    else
    begin
      if Assigned(fsuc) then
        fsuc(nil, value, 0,[]);
    end;
    fsuc := nil;
    ffail := nil;

  except
    if hp <> nil then
      g_global.imp.http_pools.pools.push(hp);

    if Assigned(ffail) then
      ffail(nil, '-1', 0);
    fsuc := nil;
    ffail := nil;
  end;

end;

function thttp_thread.Getfail: TNotifyFail;
begin
  result := ffail;
end;

function thttp_thread.GetSuc: TNotifySucc;
begin
  result := fsuc;
end;

procedure thttp_thread.Setfail(v: TNotifyFail);
begin
  ffail := v;
end;

procedure thttp_thread.SetSuc(v: TNotifySucc);
begin
  fsuc := v;
end;

{ Thttp_pools }

function Thttp_pools.CreateThread: tthread;
begin
  result := thttp_thread.Create();
end;

procedure Thttp_pools.http_pools_dispose;
begin
  pools.dis;
end;

//
function Thttp_pools.execute_get(data_utf8: string; succ: TNotifySucc; fail: TNotifyFail): THandle;
var
  pp: thttp_thread;
  url: string;
  value: string;
  hp: tnethttpclient;
begin // 'http://192.168.20.139:9011/api_qrcode'
  url := g_global.imp.cloud.api_host + '/' + data_utf8;
//  Debug.Show(url);
  try
//    var
//    t1 := GetTickCount;
    hp := g_global.imp.http_pools.pools.pop;
    var
    response := hp.get(url);
    g_global.imp.http_pools.pools.push(hp);
    value := response.contentasstring();
//    var
//    t2 := GetTickCount;
//    var
//    gg := (t2 - t1);
    /// 1000;
//    Debug.Show(gg.ToString + '√Î');
    if (value.Trim = '') and Assigned(fail) then
      fail(nil, '-1', 0)
    else
    begin
      if Assigned(succ) then
        succ(nil, value, 0,[]);
    end;

  except
    if hp <> nil then
      g_global.imp.http_pools.pools.push(hp);

    if Assigned(fail) then
      fail(nil, '-1', 0);
  end;

end;

procedure Thttp_pools.init;
begin
  pools.init;
end;

function Thttp_pools.execute_post(data_utf8: string; paramStream: TStringStream; succ: TNotifySucc; fail: TNotifyFail;params:array   of string): THandle;
var
  url: string;
var
  value: string;
  hp: tnethttpclient;

begin
  url := g_global.imp.cloud.api_host + '/' + data_utf8;
//  Debug.Show(url);
  try
    hp := g_global.imp.http_pools.pools.pop;
//    if hp = nil then
//      Debug.Show('error hp=nil');

    value := hp.Post(url, paramStream).contentasstring(tencoding.UTF8);

    g_global.imp.http_pools.pools.push(hp);
    if paramStream <> nil then
      FreeAndNil(paramStream);
    if (value.Trim = '') and Assigned(fail) then
      fail(nil, '-1', 0)
    else   if (value.Trim <> '') and Assigned(succ) then
    begin

        succ(nil, value, 0,params);
    end;

  except

    if Assigned(hp) then
    begin
      g_global.imp.http_pools.pools.push(hp);
    end;
    if paramStream <> nil then
      FreeAndNil(paramStream);

    if Assigned(fail) then
      fail(nil, '-1', 0);

  end;

end;

{ tthttps_mgr }

procedure tthttps_mgr.dis;
var
  i: Integer;
  s: thttp_thread;
begin

  lock.Free;

  for i := 0 to http_pools_fifo.Count - 1 do
    tnethttpclient(http_pools_fifo.Dequeue).Free;

  http_pools_fifo.Clear;
  FreeAndNil(http_pools_fifo);
end;

procedure tthttps_mgr.init;
begin
  http_pools_fifo := TQueue<tnethttpclient>.Create;
  lock := TCriticalSection.Create;
end;

function tthttps_mgr.pop: tnethttpclient;
begin
  result := nil;
  if (http_pools_fifo <> nil) and (http_pools_fifo.Count > 0) then
  begin
    lock.Enter;
    try
   if http_pools_fifo.Count>0 then
      result := http_pools_fifo.Dequeue else
      result:=tnethttpclient.Create(nil);

    finally
      lock.Leave;
    end;
  end;

  if result = nil then
  begin
    result := tnethttpclient.Create(nil);
    with result do
    begin
      ConnectionTimeout := 2000; // 2√Î
      ResponseTimeout := 10000; // 10√Î
      AcceptCharSet := 'UTF-8';
      // 'Content-Type': 'application/json', 'charset': 'UTF-8', 'Connection': 'close
      ContentType := 'application/json';
      UserAgent := 'Embarcadero URI Client/1.0';
    end;
  end;

end;

procedure tthttps_mgr.push(v: tnethttpclient);
begin
  lock.Enter;
  try
    http_pools_fifo.Enqueue(v);
  finally
    lock.Leave;
  end;
end;

end.
