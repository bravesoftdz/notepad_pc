unit uutils;

interface

uses
  Windows, Sysutils, Controls, Graphics, Forms, Messages, Classes, GR32,
  pngimage, jpeg, ActiveX, ImgList, Math, ComCtrls;

type
  TBitmap32Arr = array of TBitmap32;

const
  CST_FIXEDPNGALPHAREDRAWCOUNT = 8;
  CWM_CheckParentBg = WM_USER + 2001;
  TMID_CtrlsSIZE = 10000;

procedure GetParentImage(Control: TControl; Dest: TCanvas;
  const ARect: TRect); overload;

procedure GetParentImage(Control: TControl; Dest: TBitmap32;
  const ARect: TRect); overload;

procedure DrawParentImage(Control: TControl; Dest: TCanvas;
  const ARect: TRect); overload;

procedure DrawParentImage(Control: TControl; Dest: TBitmap32;
  const ARect: TRect); overload;

function SpliteImg(const Src: TBitmap32; Count: Integer): TBitmap32Arr;

function ResizeHorzImg(const Src: TBitmap32; const Width: Integer;
  const LeftRightSize: Integer = 0): TBitmap32;

function ResizeVertImg(const Src: TBitmap32; const Height: Integer): TBitmap32;

function SpliteHorz3Img(const Src: TBitmap32; const LeftRightSize: Integer = 0)
  : TBitmap32Arr;

function RectWidth(const ARect: TRect): Integer;

function RectHeight(const ARect: TRect): Integer;

procedure SetAlphaBlendTransparent(WHandle: HWND = 0; Value: Byte = 0);

function GetRectWidth(const rect: TRect): Integer;

function GetRectHeight(const rect: TRect): Integer;

implementation

uses
  Themes, UxTheme, scrollbar_bas, ShellApi, System.Win.Registry,
  GR32_Transforms;

type
  TFixedStreamAdapter = class(TStreamAdapter)
  public
    function Stat(out statstg: TStatStg; grfStatFlag: DWORD): HResult;
      override; stdcall;
  end;

  TParentControl = class(TWinControl);

  PRGB24 = ^TRGB24;

  TRGB24 = packed record
    B: Byte;
    G: Byte;
    R: Byte;
  end;

  PRGBArray = ^TRGBArray;

  TRGBArray = packed array [0 .. MaxInt div SizeOf(TRGB24) - 1] of TRGB24;

var
  gT: Integer = 0;
  lRH: Integer = 0;
  lRHSC: Integer = 0;

var

  jpeg: TJPEGImage;
  Bit: TBitmap;

procedure FreeDynImg(var DynImg: TBitmap32Arr);
var
  i: Integer;
begin
  for i := 0 to Length(DynImg) - 1 do
  begin
    if Assigned(DynImg[i]) then
    begin
      FreeAndNil(DynImg[i]);
    end;
  end;
  SetLength(DynImg, 0);
end;

function MyWinProc(HWND: THandle; uMsg: UINT; wParam, lParam: cardinal)
  : cardinal; stdcall;
var
  hdca, hdcb: THandle;
  ps: TPaintStruct;
begin
  Result := 0;
  case uMsg of
    WM_PAINT:
      begin
        hdca := BeginPaint(HWND, ps);
        BitBlt(hdca, 0, 0, Bit.Width, Bit.Height, Bit.Canvas.Handle, 0,
          0, SRCCOPY);
        EndPaint(HWND, ps);
      end;

    WM_DESTROY:
      PostQuitMessage(0);
  else
    Result := DefWindowProc(HWND, uMsg, wParam, lParam);

  end;
end;

function PKV_GetKeyByte(const Seed: Int64; a, B, c: Byte): Byte;
begin

end;

function PKV_GetChecksum(const s: string): string;
begin

end;

function PKV_MakeKey(const Seed: Int64): string;
begin

end;

function PKV_CheckKeyChecksum(const Key: string): Boolean;
begin

end;

function MlSoftGetCode(const UserKey: string): string;
begin

end;

function MlSoftGetKey(const UserCode: string): string;
var
  i, c: Integer;
  s: AnsiString;
