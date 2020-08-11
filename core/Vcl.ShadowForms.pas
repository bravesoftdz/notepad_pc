unit Vcl.ShadowForms;

interface

uses
{$IFDEF CLR}
  System.ComponentModel.Design.Serialization, System.Security.Permissions,
  System.Security,
{$ENDIF}
  Winapi.Messages, Winapi.Windows, System.UITypes, System.SysUtils,    Vcl.Dialogs,
  System.Classes, System.Actions, Vcl.Graphics, Vcl.Menus, Vcl.Controls,
  Vcl.ActnList, u_Debug, Vcl.Forms,  ExtCtrls,

  Winapi.GDIPAPI, Winapi.GDIPOBJ;

(*$HPPEMIT '#if defined(_VCL_ALIAS_RECORDS)' *)
{$IFDEF UNICODE}
(*$HPPEMIT '#if defined(UNICODE)' *)
(*$HPPEMIT '#pragma alias "@Vcl@Forms@TApplication@MessageBoxW$qqrpxbt1i"="@Vcl@Forms@TApplication@MessageBox$qqrpxbt1i"' *)
(*$HPPEMIT '#else' *)
(*$HPPEMIT '#pragma alias "@Vcl@Forms@TApplication@MessageBoxA$qqrpxbt1i"="@Vcl@Forms@TApplication@MessageBox$qqrpxbt1i"' *)
(*$HPPEMIT '#endif' *)
{$ELSE}
(*$HPPEMIT '#if defined(UNICODE)' *)
(*$HPPEMIT '#pragma alias "@Vcl@Forms@TApplication@MessageBoxW$qqrpxct1i"="@Vcl@Forms@TApplication@MessageBox$qqrpxct1i"' *)
(*$HPPEMIT '#else' *)
(*$HPPEMIT '#pragma alias "@Vcl@Forms@TApplication@MessageBoxA$qqrpxct1i"="@Vcl@Forms@TApplication@MessageBox$qqrpxct1i"' *)
(*$HPPEMIT '#endif' *)
{$ENDIF}
(*$HPPEMIT '#endif' *)

const
  sfShadowWidth = 1;

   INITIALX_96DPI= 50             ;
 INITIALY_96DPI =50              ;
 INITIALWIDTH_96DPI =100        ;
 INITIALHEIGHT_96DPI =50;
type

{ Forward declarations }
  TSkinForm = class;

  TShadowForm = class;

{ TSkinForm }
  TSkinForm = class(TForm)
  private
		{ private declarations }
    FBlendFunction: BLENDFUNCTION;
  public
		{ Public declarations }
    constructor CreateNew(AOwner: TComponent; Dummy: Integer = 0); override;
    procedure DrawRoundRectangle(AGPGraphics: TGPGraphics; AGPPen: TGPPen; ARect: TRect; ACornerRadius: Integer);
    procedure SetBitmaps;
    function CreateRoundedRectanglePath(ARect: TRect; ACornerRadius: Integer): TGPGraphicsPath;
  end;

{ TShadowForm }
  TShadowForm = class(TForm)
  private
		{ private declarations }
    FSkinForm: TSkinForm;
    procedure LocationChanged;
    procedure SizeChanged;
    procedure UpdateButtonLayoutForDpi(hWnd: thandle);
     property OnShow;
  public
    go: string;
		{ Public declarations }
    constructor Create(AOwner: TComponent); override;
    procedure ShowShadow;
    procedure HideShadow;
    procedure WMMove(var Message: TMessage); message WM_MOVE;
    procedure WMSize(var Message: TWMSize); message WM_SIZE;
        procedure WM_DPICHANGED(var Message: TMessage); message WM_DPICHANGED;
    procedure CMShowingChanged(var Message: TMessage); message CM_SHOWINGCHANGED;
    procedure WMMouseActivate(var Message: TWMMouseActivate); message WM_MOUSEACTIVATE;


  end;

implementation


