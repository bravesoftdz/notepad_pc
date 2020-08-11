unit widgetScrollBar;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, ExtCtrls,
  StdCtrls, uutils, scrollbar_bas, pngimage, GR32;

type
  tpostion_xy = record
    R: TRect;
    MouseIn: Boolean;
    Down: Boolean;
    Visible: Boolean;
  end;

  TWidgetScrollBar = class(tscroll_bas)
  private
    Offset1, Offset2, BOffset: Integer;
    NewTrackArea: TRect;
    FDown, FMouseInClientRect: Boolean;
    OMPos, OldPosition, FScrollWidth: Integer;
    OldBOffset: Integer;
    MX, MY: Integer;
    MouseD: Boolean;
    Fscrollbar_bar_down, Fscrollbar_bar_highlight, Fscrollbar_bar_normal, Fscrollbar_bkg, Fscrollbar_arrowdown_normal, Fscrollbar_arrowup_normal, Fscrollbar_arrowdown_down, Fscrollbar_arrowdown_highlight, Fscrollbar_arrowup_down, Fscrollbar_arrowup_highlight: string;
    FTransparent: Boolean;
    FColor: TColor;
    FAutoHide: Boolean;
    FBindingWinControl: TWinControl;
    procedure SetAutoHide(const Value: Boolean);
    procedure SetBindingWinControl(const Value: TWinControl);
  protected
    WaitMode: Boolean;
    FClicksDisabled: Boolean;
    FCanFocused: Boolean;
    FOnChange: TNotifyEvent;
    FOnUpButtonClick: TNotifyEvent;
    FOnDownButtonClick: TNotifyEvent;
    FOnLastChange: TNotifyEvent;
    FOnPageUp: TNotifyEvent;
    FOnPageDown: TNotifyEvent;
    TimerMode: Integer;
    ActiveButton, OldActiveButton, CaptureButton: Integer;
    postion_xy: array[0..2] of tpostion_xy;
    FMin, FMax, FSmallChange, FLargeChange, FPosition: Integer;
    FKind: TScrollBarKind;
    FPageSize, FBarWidth: Integer;
    procedure CreateControlRegion;
    function IsFocused: Boolean;
    procedure SetCanFocused(Value: Boolean);
    procedure TestActive(X, Y: Integer);
    procedure SetPageSize(AValue: Integer);
    procedure ButtonDown(I: Integer; X, Y: Integer);
    procedure ButtonUp(I: Integer; X, Y: Integer);
    procedure ButtonEnter(I: Integer);
    procedure ButtonLeave(I: Integer);
    procedure CalcRects;
    function CalcValue(AOffset: Integer): Integer;
    procedure SetPosition(AValue: Integer);
    procedure SetMin(AValue: Integer);
    procedure SetMax(AValue: Integer);
    procedure SetSmallChange(AValue: Integer);
    procedure SetLargeChange(AValue: Integer);
    procedure CalcSize(var W, H: Integer);
    procedure DrawBody(Bmp32: TBitmap32); override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure WMTimer(var Message: TWMTimer); message WM_Timer;
    procedure StartScroll;
    procedure StopTimer;
    procedure DrawButton(Bmp32: TBitmap32; I: Integer);
    procedure WMMOUSEWHEEL(var Message: TMessage); message WM_MOUSEWHEEL;
    procedure CMMouseLeave(var Message: TMessage); message CM_MOUSELEAVE;
    procedure CMMouseEnter(var Message: TMessage); message CM_MOUSEENTER;
    procedure CMEnabledChanged(var Message: TMessage); message CM_ENABLEDCHANGED;
    procedure WMSETFOCUS(var Message: TWMSETFOCUS); message WM_SETFOCUS;
    procedure WMKILLFOCUS(var Message: TWMKILLFOCUS); message WM_KILLFOCUS;
    procedure WndProc(var Message: TMessage); override;
    procedure CMWantSpecialKey(var Msg: TCMWantSpecialKey); message CM_WANTSPECIALKEY;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    procedure CreateControlDefaultImage(B: TBitmap32);
    procedure SetBounds(ALeft, ATop, AWidth, AHeight: Integer); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure SetRange(AMin, AMax, APosition, APageSize: Integer);
    property BindingWinControl: TWinControl read FBindingWinControl write SetBindingWinControl;
  published
    property AutoHide: Boolean read FAutoHide write SetAutoHide default False;
    property Enabled;
    property CanFocused: Boolean read FCanFocused write SetCanFocused default False;
    property Align;
    property Anchors;
    property Visible;
    property Min: Integer read FMin write SetMin default 0;
    property Max: Integer read FMax write SetMax default 100;
    property Position: Integer read FPosition write SetPosition default 0;
    property SmallChange: Integer read FSmallChange write SetSmallChange default 1;
    property LargeChange: Integer read FLargeChange write SetLargeChange default 1;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
    property OnLastChange: TNotifyEvent read FOnLastChange write FOnLastChange;
    property OnUpButtonClick: TNotifyEvent read FOnUpButtonClick write FOnUpButtonClick;
    property OnDownButtonClick: TNotifyEvent read FOnDownButtonClick write FOnDownButtonClick;
    property OnPageUp: TNotifyEvent read FOnPageUp write FOnPageUp;
    property OnPageDown: TNotifyEvent read FOnPageDown write FOnPageDown;
    property OnKeyDown;
    property OnKeyPress;
    property OnKeyUp;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
    property OnResize;
  end;

