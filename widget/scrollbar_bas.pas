unit scrollbar_bas;

interface

uses
  Windows, SysUtils, Controls, messages, Classes, Graphics,  uutils,
  GR32, GR32_Image,
   Forms;

type

  tscroll_bas = class(TWidgetPaintBox32)
  private
    FTransparent: Boolean;
    FColor: TColor;
    FAutoInvalidate: Boolean;
    FRgnChanging: Boolean;
    FEraseBackground: Boolean;
    FDelayRefresh: Boolean;

    procedure CWMCheckParentBg(var Msg: TMessage); message CWM_CheckParentBg;
    procedure SetTransparent(const Value: Boolean);
    procedure SetColor(const Value: TColor);
    procedure SetAutoInvalidate(const Value: Boolean);
    procedure SetEraseBackground(const Value: Boolean);
    procedure SetDelayRefresh(const Value: Boolean);
  protected
    FXOffset, FYOffset: Integer;
    FStopDrawBody: Boolean;
    procedure DoPaintBuffer; override; 
    procedure Resize; override;
    procedure DoBufferResized(const OldWidth, OldHeight: Integer); override;
    function GetBackgroundPicture: TBitmap32; virtual;
    procedure DrawBody(ABmp32: TBitmap32); virtual;
    function GetDoubleBuffer: TBitmap32; virtual;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure WMTimer(var Msg: TWMTimer); message WM_TIMER;
    procedure WMSize(var Msg: TWMSize); message WM_SIZE;
    procedure WMMove(var Msg: TWMMove); message WM_MOVE;
    procedure WMWindowPosChanged(var Message: TWMWindowPosChanged); message WM_WINDOWPOSCHANGED;
    procedure CMINVALIDATE(var Message: TMessage); message CM_INVALIDATE;
    procedure CM_TEXTCHANGED(var Message: TMessage); message CM_TEXTCHANGED;
    procedure CMENABLEDCHANGED(var Message: TMessage); message CM_ENABLEDCHANGED;
    procedure WMEraseBkgnd(var Message: TWmEraseBkgnd); message WM_ERASEBKGND;
    procedure AdjustClientRect(var Rect: TRect); override;
  public
    procedure RefreshSubControl(const All: Boolean = False);
    procedure InvalidateNC;
    constructor Create(AOwner: TComponent); override;
    property BackgroundPicture: TBitmap32 read GetBackgroundPicture;
    property DelayRefresh: Boolean read FDelayRefresh write SetDelayRefresh default False;
  published
    property DragCursor;
    property DragKind;
    property DragMode;
    property Transparent: Boolean read FTransparent write SetTransparent default True;
    property Color: TColor read FColor write SetColor default 16119285;//clWhite;
    property AutoInvalidate: Boolean read FAutoInvalidate write SetAutoInvalidate default False;
    property EraseBackground: Boolean read FEraseBackground write SetEraseBackground default False;
    property OnCanResize;
    property OnResize;
  end;

implementation

procedure tscroll_bas.AdjustClientRect(var Rect: TRect);
begin
  inherited AdjustClientRect(Rect);
  if not (csDesigning in ComponentState) then
    Invalidate;
end;

procedure tscroll_bas.CMENABLEDCHANGED(var Message: TMessage);
begin
  inherited;
  Invalidate;
end;

procedure tscroll_bas.CMINVALIDATE(var Message: TMessage);
begin
  inherited;
end;

procedure tscroll_bas.CM_TEXTCHANGED(var Message: TMessage);
begin
  inherited;
  Invalidate;
end;

constructor tscroll_bas.Create(AOwner: TComponent);
begin
  inherited;
  FTransparent := True;
  FColor := clWhite;
  FAutoInvalidate := False;
  BufferOversize := 0;
  FXOffset := 0;
  FYOffset := 0;
  FEraseBackground := False;
  FStopDrawBody := False;
  FDelayRefresh := False;
  if not (csDesigning in ComponentState) then
  begin
    SetAlphaBlendTransparent;
    StyleElements := [];
  end;
end;

procedure tscroll_bas.CWMCheckParentBg(var Msg: TMessage);
begin
  if not (csDesigning in ComponentState) then
  begin
    Invalidate;
    InvalidateNC;
  end;
