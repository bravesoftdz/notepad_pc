unit frm_login;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,System.Messaging,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.WinXCtrls,qjson,VarCoreUnit,global,utils,
  Vcl.Imaging.pngimage, Vcl.ExtCtrls, ImgPanel;

type
  Tlogin_fm = class(TForm)
    ImgPanel4: TImgPanel;
    edt_nick: TSearchBox;
    edt_pwd: TSearchBox;
    ImgPanel1: TImgPanel;
    procedure ImgPanel4Click(Sender: TObject);
    procedure FormMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure ImgPanel1Click(Sender: TObject);
  private
    { Private declarations }
  public
   procedure get_succ_state_login(sender: tobject; json_value: string; thread_index: integer; params: array of string);
   procedure get_fail_state_login(sender: tobject; json_value: string; thread_index: integer);
  end;

var
  login_fm: Tlogin_fm;

implementation

{$R *.dfm}

procedure Tlogin_fm.get_succ_state_login(sender: tobject; json_value: string; thread_index: integer; params: array of string);
type
  lgresult = record
    code: integer;
    msg: string;
    data:  record token:string; end;
//    array[0..0] of
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
//    '{"code":0,"msg":"ok","data":{"token":"7a3c5bebe73d3881954b3ba803c09ed8"}}'
    // 返回个人信息 加载
    json.torecord<lgresult>(bb);

    if bb.code = -1 then
    begin
      Canvas.TextOut(width div 4 + 30, height div 4, '账号存在');
      Exit;
    end;

      g_global.imp.db.kv.setstring('token', bb.data.token);
    Canvas.TextOut(width div 4 + 30, height div 4, '登录成功');

    var Message: TMessage;


    ttx.msg_type := 'login';
    ttx.msg_value := 'ok';
    Message := TMessage<tmsg_obj>.Create(ttx);
    message_bus.SendMessage(nil, Message, true);

  finally
    if json <> nil then
      freeandnil(json);
  end;
  login_fm.Hide;
  FreeAndNil(login_fm);


//  close;
end;

procedure Tlogin_fm.FormMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  releasecapture;
  SendMessage(handle, wm_syscommand, $F011, 0);
end;

procedure Tlogin_fm.get_fail_state_login(sender: tobject; json_value: string; thread_index: integer);
begin
  Canvas.TextOut(width div 4 + 30, height div 4, '登录失败')
end;


procedure Tlogin_fm.ImgPanel1Click(Sender: TObject);
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
 g_global.imp.db.kv.delky('token') ;
  json := tqjson.create;
  vS := TStringStream.create('', TEncoding.UTF8);
  try

    logn_.user_id := trim(edt_nick.Text);
    logn_.pwd := trim(edt_pwd.Text);
    logn_.ver := 1;
    json.FromRecord(logn_);

    vS.WriteString(json.AsJson);
    vS.Position := 0;
    g_global.imp.http_pools.execute_post('api_user_login_go_app', vS, get_succ_state_login, get_fail_state_login, []);
  finally

    if json <> nil then
      freeandnil(json);
  end;
end;

procedure Tlogin_fm.ImgPanel4Click(Sender: TObject);
begin
close
end;

end.
