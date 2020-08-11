unit frm_reg;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  System.Messaging, utils, Vcl.StdCtrls, Vcl.WinXCtrls, qjson, VarCoreUnit,
  Vcl.ExtCtrls, heads_list, ImgPanel, Vcl.Imaging.pngimage;

type
  Treg_fm = class(TForm)
    edt_nick: TSearchBox;
    edt_pwd: TSearchBox;
    ImgPanel1: TImgPanel;
    ImgPanel4: TImgPanel;
    Label1: TLabel;
    procedure ImgPanel1Click(Sender: TObject);
    procedure FormMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure ImgPanel4Click(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    procedure get_succ_state_login(sender: tobject; json_value: string; thread_index: integer; params: array of string);
    procedure get_fail_state_login(sender: tobject; json_value: string; thread_index: integer);
  public
    { Public declarations }
  end;

var
  reg_fm: Treg_fm;

implementation

{$R *.dfm}
procedure Treg_fm.get_succ_state_login(sender: tobject; json_value: string; thread_index: integer; params: array of string);
type
  lgresult = record
    code: integer;
    msg: string;
    data: array[0..0] of string;
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
    json.torecord<lgresult>(bb);

    if bb.code = -1 then
    begin

      Label1.Caption:='ÕËºÅ´æÔÚ';
      Exit;
    end;

    g_global.imp.db.kv.setstring('token', bb.data[0]);
    Label1.Caption:='×¢²á³É¹¦';
    var Message: TMessage;


    ttx.msg_type := 'register';
    ttx.msg_value := 'ok';
    Message := TMessage<tmsg_obj>.Create(ttx);
    message_bus.SendMessage(nil, Message, true);

  finally
    if json <> nil then
      freeandnil(json);
  end;
  close;
end;

procedure Treg_fm.FormMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  releasecapture;
  SendMessage(handle, wm_syscommand, $F011, 0);
end;

procedure Treg_fm.FormShow(Sender: TObject);
begin
Label1.Caption:='';
edt_pwd.Text:='';
edt_nick.Text:='';
end;

procedure Treg_fm.get_fail_state_login(sender: tobject; json_value: string; thread_index: integer);
begin
  Label1.Caption:='×¢²áÊ§°Ü';
end;

procedure Treg_fm.ImgPanel1Click(Sender: TObject);
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
if (trim(edt_nick.Text)='') or (trim(edt_pwd.Text)='') then    Exit;

  json := tqjson.create;
  vS := TStringStream.create('', TEncoding.UTF8);
  try

    logn_.user_id := trim(edt_nick.Text);
    logn_.pwd := trim(edt_pwd.Text);
    logn_.ver := 1;
    json.FromRecord(logn_);

    vS.WriteString(json.AsJson);
    vS.Position := 0;
    g_global.imp.http_pools.execute_post('api_user_reg', vS, get_succ_state_login, get_fail_state_login, []);
  finally

    if json <> nil then
      freeandnil(json);
  end;

end;

procedure Treg_fm.ImgPanel4Click(Sender: TObject);
begin
close
end;

end.