begin
  s := UserCode;
  c := 0;
  for i := 1 to Length(s) do
  begin
    c := c + Ord(s[i]);
  end;
  Result := PKV_MakeKey(c);
end;

function MlSoftCheckKey(const UserCode, UserKey: string): Boolean;
begin
  Result := MlSoftGetKey(UserCode) = UserKey;
end;

function GetRectWidth(const rect: TRect): Integer;
begin
  Result := rect.Right - rect.Left;
end;

function GetRectHeight(const rect: TRect): Integer;
begin
  Result := rect.Bottom - rect.Top;
end;

function MlDrawSkinText(DC: HDC; AText: WideString; var Bounds: TRect;
  Flag: cardinal): Integer;
begin
  Result := Windows.DrawTextW(DC, PWideChar(AText), Length(AText), Bounds, Flag)
end;

procedure MlRH;
begin

end;

procedure SetAlphaBlendTransparent(WHandle: HWND; Value: Byte);
begin
  // lRU := True;
  gT := 1;

end;

// function CheckMultiMonitors: Boolean;
// var
// MonitorCount: Integer;
// begin
// MonitorCount := GetSystemMetrics(SM_CMONITORS);
// Result := (MonitorCount > 1) and Assigned(GetMonitorInfoFunc);
// end;

function GetPrimaryMonitorWorkArea(const WorkArea: Boolean): TRect;
begin
  if WorkArea then
    SystemParametersInfo(SPI_GETWORKAREA, 0, @Result, 0)
  else
    Result := rect(0, 0, Screen.Width, Screen.Height);
end;

function NullRect: TRect;
begin
  Result := rect(0, 0, 0, 0);
end;

procedure GetParentImage(Control: TControl; Dest: TBitmap32;
  const ARect: TRect); overload;
var
  Count, X, Y, SaveIndex: Integer;
  DC: HDC;
  SelfR, CtlR: TRect;
  CopyBitmapFromMemory: Boolean;
  i: Integer;
  MemoryBit: TBitmap32;
  R: TRect;
  // sh: PFormSkinHelperData;
begin
  with Control do
  begin
    if (Parent = nil) or (gT <= 0) then
    begin
      Dest.FillRect(0, 0, Dest.Width, Dest.Height, clWhite32);
      Exit;
    end;
    CopyBitmapFromMemory := False;
    R := ARect;

    if Parent is tscroll_bas then
    begin
      MemoryBit := tscroll_bas(Parent).BackgroundPicture;
      CopyBitmapFromMemory := True;
    end
    else
    begin
      CopyBitmapFromMemory := False;
    end;
    if csDesigning in ComponentState then
      CopyBitmapFromMemory := False;
    if CopyBitmapFromMemory then
    begin
      MemoryBit.DrawTo(Dest, Dest.ClipRect, R);
    end
    else
    begin
      if (Control = nil) or (Control.Parent = nil) then
        Exit;
      Count := Control.Parent.ControlCount;
      DC := Dest.Handle;
      with Control.Parent do
        ControlState := ControlState + [csPaintCopy];
      try
        with Control do
        begin
          SelfR := Bounds(Left, Top, Width, Height);
          X := -Left;
          Y := -Top;
        end;

        SaveIndex := SaveDC(DC);
        try
          SetViewportOrgEx(DC, X, Y, nil);
          IntersectClipRect(DC, 0, 0, Control.Parent.ClientWidth,
            Control.Parent.ClientHeight);
          with TParentControl(Control.Parent) do
          begin
            Perform(WM_ERASEBKGND, DC, 0);
            PaintWindow(DC);
          end;
        finally
          RestoreDC(DC, SaveIndex);
        end;

        for i := 0 to Count - 1 do
        begin
          if Control.Parent.Controls[i] = Control then
            Break
          else if (Control.Parent.Controls[i] <> nil) and
            (Control.Parent.Controls[i] is TGraphicControl) then
          begin
            with TGraphicControl(Control.Parent.Controls[i]) do
            begin
              CtlR := Bounds(Left, Top, Width, Height);
              if BOOL(IntersectRect(R, SelfR, CtlR)) and Visible then
              begin
                ControlState := ControlState + [csPaintCopy];
                SaveIndex := SaveDC(DC);
                try
                  SetViewportOrgEx(DC, Left + X, Top + Y, nil);
                  IntersectClipRect(DC, 0, 0, Width, Height);
                  Perform(WM_PAINT, DC, 0);
                finally
                  RestoreDC(DC, SaveIndex);
                  ControlState := ControlState - [csPaintCopy];
                end;
              end;
            end;
          end;
        end;
      finally
        with Control.Parent do
          ControlState := ControlState - [csPaintCopy];
      end;
    end;
  end;