procedure Register;

implementation

const
  THUMB = 0;
  UPBUTTON = 1;
  DOWNBUTTON = 2;

procedure Register;
begin
  RegisterComponents('widget', [TWidgetScrollBar]);
end;

constructor TWidgetScrollBar.Create;
begin
  inherited;
  FCanFocused := False;
  Color := clWhite;
  FMin := 0;
  FMax := 100;
  FPosition := 0;
  FSmallChange := 1;
  FLargeChange := 1;
  FPageSize := 0;
  WaitMode := False;
  TimerMode := 0;
  ActiveButton := -1;
  OldActiveButton := -1;
  CaptureButton := -1;
  FOnChange := nil;
  Width := 200;
  Height := 19;
  FBarWidth := Height;
  FAutoHide := False;
  FTransparent := True;
  FBindingWinControl := nil;
  Fscrollbar_bar_down := 'Scrollbar_bar_down';
  Fscrollbar_bar_highlight := 'Scrollbar_bar_highlight';
  Fscrollbar_bar_normal := 'Scrollbar_bar_normal';
  Fscrollbar_bkg := 'Scrollbar_bkg';
  Fscrollbar_arrowdown_normal := 'Scrollbar_arrowdown_normal';
  Fscrollbar_arrowup_normal := 'Scrollbar_arrowup_normal';
  Fscrollbar_arrowdown_down := 'Scrollbar_arrowdown_down';
  Fscrollbar_arrowdown_highlight := 'Scrollbar_arrowdown_highlight';
  Fscrollbar_arrowup_down := 'Scrollbar_arrowup_down';
  Fscrollbar_arrowup_highlight := 'Scrollbar_arrowup_highlight';
end;

destructor TWidgetScrollBar.Destroy;
begin
  inherited;
end;

procedure TWidgetScrollBar.CMEnabledChanged;
begin
  inherited;
  Invalidate;
end;

procedure TWidgetScrollBar.SetAutoHide(const Value: Boolean);
begin
  FAutoHide := Value;
  if FAutoHide then
    Visible := False;
end;

procedure TWidgetScrollBar.SetBindingWinControl(const Value: TWinControl);
begin
  FBindingWinControl := Value;
end;

procedure TWidgetScrollBar.SetBounds(ALeft, ATop, AWidth, AHeight: Integer);
begin
  inherited;
  Invalidate;
end;

procedure TWidgetScrollBar.KeyDown;
begin
  inherited KeyDown(Key, Shift);
  if FCanFocused then
    case Key of
      VK_DOWN, VK_RIGHT:
        Position := Position + FSmallChange;
      VK_UP, VK_LEFT:
        Position := Position - FSmallChange;
    end;
end;

procedure TWidgetScrollBar.WMMOUSEWHEEL;
begin
  if IsFocused then
    if TWMMOUSEWHEEL(Message).WheelDelta > 0 then
      Position := FPosition - FSmallChange
    else
      Position := FPosition + FSmallChange;
end;

procedure TWidgetScrollBar.CMWantSpecialKey(var Msg: TCMWantSpecialKey);
begin
  inherited;
  if FCanFocused then
    case Msg.CharCode of
      VK_UP, VK_DOWN, VK_LEFT, VK_RIGHT:
        Msg.Result := 1;
    end;
end;

function TWidgetScrollBar.IsFocused;
begin
  Result := Focused and FCanFocused;