end;


procedure tscroll_bas.DoBufferResized(const OldWidth, OldHeight: Integer);
begin
  inherited;
end;


procedure tscroll_bas.DoPaintBuffer;
var
  Handled: Boolean;
begin
  Buffer.BeginUpdate;
  Handled := False;
  if not Handled then
  begin
    
    if FTransparent then
    begin
      DrawParentImage(Self, Buffer, Rect(Left + FXOffset, Top + FYOffset, Left + Width + FXOffset, Top + Height + FYOffset));
    end
    else
    begin
      Buffer.FillRectS(0, 0, Width, Height, Color32(FColor));
    end;
  end;
  DrawBody(Buffer);
  Buffer.EndUpdate;
  
  if ((Left + Width) <= Parent.Width) and ((Top + Height) <= Parent.Height) then
    BufferValid := True;
end;

procedure tscroll_bas.DrawBody(ABmp32: TBitmap32);
begin

end;

function tscroll_bas.GetBackgroundPicture: TBitmap32;
begin
  Result := Buffer;
end;

function tscroll_bas.GetDoubleBuffer: TBitmap32;
begin
  Result := nil;
end;

procedure tscroll_bas.InvalidateNC;
var
  cw, ch: Integer;
begin
  cw := ClientWidth;
  ch := ClientHeight;
  if (cw <> Width) or (ch <> Height) then
    Perform(WM_NCPAINT, 0, 0);
end;

procedure tscroll_bas.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited;
end;

procedure tscroll_bas.RefreshSubControl(const All: Boolean);
var
  i: Integer;
begin
  if csDesigning in ComponentState then
    Exit;
  if not All then
  begin
    for i := 0 to ControlCount - 1 do
    begin
      if Controls[i] is TWinControl then
      begin
        PostMessage(TWinControl(Controls[i]).Handle, CWM_CheckParentBg, 0, 0);
      end;
    end;
  end
end;

procedure tscroll_bas.Resize;
begin
  try
    Buffer.BeginUpdate;
    inherited;
    Buffer.FillRectS(0, 0, Width, Height, Color32(FColor));
  finally
    Buffer.EndUpdate;
  end;
end;

procedure tscroll_bas.SetAutoInvalidate(const Value: Boolean);
begin
  FAutoInvalidate := Value;
end;

procedure tscroll_bas.SetColor(const Value: TColor);
begin
  FColor := Value;
  Invalidate;
end;

procedure tscroll_bas.SetDelayRefresh(const Value: Boolean);
begin
  FDelayRefresh := Value;
end;

procedure tscroll_bas.SetEraseBackground(const Value: Boolean);
begin
  FEraseBackground := Value;
end;

procedure tscroll_bas.SetTransparent(const Value: Boolean);
begin
  FTransparent := Value;
end;

procedure tscroll_bas.WMEraseBkgnd(var Message: TWmEraseBkgnd);
begin
  if FEraseBackground then
  begin
    if (Message.DC <> 0) and (Message.Unused = 1) then
    begin
      Buffer.DrawTo(Message.DC, 0, 0);
    end;
  end;
  Message.Result := 1;
end;

procedure tscroll_bas.WMMove(var Msg: TWMMove);
begin
  inherited;
  if FAutoInvalidate then
  begin
    Invalidate;
    RefreshSubControl;
  end;
end;

procedure tscroll_bas.WMSize(var Msg: TWMSize);
begin
  if FDelayRefresh then
  begin
    FStopDrawBody := True;
    KillTimer(Handle, TMID_CtrlsSIZE);
    SetTimer(Handle, TMID_CtrlsSIZE, 10, nil);
  end;
  inherited;
end;

procedure tscroll_bas.WMTimer(var Msg: TWMTimer);
begin
  if Msg.TimerID = TMID_CtrlsSIZE then
  begin
    KillTimer(Handle, TMID_CtrlsSIZE);
    FStopDrawBody := False;
    Invalidate;
  end
  else
    inherited;
end;

procedure tscroll_bas.WMWindowPosChanged(var Message: TWMWindowPosChanged);
begin
  if not ((csDesigning in ComponentState) or (csDestroying in ComponentState)) then
  begin
    ResizeBuffer;
  end;
  inherited;
end;

end.

 