procedure TShadowForm.UpdateButtonLayoutForDpi( hWnd:thandle)  ;
begin
    var iDpi:= GetDpiForWindow(hWnd);
    var dpiScaledX := MulDiv(INITIALX_96DPI, iDpi, 96);
    var dpiScaledY := MulDiv(INITIALY_96DPI, iDpi, 96);
    var dpiScaledWidth := MulDiv(INITIALWIDTH_96DPI, iDpi, 96);
    var dpiScaledHeight := MulDiv(INITIALHEIGHT_96DPI, iDpi, 96);
    SetWindowPos(hWnd, hWnd, dpiScaledX, dpiScaledY, dpiScaledWidth, dpiScaledHeight, SWP_NOZORDER or SWP_NOACTIVATE);
end;

    procedure AdjustControlPosition2Dpi(AOwner: TWinControl);
var
  dpi: Integer;
  i: Integer;
begin
  dpi := Screen.PixelsPerInch * 100 div 96;
  for i := 0 to AOwner.ControlCount - 1 do
  begin
    if (AOwner.Controls[i] is TImage) = False then
    begin
      AOwner.Controls[i].Top := AOwner.Controls[i].Top * 100 div dpi;
      AOwner.Controls[i].Left := AOwner.Controls[i].Left * 100 div dpi;
      AOwner.Controls[i].Width := AOwner.Controls[i].Width * 100 div dpi;
    end;
  end;
end;
{ TShadowForm }
procedure TShadowForm.CMShowingChanged(var Message: TMessage);
begin
  if not Visible then
    inherited
  else
    ShowWindow(Handle, SW_SHOWNOACTIVATE);
  ShowShadow();

end;

constructor TShadowForm.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FSkinForm := nil;
  AdjustControlPosition2Dpi(self);
end;

procedure TShadowForm.ShowShadow;
begin
  if go = 'go' then
  begin
    if (FSkinForm = nil) then
    begin
      FSkinForm := TSkinForm.CreateNew(Self); // 创建皮肤层
      FSkinForm.Color := $000000FF;
      FSkinForm.BorderStyle := bsNone;
      FSkinForm.left := Self.left - sfShadowWidth;
      FSkinForm.Top := Self.Top - sfShadowWidth;
      FSkinForm.Height := Self.Height + sfShadowWidth * 2;
      FSkinForm.Width := Self.Width + sfShadowWidth * 2;

      FSkinForm.SetBitmaps;
    end
    else
    begin
      FreeAndNil(FSkinForm);
      FSkinForm := TSkinForm.CreateNew(Self); // 创建皮肤层
      FSkinForm.Color := $000000FF;
      FSkinForm.BorderStyle := bsNone;
      FSkinForm.left := Self.left - sfShadowWidth;
      FSkinForm.Top := Self.Top - sfShadowWidth;
      FSkinForm.Height := Self.Height + sfShadowWidth * 2;
      FSkinForm.Width := Self.Width + sfShadowWidth * 2;

      FSkinForm.SetBitmaps;

    end;

    Self.LocationChanged;

    FSkinForm.Show;
  end;
end;

procedure TShadowForm.HideShadow;
begin
  Self.Visible := False;

  if (FSkinForm <> nil) then
  begin
    FSkinForm.Hide; // 隐藏皮肤层
  end;
end;

procedure TShadowForm.WMMouseActivate(var Message: TWMMouseActivate);
begin
  Message.Result := MA_NOACTIVATE;
end;

procedure TShadowForm.WMMove(var Message: TMessage);
begin
  inherited;
  if not (fsCreating in Self.FormState) then
    Self.ShowShadow;
end;

//procedure TShadowForm.WMShowWindow(var Message: TWMShowWindow);
//begin
//inherited;
//ShowMessage('ssss');
//end;

procedure TShadowForm.WMSize(var Message: TWMSize);
var
 i:integer;
begin
    if Message.SizeType = SIZE_MAXIMIZED then
        begin
          Self.Height := Screen.WorkAreaHeight;
          self.Width := Screen.WorkAreaWidth;
