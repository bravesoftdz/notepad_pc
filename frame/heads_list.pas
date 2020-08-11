unit heads_list;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, winapi.gdipobj, winapi.gdipapi, Vcl.Graphics, Vcl.Controls,
  Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.Imaging.pngimage, Vcl.ExtCtrls, jpeg,
  Vcl.Menus, System.Messaging;

type
  TFrame2 = class(TFrame)
    Image1: TImage;
    nickname: TLabel;
    Shape1: TShape;
    procedure Image1MouseEnter(Sender: TObject);
    procedure Image1MouseLeave(Sender: TObject);
    procedure Image2MouseEnter(Sender: TObject);
    procedure Image1Click(Sender: TObject);
  private
    procedure make_circular_img(w, h: integer; image1: timage; bitmap1: tgpbitmap; wz: string);
  public
    user_id: string;
    owner_id: string;
    members: string;
    froom_id: string;
    procedure vv(pic_path: string);
  end;

procedure closexx(x: thandle);

implementation

{$R *.dfm}

uses
  VarCoreUnit, global, frm_reg, utils, frm_login;

var
  oldfont: tcolor;

procedure closexx(x: thandle);
begin
  SendMessage(x, wm_close, 0, 0);
end;

procedure TFrame2.Image1Click(Sender: TObject);
begin

  if user_id = '101' then
  begin
    if not Assigned(reg_fm) then
      reg_fm := Treg_fm.create(self);
    reg_fm.ShowModal;
  end;
  if user_id = '103' then
  begin
    g_global.imp.db.kv.delky('gid');

    var Message: TMessage;

    ttx.msg_type := 'outlogin';
    ttx.msg_value := 'ok';
    Message := TMessage<tmsg_obj>.Create(ttx);
    message_bus.SendMessage(nil, Message, true);

  end;
  if user_id = '102' then
  begin
    if login_fm = nil then
      login_fm := Tlogin_fm.create(self);
    login_fm.Show;
  end;
end;

procedure TFrame2.Image1MouseEnter(Sender: TObject);
begin

  oldfont := nickname.Font.Color;
  nickname.Font.Color := clred;
end;

procedure TFrame2.Image1MouseLeave(Sender: TObject);
begin
  nickname.Font.Color := oldfont;
end;

procedure TFrame2.Image2MouseEnter(Sender: TObject);
begin
  oldfont := nickname.Font.Color;
  nickname.Font.Color := clred;
end;

procedure TFrame2.make_circular_img(w, h: integer; image1: timage; bitmap1: tgpbitmap; wz: string);
var
  bitmap2: tbitmap;
  graphic: tgpgraphics;
var
  bmp: tbitmap;
  rhandle: hrgn;
  r: trect;
begin

  bitmap2 := tbitmap.create;
  with bitmap2 do
  begin
//    Width := w * 2 div 3;  // shrink to 2/3 width
//    Height := h * 2 div 3;  // shrink to 2/3 height
    width := w; // * 2 div 3;  // shrink to 2/3 width
    height := h; // * 2 div 3;  // shrink to 2/3 height

    pixelformat := pf32bit;
  end;
  graphic := tgpgraphics.create(bitmap2.canvas.handle);
  graphic.setinterpolationmode(interpolationmodehighqualitybicubic);
  graphic.drawimage(bitmap1, 0, 0, bitmap2.width, bitmap2.height);

  image1.picture.assign(bitmap2);

  image1.autosize := true;
  r := image1.clientrect;
  bmp := tbitmap.create;

  bmp.assign(image1.picture.graphic);

  rhandle := createroundrectrgn(0, 0, image1.width, image1.height, image1.width, image1.height);

  image1.picture.assign(nil);
  image1.autosize := false;
  image1.stretch := false;
  image1.height := r.bottom - r.top;
  image1.width := r.right - r.left;

  image1.canvas.brush.color := clred;
  image1.canvas.fillrect(image1.clientrect);

  selectcliprgn(image1.canvas.handle, rhandle);
  image1.canvas.draw(0, 0, bmp);
  deleteobject(rhandle);
  image1.canvas.brush.style := bsclear;
  image1.picture.bitmap.transparentcolor := clred;
  image1.picture.bitmap.transparent := true;
  image1.transparent := true;
//  image1.canvas.font.size := 8;
//  image1.canvas.font.color :=$ffffff; //  $00A9A9A9;
//  image1.canvas.textout(image1.width div 2 - image1.canvas.textwidth(wz) div 2, image1.height div 3, duty);


  graphic.free;
  bitmap2.free;
  bitmap1.free;
end;

procedure TFrame2.vv(pic_path: string);
begin

  var bitmap1 := tgpbitmap.create(pic_path); // bmp, gif, jpeg, png...
//  make_circular_img(48, 48, image1, bitmap1, '����');
  make_circular_img(Image1.Width, Image1.Height, image1, bitmap1, '����');
end;

end.