end;

procedure GetParentImage(Control: TControl; Dest: TCanvas; const ARect: TRect);
var
  SaveIndex: Integer;
  DC: HDC;
  Position: TPoint;
  Count, X, Y: Integer;
  SelfR, CtlR: TRect;
  CopyBitmapFromMemory: Boolean;
  i: Integer;
  MemoryBit: TBitmap32;
  R: TRect;
begin
  with Control do
  begin
    if (Parent = nil) or (gT <= 0) then
    begin
      Dest.Brush.Color := clWhite;
      Dest.FillRect(rect(0, 0, GetRectWidth(ARect), GetRectHeight(ARect)));
      Exit;
    end;
    CopyBitmapFromMemory := False;
    R := ARect;
    if Parent is TForm then
    begin

    end;

    if csDesigning in ComponentState then
      CopyBitmapFromMemory := False;
    if CopyBitmapFromMemory then
    begin
      MemoryBit.DrawTo(Dest.Handle, Dest.ClipRect, R);
    end
    else
    begin
      if (Control = nil) or (Control.Parent = nil) then
        Exit;
      Count := Control.Parent.ControlCount;
      DC := Dest.Handle;
      with Control.Parent do
        ControlState := ControlState + [csPaintCopy];
      try
        with Control do
        begin
          SelfR := Bounds(Left, Top, Width, Height);
          X := -Left;
          Y := -Top;
        end;

        SaveIndex := SaveDC(DC);
        try
          SetViewportOrgEx(DC, X, Y, nil);
          IntersectClipRect(DC, 0, 0, Control.Parent.ClientWidth,
            Control.Parent.ClientHeight);
          with TParentControl(Control.Parent) do
          begin
            Perform(WM_ERASEBKGND, DC, 0);
            PaintWindow(DC);
          end;
        finally
          RestoreDC(DC, SaveIndex);
        end;

        for i := 0 to Count - 1 do
        begin
          if Control.Parent.Controls[i] = Control then
            Break
          else if (Control.Parent.Controls[i] <> nil) and
            (Control.Parent.Controls[i] is TGraphicControl) then
          begin
            with TGraphicControl(Control.Parent.Controls[i]) do
            begin
              CtlR := Bounds(Left, Top, Width, Height);
              if BOOL(IntersectRect(R, SelfR, CtlR)) and Visible then
              begin
                ControlState := ControlState + [csPaintCopy];
                SaveIndex := SaveDC(DC);
                try
                  SetViewportOrgEx(DC, Left + X, Top + Y, nil);
                  IntersectClipRect(DC, 0, 0, Width, Height);
                  Perform(WM_PAINT, DC, 0);
                finally
                  RestoreDC(DC, SaveIndex);
                  ControlState := ControlState - [csPaintCopy];
                end;
              end;
            end;
          end;
        end;
      finally
        with Control.Parent do
          ControlState := ControlState - [csPaintCopy];
      end;
    end;
  end;
end;

function TFixedStreamAdapter.Stat(out statstg: TStatStg; grfStatFlag:
  // {$IFDEF DELPHI_XE8UP}
  DWORD
  // {$ELSE}Longint{$ENDIF}
  ): HResult;
begin
  Result := inherited Stat(statstg, grfStatFlag);
  statstg.pwcsName := nil;
end;

function RectWidth(const ARect: TRect): Integer;
begin
  Result := ARect.Right - ARect.Left;
end;

function RectHeight(const ARect: TRect): Integer;
begin
  Result := ARect.Bottom - ARect.Top;
end;

procedure FillPng(const Src: TPngImage; var Dest: TPngImage;
  X, Y, Width, Height: Integer);
var
  i, j, ii, jj: Integer;
  p1, p2: PByteArray;
  pa1, pa2: PByteArray;