////          SetWindowRgn(Self.Handle, 0, TRUE);
        end;

//   for i := 0 to screen.FormCount-1 do     begin
////           UpdateButtonLayoutForDpi( screen.Forms[i].Handle);
//    screen.Forms[i].Left:=(Screen.Width-screen.Forms[i].Width) div 2;
//   screen.Forms[i].Top:=(Screen.WorkAreaHeight-screen.Forms[i].Height) div 2;
//
//   end;

  UpdateBounds; {去掉"UpdateBounds"这个函数,不然在Vista下会显示粗边框}
  UpdateExplicitBounds;

  Repaint();

  Realign;
  ShowShadow;
end;

procedure TShadowForm.WM_DPICHANGED(var Message: TMessage);
begin
sendmessage(handle,wm_size,0,0);
screen.ComponentCount
end;

procedure TShadowForm.LocationChanged;
begin
  if (FSkinForm <> nil) then
  begin
    FSkinForm.left := Self.left - sfShadowWidth;
    FSkinForm.Top := Self.Top - sfShadowWidth;
  end;
end;


procedure TShadowForm.SizeChanged;
begin
  if (FSkinForm <> nil) then
  begin
    FSkinForm.Height := Self.Height + sfShadowWidth * 2;
    FSkinForm.Width := Self.Width + sfShadowWidth * 2;
  end;
end;

{ TSkinForm }
constructor TSkinForm.CreateNew(AOwner: TComponent; Dummy: Integer = 0);
begin
  inherited CreateNew(AOwner);

  SetWindowLong(Self.Handle, GWL_EXSTYLE, GetWindowLong(Self.Handle, GWL_EXSTYLE) or WS_EX_LAYERED);
end;

procedure TSkinForm.DrawRoundRectangle(AGPGraphics: TGPGraphics; AGPPen: TGPPen; ARect: TRect; ACornerRadius: Integer);
var
  pathGPGraphics: TGPGraphicsPath;
begin
  pathGPGraphics := CreateRoundedRectanglePath(ARect, ACornerRadius);
  try
    AGPGraphics.DrawPath(AGPPen, pathGPGraphics);
  finally
    pathGPGraphics.Free;
  end;
end;

procedure TSkinForm.SetBitmaps;
var
  m_GPitmap: TGPBitmap;
  m_GPGraphicBitmap: TGPGraphics;
  m_GPGraphicMemory: TGPGraphics;
  m_GPColor: TGPColor;
  m_GPPen: TGPPen;
  i: Integer;
  m_Alpha: Byte;
  sPoint: TPoint;
  cRect: TRect;
  hdcScreen: HDC;
  hdcMemory: HDC;
  hdcTemp: HDC;
  hBMP: HBITMAP;
  ptWinPos: TPoint;
  ptSrc: TPoint;
  sizeWindow: SIZE;
