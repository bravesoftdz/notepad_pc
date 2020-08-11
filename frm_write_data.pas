unit frm_write_data;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Messaging, System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms,
  Vcl.Dialogs, utils, VarCoreUnit, global, Vcl.StdCtrls, Vcl.WinXCtrls, qjson,
  Vcl.WinXPickers, Vcl.ExtCtrls, ImgPanel, Vcl.AppEvnts, Vcl.Imaging.pngimage,
  Vcl.ComCtrls;

type
  Tset_frm = class(TForm)
    RadioGroup1: TRadioGroup;
    RadioButton1: TRadioButton;
    RadioButton2: TRadioButton;
    DatePicker1: TDatePicker;
    Memo1: TMemo;
    ImgPanel1: TImgPanel;
    RadioButton3: TRadioButton;
    ImgPanel2: TImgPanel;
    Edit1: TEdit;
    Image2: TImage;
    StatusBar1: TStatusBar;
    procedure RadioButton1Click(Sender: TObject);
    procedure RadioButton2Click(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure ImgPanel1Click(Sender: TObject);
    procedure FormMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure RadioButton3Click(Sender: TObject);
    procedure ImgPanel2MouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure Image2MouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure FormResize(Sender: TObject);
  private
    procedure get_succ_state_login(sender: tobject; json_value: string; thread_index: integer; params: array of string);
    procedure get_fail_state_login(sender: tobject; json_value: string; thread_index: integer);
  public
  end;

var
  set_frm: Tset_frm;

procedure Close_create_set_Form;

procedure open_set_info(msg_id: string);

implementation

{$R *.dfm}
procedure open_set_info(msg_id: string);
var
  vForm: tform;
begin
  if not Assigned(set_frm) then
  begin
    set_frm := Tset_frm.Create(nil);

    set_frm.Show;

  end
  else
    set_frm.Show;
  set_frm.Memo1.Text := '2狗子';
end;

procedure Close_create_set_Form;
begin
  if Assigned(set_frm) then
  begin
    set_frm.Hide();
    freeandnil(set_frm);

  end;
end;

procedure Tset_frm.get_succ_state_login(sender: tobject; json_value: string; thread_index: integer; params: array of string);
type
  lgresult = record
    code: integer;
    msg: string;
    data: array[0..0] of string;
  end;
var
  bb: lgresult;
  json: tqjson;
var
  v1: tqjson;
  txt: string;
begin
  json := tqjson.create;
  try
    json.parse(json_value);

    json.torecord<lgresult>(bb);

    if bb.code = -1 then
    begin
      Canvas.TextOut(width div 4 + 30, height div 4, '发送失败');
      Exit;
    end;

    var Message: TMessage;

    ttx.msg_type := '投递成功';
    ttx.msg_value := 'ok';
    Message := TMessage<tmsg_obj>.Create(ttx);
    message_bus.SendMessage(nil, Message, true);

  finally
    if json <> nil then
      freeandnil(json);
  end;
  close;
end;

procedure Tset_frm.get_fail_state_login(sender: tobject; json_value: string; thread_index: integer);
begin
  Canvas.TextOut(width div 4 + 30, height div 4, '发送失败')
end;

procedure Tset_frm.FormMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  releasecapture;
  sendmessage(handle, wm_syscommand, $F011, 0);
end;

procedure Tset_frm.FormResize(Sender: TObject);
begin
//  setwindowrgn(handle, createroundrectrgn(1, 1, Width - 2, height - 2, 5, 5), True);
end;

procedure Tset_frm.FormShow(Sender: TObject);
begin
  RadioButton3.Checked := true;
  DatePicker1.Visible := false;
//    Edit1.Visible:=False;
  RadioButton3Click(self);
  if Edit1.CanFocus then
    Edit1.SetFocus;
  Edit1.Clear;
end;

procedure Tset_frm.RadioButton1Click(Sender: TObject);
begin
  DatePicker1.Visible := true;
end;

procedure Tset_frm.RadioButton2Click(Sender: TObject);
begin
  DatePicker1.Visible := false;
end;

procedure Tset_frm.RadioButton3Click(Sender: TObject);
begin
  DatePicker1.Visible := false;
end;

procedure Tset_frm.Image2MouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  ReleaseCapture;
  Perform(WM_SysCommand, $F008, 0);
end;

procedure Tset_frm.ImgPanel1Click(Sender: TObject);
var
  json: tqjson;
  vS: TStringStream;
type
  tlogn_ = record
    ctype: string;
    dt: string;
    content: string;
    msg_id: string;
    token: string;
    ver: integer;
  end;
var
  logn_: tlogn_;
begin
  if memo1.Lines.Text.Trim = '' then
    exit;

  json := tqjson.create;
  vS := TStringStream.create('', TEncoding.UTF8);
  var token_ := g_global.imp.db.kv.getstring('token');
  try
    if RadioButton1.Checked then
    begin
      logn_.ctype := '1';
      logn_.dt := DateTimeToStr(DatePicker1.Date);
      var year: word;
      var month: word;
      var day: word;
      DecodeDate(now, year, month, day);
      var arr := logn_.dt.Split(['-']);
      if length(arr[1]) < 2 then
        arr[1] := '0' + arr[1];
      if length(arr[2]) < 2 then
        arr[2] := '0' + arr[2];
      logn_.dt := edit1.Text + ' ' + year.ToString + '-' + arr[1] + '-' + arr[2];
      logn_.content := memo1.Lines.Text.Trim;
      logn_.msg_id := GetGUID;
      logn_.token := token_;
      logn_.ver := 1;
    end
    else if RadioButton2.Checked then
    begin
      logn_.ctype := '2';
      var year: word;
      var month: word;
      var day: word;
      DecodeDate(now, year, month, day);

      logn_.dt := edit1.Text + ' ' + year.ToString + '-' + month.ToString + '-' + day.ToString;
//      logn_.dt := '00-00-00';
      logn_.content := trim(memo1.Text); // memo1.Lines.Text.Trim;
      logn_.msg_id := GetGUID;
      logn_.token := token_;
      logn_.ver := 1;
    end
    else if RadioButton3.Checked then
    begin
      logn_.ctype := '3';
      var year: word;
      var month: word;
      var day: word;
      DecodeDate(now, year, month, day);

      logn_.dt := edit1.Text + ' ' + year.ToString + '-' + month.ToString + '-' + day.ToString;
//      logn_.dt := '00-00-00';
      logn_.content := trim(memo1.Text); // memo1.Lines.Text.Trim;
      logn_.msg_id := GetGUID;
      logn_.token := token_;
      logn_.ver := 1;
    end;
    json.FromRecord(logn_);

    vS.WriteString(json.AsJson);
    vS.Position := 0;
    g_global.imp.http_pools.execute_post('api_c2c_save', vS, get_succ_state_login, get_fail_state_login, []);
  finally

    if json <> nil then
      freeandnil(json);
  end;

end;

procedure Tset_frm.ImgPanel2MouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  releasecapture;
  SendMessage(handle, wm_syscommand, $F011, 0);
end;

end.