begin
  ii := 0;
  if X < 0 then
    X := 0;
  if Y < 0 then
    Y := 0;
  for i := Y to Y + Height - 1 do
  begin
    if ii >= Src.Height then
      ii := 0;
    p1 := Src.Scanline[ii];
    p2 := Dest.Scanline[i];
    pa1 := Src.AlphaScanline[ii];
    pa2 := Dest.AlphaScanline[i];
    // if p2<>nil then
    begin
      jj := 0;
      for j := X to X + Width - 1 do
      begin
        if jj >= Src.Width then
          jj := 0;
        p2[3 * j] := p1[3 * jj];
        p2[3 * j + 1] := p1[3 * jj + 1];
        p2[3 * j + 2] := p1[3 * jj + 2];
        pa2[j] := pa1[jj];
        Inc(jj);
      end;
    end;
    Inc(ii);
  end;
end;

function SpliteVertImg(const Src: TBitmap32; Count: Integer): TBitmap32Arr;
var
  lHeight, loffset: Integer;
  t: TAffineTransformation;
  i, j: Integer;
begin
  FreeDynImg(Result);
  if Src = nil then
  begin
    SetLength(Result, 0);
    Exit;
  end;
  lHeight := Src.Height div Count;
  t := TAffineTransformation.Create;
  SetLength(Result, Count);
  loffset := 0;
  for i := 0 to Count - 1 do
  begin
    Result[i] := TBitmap32.Create;
    Src.CopyPropertiesTo(Result[i]);

    Result[i].SetSize(Src.Width, lHeight);
    t.BeginUpdate;
    t.Clear;
    t.SrcRect := FloatRect(0, loffset, Src.Width, loffset + lHeight);
    t.Translate(0, -1 * loffset);
    t.EndUpdate;
    for j := 1 to CST_FIXEDPNGALPHAREDRAWCOUNT do

    begin
      Transform(Result[i], Src, t);
    end;
    loffset := lHeight * (i + 1);
  end;
  t.Free;
end;

function ResizeVertImg(const Src: TBitmap32; const Height: Integer): TBitmap32;
var
  imgs: TBitmap32Arr;
begin
  Result := TBitmap32.Create;
  Src.CopyPropertiesTo(Result);
  Result.SetSize(Src.Width, Height);
  if Height <= 0 then
    Exit;
  imgs := SpliteVertImg(Src, 3);
  if imgs[1].Height >= Result.Height then
  begin
    if Result.Height <= 3 then
      imgs[0].DrawTo(Result, rect(0, 0, Result.Width, Result.Height))
    else
      imgs[1].DrawTo(Result, rect(0, 0, Result.Width, Result.Height))
  end
  else
  begin

    imgs[1].DrawTo(Result.Handle, rect(0, imgs[0].Height, Result.Width,
      Result.Height - imgs[2].Height), rect(0, 0, imgs[1].Width,
      imgs[1].Height));

    imgs[0].DrawTo(Result.Handle, rect(0, 0, Result.Width, imgs[0].Height),
      rect(0, 0, imgs[0].Width, imgs[0].Height));

    imgs[2].DrawTo(Result.Handle, rect(0, Result.Height - imgs[2].Height,
      Result.Width, Result.Height), rect(0, 0, imgs[2].Width, imgs[2].Height));
  end;
  FreeDynImg(imgs);
end;

function ResizeHorzImg(const Src: TBitmap32; const Width: Integer;
  const LeftRightSize: Integer = 0): TBitmap32;
var
  imgs: TBitmap32Arr;