begin
	// 创建与窗体大小相同的带Alpha通道的32位透明图像
  m_GPitmap := TGPBitmap.Create(Self.Width, Self.Height, PixelFormat32bppPARGB);
	// 创建图形对象
  m_GPGraphicBitmap := TGPGraphics.Create(m_GPitmap);
  m_GPGraphicBitmap.SetSmoothingMode(SmoothingModeAntiAlias);

  m_GPColor := MakeColor(0, 0, 0, 0);

  m_GPPen := TGPPen.Create(m_GPColor, 3);

  for i := 0 to sfShadowWidth do
  begin
    m_Alpha := Trunc(255 * i / 10 / sfShadowWidth);
    m_GPPen.SetColor(MakeColor(m_Alpha, 0, 0, 0));
    sPoint.X := i;
    sPoint.Y := i;
    cRect := TRect.Create(sPoint, Self.Width - (2 * i) - 1, Self.Height - (2 * i) - 1);
    DrawRoundRectangle(m_GPGraphicBitmap, m_GPPen, cRect, sfShadowWidth - i);
  end;

	// 创建兼容位图
  hdcTemp := GetDC(0);
  hdcMemory := CreateCompatibleDC(hdcTemp);
  hBMP := CreateCompatibleBitmap(hdcTemp, m_GPitmap.GetWidth(), m_GPitmap.GetHeight());
  SelectObject(hdcMemory, hBMP);

  FBlendFunction.BlendOp := AC_SRC_OVER;
  FBlendFunction.SourceConstantAlpha := 255;
  FBlendFunction.AlphaFormat := AC_SRC_ALPHA;
  FBlendFunction.BlendFlags := 0;

  hdcScreen := GetDC(0);
  GetWindowRect(Self.Handle, cRect);
  ptWinPos.X := cRect.left;
  ptWinPos.Y := cRect.Top;

  m_GPGraphicMemory := TGPGraphics.Create(hdcMemory);
  m_GPGraphicMemory.SetSmoothingMode(SmoothingModeAntiAlias);
  m_GPGraphicMemory.DrawImage(m_GPitmap, 0, 0, m_GPitmap.GetWidth(), m_GPitmap.GetHeight());

  sizeWindow.cx := m_GPitmap.GetWidth();
  sizeWindow.cy := m_GPitmap.GetHeight();

  ptSrc.X := 0;
  ptSrc.Y := 0;

  UpdateLayeredWindow(Self.Handle, hdcScreen, @ptWinPos, @sizeWindow, hdcMemory, @ptSrc, 0, @FBlendFunction, ULW_ALPHA);

	// 释放相关资源
  m_GPGraphicMemory.ReleaseHDC(hdcMemory);

  ReleaseDC(0, hdcScreen);
  hdcScreen := 0;

  ReleaseDC(0, hdcTemp);
  hdcTemp := 0;

  DeleteObject(hBMP);
  hBMP := 0;

  DeleteDC(hdcMemory);
  hdcMemory := 0;

  m_GPitmap.Free;
  m_GPGraphicMemory.Free;
  m_GPGraphicBitmap.Free;
end;

function TSkinForm.CreateRoundedRectanglePath(ARect: TRect; ACornerRadius: Integer): TGPGraphicsPath;
var
  roundedRect: TGPGraphicsPath;
begin
  roundedRect := TGPGraphicsPath.Create;
  roundedRect.AddArc(ARect.TopLeft.X, ARect.TopLeft.Y, ACornerRadius * 2, ACornerRadius * 2, 180, 90);
  roundedRect.AddLine(ARect.TopLeft.X + ACornerRadius, ARect.TopLeft.Y, ARect.Right - ACornerRadius * 2, ARect.TopLeft.Y);
  roundedRect.AddArc(ARect.TopLeft.X + ARect.Width - ACornerRadius * 2, ARect.TopLeft.Y, ACornerRadius * 2, ACornerRadius * 2, 270, 90);
  roundedRect.AddLine(ARect.Right, ARect.TopLeft.Y + ACornerRadius * 2, ARect.Right, ARect.TopLeft.Y + ARect.Height - ACornerRadius * 2);
  roundedRect.AddArc(ARect.TopLeft.X + ARect.Width - ACornerRadius * 2, ARect.TopLeft.Y + ARect.Height - ACornerRadius * 2, ACornerRadius * 2, ACornerRadius * 2, 0, 90);
  roundedRect.AddLine(ARect.Right - ACornerRadius * 2, ARect.Bottom, ARect.TopLeft.X + ACornerRadius * 2, ARect.Bottom);
  roundedRect.AddArc(ARect.TopLeft.X, ARect.Bottom - ACornerRadius * 2, ACornerRadius * 2, ACornerRadius * 2, 90, 90);
  roundedRect.AddLine(ARect.TopLeft.X, ARect.Bottom - ACornerRadius * 2, ARect.TopLeft.X, ARect.TopLeft.Y + ACornerRadius * 2);
  roundedRect.CloseFigure();
  Result := roundedRect;
end;

end.