end;

procedure TWidgetScrollBar.SetCanFocused;
begin
  FCanFocused := Value;
  if FCanFocused then
    TabStop := True
  else
    TabStop := False;
end;

procedure TWidgetScrollBar.WMSETFOCUS;
begin
  inherited;
  if FCanFocused then
    Invalidate;
end;

function LoadPNGintoBitmap32(DstBitmap: TBitmap32; SrcStream: TStream): Boolean;
var
  PNGObject: TPNGObject;
  TransparentColor: TColor32;
  PixelPtr: PColor32;
  AlphaPtr: PByte;
  X, Y: Integer;
begin
  PNGObject := nil;
  try

    PNGObject := TPNGObject.Create;
    PNGObject.LoadFromStream(SrcStream);

    PNGObject.RemoveTransparency;
    DstBitmap.Assign(PNGObject);
    DstBitmap.ResetAlpha;

    SrcStream.Position := 0;
    PNGObject.LoadFromStream(SrcStream);

    case PNGObject.TransparencyMode of
      ptmPartial:
        begin
          if (PNGObject.Header.ColorType = COLOR_GRAYSCALEALPHA) or (PNGObject.Header.ColorType = COLOR_RGBALPHA) then
          begin
            PixelPtr := PColor32(@DstBitmap.Bits[0]);
            for Y := 0 to DstBitmap.Height - 1 do
            begin
              AlphaPtr := PByte(PNGObject.AlphaScanline[Y]);
              for X := 0 to DstBitmap.Width - 1 do
              begin
                PixelPtr^ := (PixelPtr^ and $00FFFFFF) or (TColor32(AlphaPtr^) shl 24);
                Inc(PixelPtr);
                Inc(AlphaPtr);
              end;
            end;

            Result := True;
          end;
        end;
      ptmBit:
        begin
          TransparentColor := Color32(PNGObject.TransparentColor);
          PixelPtr := PColor32(@DstBitmap.Bits[0]);
          for X := 0 to DstBitmap.Height * DstBitmap.Width - 1 do
          begin
            if PixelPtr^ = TransparentColor then
              PixelPtr^ := PixelPtr^ and $00FFFFFF;
            Inc(PixelPtr);
          end;

          Result := True;
        end;
      ptmNone:
        Result := False;
    end;
  finally
    if Assigned(PNGObject) then
      PNGObject.Free;
  end;
end;
//

function GetImageByFileName(const FileName: string): TBitmap32;
var
  bb: Boolean;
  img: TBitmap32;
begin
  try

    img := TBitmap32.Create;

    var FileStream: TFileStream;

    FileStream := TFileStream.Create(FileName, fmOpenRead);
    try
      bb := LoadPNGintoBitmap32(img, FileStream);
    finally
      FileStream.Free;
    end;

    if bb then
      img.DrawMode := dmBlend
    else
      img.DrawMode := dmOpaque;

    Result := TBitmap32(img);

  except
    Result := nil;
  end;
end;

procedure TWidgetScrollBar.WMKILLFOCUS;
begin
  inherited;
  if FCanFocused then
    Invalidate;
end;

procedure TWidgetScrollBar.WndProc(var Message: TMessage);
begin
  if FCanFocused then
    case Message.Msg of
      WM_LBUTTONDOWN, WM_LBUTTONDBLCLK:
        if not (csDesigning in ComponentState) and not Focused then
        begin
          FClicksDisabled := True;
          Windows.SetFocus(Handle);
          FClicksDisabled := False;
          if not Focused then
            Exit;
        end;
      CN_COMMAND:
        if FClicksDisabled then
          Exit;
    end;
  inherited WndProc(Message);
end;

procedure TWidgetScrollBar.CalcSize;
begin
  CalcRects;
end;

procedure TWidgetScrollBar.SetPageSize;
begin
  if AValue + FPosition <= FMax - FMin + 1 then
    FPageSize := AValue;
  Invalidate;
end;

procedure TWidgetScrollBar.StopTimer;
begin
  KillTimer(Handle, 1);
  TimerMode := 0;
end;

procedure TWidgetScrollBar.TestActive(X, Y: Integer);
var
  I, j: Integer;