begin
  Result := TBitmap32.Create;
  Src.CopyPropertiesTo(Result);
  Result.SetSize(Width, Src.Height);
  if Width <= 0 then
    Exit;
  if LeftRightSize = 0 then
    imgs := SpliteImg(Src, 3)
  else
    imgs := SpliteHorz3Img(Src, LeftRightSize);
  if imgs[0].Width >= Result.Width then
  begin
    imgs[0].DrawTo(Result, rect(0, 0, imgs[0].Width, Result.Height));
  end
  else
  begin
    if LeftRightSize <> 0 then
    begin
      if Width > (3 + LeftRightSize) then
        imgs[1].DrawTo(Result.Handle, rect(imgs[0].Width, 0,
          Result.Width - imgs[2].Width, Result.Height),
          rect(0, 0, imgs[1].Width, imgs[1].Height));

      imgs[0].DrawTo(Result.Handle, rect(0, 0, imgs[0].Width, Result.Height),
        rect(0, 0, imgs[0].Width, imgs[0].Height));

      if Width > (3 + LeftRightSize) then
        imgs[2].DrawTo(Result.Handle, rect(Result.Width - imgs[2].Width, 0,
          Result.Width, Result.Height), rect(0, 0, imgs[2].Width,
          imgs[2].Height));
    end
    else
    begin

      imgs[1].DrawTo(Result.Handle, rect(imgs[0].Width, 0,
        Result.Width - imgs[0].Width, Result.Height),
        rect(0, 0, imgs[1].Width, imgs[1].Height));

      imgs[0].DrawTo(Result.Handle, rect(0, 0, imgs[0].Width, imgs[0].Height),
        rect(0, 0, imgs[0].Width, imgs[0].Height));

      imgs[2].DrawTo(Result.Handle, rect(Result.Width - imgs[2].Width, 0,
        Result.Width, imgs[2].Height), rect(0, 0, imgs[2].Width,
        imgs[2].Height));
    end;
  end;
  FreeDynImg(imgs);
end;

function SpliteHorz3Img(const Src: TBitmap32; const LeftRightSize: Integer = 0)
  : TBitmap32Arr;
var
  i, w, lwoffset, j: Integer;
  t: TAffineTransformation;
begin
  FreeDynImg(Result);
  if (LeftRightSize <= 0) or (LeftRightSize >= (Src.Width div 3)) then
  begin
    Result := SpliteImg(Src, 3);
    Exit;
  end;
  lwoffset := 0;
  t := TAffineTransformation.Create;
  SetLength(Result, 3);
  for i := 0 to Length(Result) - 1 do
  begin
    case i of
      0, 2:
        w := LeftRightSize;
      1:
        w := Src.Width - 2 * w;
    end;
    Result[i] := TBitmap32.Create;
    Src.CopyPropertiesTo(Result[i]);
    Result[i].SetSize(w, Src.Height);
    t.BeginUpdate;
    t.Clear;
    t.SrcRect := FloatRect(lwoffset, 0, lwoffset + w, Src.Height);
    t.Translate(-1 * lwoffset, 0);
    t.EndUpdate;
    for j := 1 to CST_FIXEDPNGALPHAREDRAWCOUNT do

    begin
      Transform(Result[i], Src, t);
    end;
    Inc(lwoffset, w);
  end;
  t.Free;
end;

function SpliteImg(const Src: TBitmap32; Count: Integer): TBitmap32Arr;
var
  lwidth, loffset: Integer;
  t: TAffineTransformation;
  i, j: Integer;
begin
  FreeDynImg(Result);
  if Src = nil then
  begin
    SetLength(Result, 0);
    Exit;
  end;
  lwidth := Src.Width div Count;
  t := TAffineTransformation.Create;
  SetLength(Result, Count);
  loffset := 0;
  for i := 0 to Count - 1 do
  begin
    Result[i] := TBitmap32.Create;
    Src.CopyPropertiesTo(Result[i]);
    Result[i].SetSize(lwidth, Src.Height);
    t.BeginUpdate;
    t.Clear;
    t.SrcRect := FloatRect(loffset, 0, loffset + lwidth, Src.Height);
    t.Translate(-1 * loffset, 0);
    t.EndUpdate;
    for j := 1 to CST_FIXEDPNGALPHAREDRAWCOUNT do

    begin
      Transform(Result[i], Src, t);
    end;
    loffset := lwidth * (i + 1);
  end;
  t.Free;
end;

procedure DrawParentImage(Control: TControl; Dest: TCanvas;
  const ARect: TRect); overload;
begin
  GetParentImage(Control, Dest, ARect);
end;

procedure DrawParentImage(Control: TControl; Dest: TBitmap32;
  const ARect: TRect); overload;
begin
  GetParentImage(Control, Dest, ARect);
end;

end.
