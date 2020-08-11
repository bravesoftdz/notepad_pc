unit frm_data_show;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls,  global, winapi.gdipobj, winapi.gdipapi,
  System.SyncObjs, u_debug, Vcl.Imaging.jpeg, Vcl.ExtCtrls, ImgPanel,
  Vcl.Imaging.pngimage;

type
  TfrmCardContact = class(tform)
    Memo1: TMemo;
    pnl1: TPanel;
    Bevel1: TBevel;
    Bevel2: TBevel;
    Bevel3: TBevel;
    Bevel4: TBevel;
    ImgPanel4: TImgPanel;
    Image2: TImage;
    procedure FormShow(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure pnl1MouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure ImgPanel4Click(Sender: TObject);
    procedure Image2MouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
  private
    Fuser_id: string;
    procedure make_circular_img(w, h: integer; image1: timage; bitmap1: tgpbitmap; wz: string);
  public
    procedure set_private_data(v: temploye);
  end;

var
  frmCardContact: TfrmCardContact;

implementation

uses
  VarCoreUnit;

var
  isself: Boolean = false;
  departMember: temploye;

{$R *.dfm}



procedure TfrmCardContact.make_circular_img(w, h: integer; image1: timage; bitmap1: tgpbitmap; wz: string);
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
    width := w;
    height := h;

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

  bmp.Free;
  graphic.free;
  bitmap2.free;
  bitmap1.free;
end;

procedure TfrmCardContact.FormResize(Sender: TObject);
begin
  pnl1.Left := self.Width div 2 - pnl1.Width div 2;
  pnl1.Top := top + self.Height div 2 - pnl1.Height div 2 + 20;
end;

procedure TfrmCardContact.FormShow(Sender: TObject);
begin
  pnl1.Left := Width div 2 - pnl1.Width div 2;
  pnl1.Top := height div 2 - pnl1.height div 2;

  Invalidate;
  Refresh;

end;

procedure TfrmCardContact.Image2MouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  ReleaseCapture;
  Perform(WM_SysCommand, $F008, 0);
end;

procedure TfrmCardContact.ImgPanel4Click(Sender: TObject);
begin
Close;
end;

procedure TfrmCardContact.pnl1MouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  releasecapture;
  postmessage(handle, wm_syscommand, sc_move + 1, 0);
end;

procedure TfrmCardContact.set_private_data(v: temploye);
begin

end;



end.