begin
  j := -1;
  OldActiveButton := ActiveButton;
  for I := 0 to 2 do
  begin
    if PtInRect(postion_xy[I].R, Point(X, Y)) then
    begin
      j := I;
      Break;
    end;
  end;
  ActiveButton := j;
  if (CaptureButton <> -1) and (ActiveButton <> CaptureButton) and (ActiveButton <> -1) then
    ActiveButton := -1;
  if (OldActiveButton <> ActiveButton) then
  begin
    if OldActiveButton <> -1 then
      ButtonLeave(OldActiveButton);
    if ActiveButton <> -1 then
      ButtonEnter(ActiveButton);
  end;
end;

procedure TWidgetScrollBar.DrawBody(Bmp32: TBitmap32);
begin
  inherited;
  if (Width <= 0) or (Height <= 0) then
    Exit;
  CreateControlDefaultImage(Bmp32);
end;

procedure TWidgetScrollBar.DrawButton(Bmp32: TBitmap32; I: Integer);
var
  img, tImg: TBitmap32;
  H: Integer;
  imgName: string;
begin
  with postion_xy[I] do
  begin

    if I = THUMB then
    begin
      with postion_xy[THUMB] do
      begin

        H := RectHeight(R);
        img := nil;

        if Down or IsFocused then
          imgName := Fscrollbar_bar_down
        else if MouseIn then
          imgName := Fscrollbar_bar_highlight
        else
          imgName := Fscrollbar_bar_normal;

        tImg := GetImageByFileName(ExtractFilePath(ParamStr(0)) + 'Res\scrollbar\' + imgName + '.png');

        if tImg <> nil then
          img := ResizeVertImg(tImg, H);

        if Assigned(img) then
        begin
          img.DrawTo(Bmp32, R.Left, R.Top);
          FreeAndNil(img);
        end;
      end;
    end
    else
    begin
      case I of
        UPBUTTON:
          with postion_xy[UPBUTTON] do
          begin
            H := RectHeight(R);

            if Down or IsFocused then
              imgName := Fscrollbar_arrowdown_down
            else if MouseIn then
              imgName := Fscrollbar_arrowdown_highlight
            else if FMouseInClientRect then
              imgName := Fscrollbar_arrowdown_normal
            else
              imgName := '';
            if imgName <> '' then
            begin
              tImg := GetImageByFileName(ExtractFilePath(ParamStr(0)) + 'Res\scrollbar\' + imgName + '.png');
              img := ResizeVertImg(tImg, H);
            end
            else
              img := nil;

            if Assigned(img) then
            begin
              img.DrawTo(Bmp32, R.Left, R.Top);
              FreeAndNil(img);
            end;
          end;
        DOWNBUTTON:
          with postion_xy[DOWNBUTTON] do
          begin
            H := RectHeight(R);

            if Down or IsFocused then
              imgName := Fscrollbar_arrowup_down
            else if MouseIn then
              imgName := Fscrollbar_arrowup_highlight
            else if FMouseInClientRect then
              imgName := Fscrollbar_arrowup_normal
            else
              imgName := '';
            if imgName <> '' then
            begin

              tImg := GetImageByFileName(ExtractFilePath(ParamStr(0)) + 'Res\scrollbar\' + imgName + '.png');

              if tImg <> nil then
                img := ResizeVertImg(tImg, H);
            end
            else
              img := nil;

            if Assigned(img) then
            begin
              img.DrawTo(Bmp32, R.Left, R.Top);
              FreeAndNil(img);
            end;
          end
      end;
    end;
  end
end;

procedure TWidgetScrollBar.CalcRects;
var
  Kf: Double;
  I, j, k, XMin, XMax: Integer;
  Offset: Integer;
  ThumbW: Integer;
  NewWidth: Integer;
  img: TBitmap32;
begin
  if FMin = FMax then
    Kf := 0
  else
    Kf := (FPosition - FMin) / (FMax - FMin);
  NewWidth := Width;
  ThumbW := 20;

  img := GetImageByFileName(ExtractFilePath(ParamStr(0)) + 'Res\scrollbar\' + Fscrollbar_arrowup_normal + '.png');

  if img <> nil then
  begin
    postion_xy[DOWNBUTTON].R := Rect(0, 0, Width, img.Height);
    postion_xy[UPBUTTON].R := Rect(0, Height - img.Height, Width, Height);
    NewTrackArea := Rect(0, img.Height, Width, Height - img.Height);
  end;
  if fPageSize = 0 then
  begin
    Offset1 := NewTrackArea.Top + ThumbW div 2;
    Offset2 := NewTrackArea.Bottom - ThumbW div 2;
    BOffset := Round((Offset2 - Offset1) * Kf);
    postion_xy[THUMB].R := Rect(NewTrackArea.Left, Offset1 + BOffset - ThumbW div 2, NewTrackArea.Right, Offset1 + BOffset + ThumbW div 2);
  end
  else
  begin
    I := RectHeight(NewTrackArea);
    j := FMax - FMin + 1;
    if j = 0 then
      Kf := 0
    else
      Kf := FPageSize / j;
    j := Round(I * Kf);
    if j < ThumbW then
      j := ThumbW;
    XMin := FMin;
    XMax := FMax - FPageSize + 1;
    if XMax - XMin > 0 then
      Kf := (FPosition - XMin) / (XMax - XMin)
    else
      Kf := 0;
    Offset1 := NewTrackArea.Top + j div 2;
    Offset2 := NewTrackArea.Bottom - j div 2;
    BOffset := Round((Offset2 - Offset1) * Kf);
    postion_xy[THUMB].R := Rect(NewTrackArea.Left, Offset1 + BOffset - j div 2, NewTrackArea.Right, Offset1 + BOffset + j div 2);
  end;

end;

procedure TWidgetScrollBar.SetPosition;
var
  TempValue: Integer;
begin
  if FPageSize = 0 then
  begin
    if AValue < FMin then
      TempValue := FMin
    else if AValue > FMax then
      TempValue := FMax
    else
      TempValue := AValue;
  end
  else
  begin
    if AValue < FMin then
      TempValue := FMin
    else if AValue > FMax - FPageSize + 1 then
      TempValue := FMax - FPageSize + 1
    else
      TempValue := AValue;
  end;
  if TempValue <> FPosition then
  begin
    FPosition := TempValue;
    Invalidate;
    if Assigned(FOnChange) then
      FOnChange(Self);
  end;
end;

procedure TWidgetScrollBar.SetRange(AMin, AMax, APosition, APageSize: Integer);
var
  v: Boolean;
begin

  FMin := AMin;
  FMax := AMax;
  FPageSize := APageSize;
  if FPageSize = 0 then
  begin
    if APosition < FMin then
      Position := FMin
    else if APosition > FMax then
      Position := FMax
    else
      FPosition := APosition;
  end
  else
  begin
    if APosition < FMin then
      Position := FMin
    else if APosition > FMax - FPageSize + 1 then
      Position := FMax - FPageSize + 1
    else
      FPosition := APosition;
  end;
  if FAutoHide then
  begin
    v := (FPageSize <> 0);
    if v <> Visible then
    begin
      Visible := v;
      if (not (Align = alNone) or (Align = alCustom)) then
      begin
        SetTimer(Handle, 2000, 30, nil);
      end;
    end;
  end;
  Invalidate;
end;

procedure TWidgetScrollBar.SetMax;
begin
  FMax := AValue;
  if FPageSize = 0 then
  begin
    if FPosition > FMax then
      FPosition := FMax;
  end
  else
  begin
    if FPageSize + FPosition > FMax - FMin then
      FPosition := (FMax - FMin) - FPageSize + 1;
    if FPosition < FMin then
      FPosition := FMin;
  end;
  Invalidate;
end;

procedure TWidgetScrollBar.SetMin;
begin
  FMin := AValue;
  if FPosition < FMin then
    FPosition := FMin;
  Invalidate;
end;

procedure TWidgetScrollBar.SetSmallChange;
begin
  FSmallChange := AValue;
  Invalidate;
end;

procedure TWidgetScrollBar.SetLargeChange;
begin
  FLargeChange := AValue;
  Invalidate;
end;

procedure TWidgetScrollBar.CreateControlDefaultImage(B: TBitmap32);
var
  R: TRect;
  I, j, W, H: Integer;
  img, ImgLeft, ImgUp, ImgVert: TBitmap32;
begin

  ImgLeft := GetImageByFileName(ExtractFilePath(ParamStr(0)) + 'Res\scrollbar\Scrollbar_arrowup_down.png');
  ImgUp := GetImageByFileName(ExtractFilePath(ParamStr(0)) + 'Res\scrollbar\' + Fscrollbar_arrowup_highlight + '.png');

  ImgVert := GetImageByFileName(ExtractFilePath(ParamStr(0)) + 'Res\scrollbar\' + Fscrollbar_bkg + '.png');

  if ImgLeft = nil then
    Exit;
  if ImgUp = nil then
    Exit;
  if ImgVert = nil then
    Exit;
  CalcRects;
  R := ClientRect;
  W := Width - (ImgLeft.Width * 2);
  H := Height + 100;
  case FKind of

    sbVertical:
      begin
        if H > 0 then
        begin
          if H < ImgVert.Height then
            H := ImgVert.Height;
          img := ResizeVertImg(ImgVert, H);

          img.DrawTo(B, 0, ImgUp.Height - 30);
          img.Free;
        end;
      end;
  end;
  if Enabled then
    j := 0
  else
    j := 1;
  for I := j to 2 do
    DrawButton(B, I);
end;

procedure TWidgetScrollBar.CreateControlRegion;
var
  W, H: Integer;
begin
  W := Width;
  H := Height;
  CalcSize(W, H);
end;

procedure TWidgetScrollBar.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  I: Integer;
  j: Integer;
begin
  inherited;
  if Button <> mbLeft then
  begin
    inherited;
    Exit;
  end;
  MouseD := True;
  CalcRects;
  TimerMode := 0;
  WaitMode := True;
  j := -1;
  for I := 0 to 2 do
  begin
    if PtInRect(postion_xy[I].R, Point(X, Y)) then
    begin
      j := I;
      Break;
    end;
  end;
  if j <> -1 then
  begin
    CaptureButton := j;
    ButtonDown(j, X, Y);
  end
  else
  begin
    if PtInRect(NewTrackArea, Point(X, Y)) then
    begin
      if Y < postion_xy[THUMB].R.Top then
      begin
        Position := Position - LargeChange;
        TimerMode := 3;
        SetTimer(Handle, 1, 11, nil);
        if Assigned(FOnPageUp) then
          FOnPageUp(Self);
      end
      else
      begin
        Position := Position + LargeChange;
        TimerMode := 4;
        SetTimer(Handle, 1, 11, nil);
        if Assigned(FOnPageDown) then
          FOnPageDown(Self);
      end;
    end;

  end;
end;

procedure TWidgetScrollBar.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited;
  MouseD := False;
  if (TimerMode >= 3) then
    StopTimer;
  if CaptureButton <> -1 then
    ButtonUp(CaptureButton, X, Y);
  if (Button = mbLeft) and (CaptureButton = 0) and Assigned(FOnLastChange) then
    FOnLastChange(Self);
  CaptureButton := -1;
end;

function TWidgetScrollBar.CalcValue;
var
  Kf: Double;
  TempPos: Integer;
begin
  if FPageSize = 0 then
  begin
    if (Offset2 - Offset1) <= 0 then
      Kf := 0
    else
      Kf := AOffset / (Offset2 - Offset1);
    if Kf > 1 then
      Kf := 1
    else if Kf < 0 then
      Kf := 0;
    Result := FMin + Round((FMax - FMin) * Kf);
  end
  else
  begin

    Offset1 := NewTrackArea.Top + RectHeight(postion_xy[THUMB].R) div 2;
    Offset2 := NewTrackArea.Bottom - RectHeight(postion_xy[THUMB].R) div 2;

    TempPos := OldBOffset + AOffset;
    if (Offset2 - Offset1) <= 0 then
      Kf := 0
    else
      Kf := TempPos / (Offset2 - Offset1);
    if Kf > 1 then
      Kf := 1
    else if Kf < 0 then
      Kf := 0;
    Result := FMin + Round((FMax - FMin - FPageSize + 1) * Kf);
  end;
end;

procedure TWidgetScrollBar.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  Off: Integer;
begin
  MX := X;
  MY := Y;
  TestActive(X, Y);
  if FDown then
  begin
    if fPageSize = 0 then
    begin
      Off := Y - OMPos;
      Off := OldBOffset + Off;
      Position := CalcValue(Off);
    end
    else
      Off := Y - OMPos;
    Position := CalcValue(Off);
  end;

  inherited;
end;

procedure TWidgetScrollBar.ButtonDown;
begin
  postion_xy[I].Down := True;
  Invalidate;
  case I of
    THUMB:
      with postion_xy[THUMB] do
      begin
        OMPos := Y;
        OldBOffset := BOffset;
        OldPosition := Position;

        FScrollWidth := NewTrackArea.Bottom - R.Bottom;
        if FScrollWidth <= 0 then
          FScrollWidth := R.Top - NewTrackArea.Top;
        FDown := True;
        Invalidate;
      end;
    DOWNBUTTON:
      with postion_xy[UPBUTTON] do
      begin
        if Assigned(FOnDownButtonClick) then
          FOnDownButtonClick(Self)
        else
          Position := Position - SmallChange;
        TimerMode := 1;
        SetTimer(Handle, 1, 11, nil);
      end;
    UPBUTTON:
      with postion_xy[DOWNBUTTON] do
      begin
        if Assigned(FOnUpButtonClick) then
          FOnUpButtonClick(Self)
        else
          Position := Position + SmallChange;
        TimerMode := 2;
        SetTimer(Handle, 1, 11, nil);
      end;
  end;
end;

procedure TWidgetScrollBar.ButtonUp;
begin
  postion_xy[I].Down := False;
  if ActiveButton <> I then
    postion_xy[I].MouseIn := False;
  Invalidate;
  case I of
    THUMB:
      FDown := False;
    UPBUTTON:
      StopTimer;
    DOWNBUTTON:
      StopTimer;

  end;
end;

procedure TWidgetScrollBar.ButtonEnter(I: Integer);
begin
  postion_xy[I].MouseIn := True;
  Invalidate;
  case I of
    UPBUTTON:
      with postion_xy[UPBUTTON] do
      begin
        if Down then
          SetTimer(Handle, 1, 50, nil);
      end;
    DOWNBUTTON:
      with postion_xy[DOWNBUTTON] do
      begin
        if Down then
          SetTimer(Handle, 1, 50, nil);
      end;
  end;
end;

procedure TWidgetScrollBar.ButtonLeave(I: Integer);
begin
  postion_xy[I].MouseIn := False;
  Invalidate;
  case I of
    UPBUTTON:
      with postion_xy[UPBUTTON] do
      begin
        if Down then
          KillTimer(Handle, 1);
      end;
    DOWNBUTTON:
      with postion_xy[DOWNBUTTON] do
      begin
        if Down then
          KillTimer(Handle, 1);
      end;
  end;
end;

procedure TWidgetScrollBar.StartScroll;
begin
  KillTimer(Handle, 1);
  SetTimer(Handle, 1, 50, nil);
end;

procedure TWidgetScrollBar.WMTimer(var Message: TWMTimer);
var
  CanScroll: Boolean;
  t: Integer;
begin
  inherited;
  if Message.TimerID = 2001 then
  begin
    if Assigned(FOnChange) then
      FOnChange(Self);
    KillTimer(Handle, 2001);
    Exit;
  end;
  if Message.TimerID = 2000 then
  begin
    KillTimer(Handle, 2000);
    t := Height;
    Height := t - 1;
    Height := t;
    Exit;
  end;
  if WaitMode then
  begin
    WaitMode := False;
    StartScroll;
    Exit;
  end;
  case TimerMode of
    1:
      begin
        if Assigned(FOnDownButtonClick) then
          FOnDownButtonClick(Self)
        else
          Position := Position - SmallChange;
      end;
    2:
      begin
        if Assigned(FOnUpButtonClick) then
          FOnUpButtonClick(Self)
        else
          Position := Position + SmallChange;
      end;
    3:
      begin
        TestActive(MX, MY);
        CanScroll := MY < postion_xy[THUMB].R.Top;
        if CanScroll then
        begin
          Position := Position - LargeChange;
          if Assigned(FOnPageUp) then
            FOnPageUp(Self);
        end
        else
          StopTimer;
      end;
    4:
      begin
        TestActive(MX, MY);
        CanScroll := MY > postion_xy[THUMB].R.Bottom;
        if CanScroll then
        begin
          Position := Position + LargeChange;
          if Assigned(FOnPageDown) then
            FOnPageDown(Self);
        end
        else
          StopTimer;
      end;
  end;
end;

procedure TWidgetScrollBar.CMMouseLeave;
begin
  inherited;
  if (csDesigning in ComponentState) then
    Exit;
  FMouseInClientRect := False;
  if (ActiveButton <> -1) and (CaptureButton = -1) and not FDown then
  begin
    postion_xy[ActiveButton].MouseIn := False;
    ActiveButton := -1;
  end;
  if MouseD and (TimerMode > 3) then
    StopTimer;
  Invalidate;
end;

procedure TWidgetScrollBar.CMMouseEnter;
begin
  inherited;
  if (csDesigning in ComponentState) then
    Exit;
  FMouseInClientRect := True;
  Invalidate;
end;

end.

