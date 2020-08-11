unit widgetree;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, StdCtrls,
  widgetscrollbar, Forms, VirtualTrees;

type
  TWidgetTree = class(TVirtualDrawTree)
  private
    FLockUpdate: Boolean;
    FOnScrollBarChange: TNotifyEvent;
    FVScrollBar: TWidgetScrollBar;
    FHScrollBar: TWidgetScrollBar;
    procedure SetHScrollBar(const Value: TWidgetScrollBar);
    procedure SetOnScrollBarChange(const Value: TNotifyEvent);
    procedure SetVScrollBar(const Value: TWidgetScrollBar);
    procedure OnVOnScrollBarChange(Sender: TObject);
    procedure OnHOnScrollBarChange(Sender: TObject);
    procedure UpDateScrollRanges;
    procedure WMNCCALCSIZE(var Message: TWMNCCalcSize); message WM_NCCALCSIZE;
  protected
    procedure Notification(AComponent: TComponent;
      Operation: TOperation); override;
    procedure DoScroll(DeltaX, DeltaY: Integer); override;
    procedure AlignControls(AControl: TControl; var ARect: TRect); override;
  public
    constructor Create(AOwner: TComponent); override;
    procedure UpdateHorizontalScrollBar(DoRepaint: Boolean); override;
    procedure UpdateVerticalScrollBar(DoRepaint: Boolean); override;
  published
    property VScrollBar: TWidgetScrollBar read FVScrollBar write SetVScrollBar;
    property HScrollBar: TWidgetScrollBar read FHScrollBar write SetHScrollBar;
    property OnScrollBarChange: TNotifyEvent read FOnScrollBarChange
      write SetOnScrollBarChange;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('widget', [TWidgetTree]);
end;

procedure TWidgetTree.DoScroll(DeltaX, DeltaY: Integer);
begin
  inherited;
  if not FLockUpdate then
    UpDateScrollRanges;
end;

procedure TWidgetTree.AlignControls(AControl: TControl; var ARect: TRect);
begin
  UpDateScrollRanges;
  inherited;
end;

constructor TWidgetTree.Create(AOwner: TComponent);
begin
  inherited;
  BorderStyle := bsNone;
end;

procedure TWidgetTree.Notification(AComponent: TComponent;
  Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if (Operation = opRemove) and (AComponent = FVScrollBar) then
    FVScrollBar := nil;
  if (Operation = opRemove) and (AComponent = FHScrollBar) then
    FHScrollBar := nil;
end;

procedure TWidgetTree.OnHOnScrollBarChange(Sender: TObject);
begin
  try
    BeginUpdate;
    FLockUpdate := True;
    OffsetX := -1 * FHScrollBar.Position;
    if Assigned(FOnScrollBarChange) then
      FOnScrollBarChange(FHScrollBar);
  finally
    FLockUpdate := False;
    EndUpdate;
  end;
end;

procedure TWidgetTree.OnVOnScrollBarChange(Sender: TObject);
begin
  try
    BeginUpdate;
    FLockUpdate := True;
    OffsetY := -1 * FVScrollBar.Position;
    if Assigned(FOnScrollBarChange) then
      FOnScrollBarChange(FVScrollBar);
  finally
    FLockUpdate := False;
    EndUpdate;
  end;
end;

procedure TWidgetTree.SetHScrollBar(const Value: TWidgetScrollBar);
begin
  FHScrollBar := Value;
  if Value <> nil then
  begin
    if not(csDesigning in ComponentState) then
    begin
      FHScrollBar.Min := 0;
      FHScrollBar.Max := 0;
      FHScrollBar.Position := 0;
      FHScrollBar.AutoHide := True;
      FHScrollBar.SmallChange := 20;
      FHScrollBar.BindingWinControl := Self;
      FHScrollBar.OnChange := OnHOnScrollBarChange;
    end;
  end;
end;

procedure TWidgetTree.SetOnScrollBarChange(const Value: TNotifyEvent);
begin
  FOnScrollBarChange := Value;
end;

procedure TWidgetTree.SetVScrollBar(const Value: TWidgetScrollBar);
begin
  FVScrollBar := Value;
  if Value <> nil then
  begin
    if not(csDesigning in ComponentState) then
    begin
      FVScrollBar.Min := 0;
      FVScrollBar.Max := 0;
      FVScrollBar.Position := 0;
      FVScrollBar.AutoHide := True;
      FVScrollBar.SmallChange := 20;
      FVScrollBar.BindingWinControl := Self;
      FVScrollBar.OnChange := OnVOnScrollBarChange;
    end;
  end;
end;

procedure TWidgetTree.UpdateHorizontalScrollBar(DoRepaint: Boolean);
var
  SF: ScrollInfo;
  sMin, SMax, SPos, sPage: Integer;
begin
  inherited;
  if csDesigning in ComponentState then
    Exit;
  if FHScrollBar <> nil then
    if not Enabled then
      FHScrollBar.Enabled := False
    else
      with FHScrollBar do
      begin
        SF.fMask := SIF_ALL;
        SF.cbSize := SizeOf(SF);
        GetScrollInfo(Self.Handle, SB_HORZ, SF);
        sMin := SF.nMin;
        SMax := SF.nMax;
        SPos := SF.nPos;
        sPage := SF.nPage;
        if SMax > sPage then
        begin
          SetRange(0, SMax, SPos, sPage);
          if not Enabled then
          begin
            Enabled := True;
          end;
        end
        else
        begin
          SetRange(0, 0, 0, 0);
          if Enabled then
          begin
            Enabled := False;
          end;
        end;
      end;
end;

procedure TWidgetTree.UpDateScrollRanges;
begin
  UpdateVerticalScrollBar(False);
  UpdateHorizontalScrollBar(False);
end;

procedure TWidgetTree.UpdateVerticalScrollBar(DoRepaint: Boolean);
var
  SF: ScrollInfo;
  sMin, SMax, SPos, sPage: Integer;
begin
  inherited;
  if csDesigning in ComponentState then
    Exit;
  if FVScrollBar <> nil then
    if not Enabled then
      FVScrollBar.Enabled := False
    else
      with FVScrollBar do
      begin
        SF.fMask := SIF_ALL;
        SF.cbSize := SizeOf(SF);
        if GetScrollInfo(Self.Handle, SB_VERT, SF) then
        begin
          sMin := SF.nMin;
          SMax := SF.nMax;
          SPos := SF.nPos;
          sPage := SF.nPage;
          if SMax + 1 > sPage then
          begin
            SetRange(0, SMax, SPos, sPage);
            if not Enabled then
            begin
              Enabled := True;
            end;
          end
          else
          begin
            SetRange(0, 0, 0, 0);
            if Enabled then
            begin
              Enabled := False;
            end;
          end;
        end
        else
        begin
          SetRange(0, 0, 0, 0);
          if Enabled then
          begin
            Enabled := False;
          end;
        end;
      end;
end;

procedure TWidgetTree.WMNCCALCSIZE(var Message: TWMNCCalcSize);
begin
  with Header do
    if hoVisible in Header.Options then
      with Message.CalcSize_Params^ do
        Inc(rgrc[0].Top, Height);
end;

end.
