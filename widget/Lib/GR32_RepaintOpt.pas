unit GR32_RepaintOpt;

interface

{$I GR32.inc}

uses
{$IFDEF FPC}
  LCLIntf,
{$ELSE}
  Windows,
{$ENDIF}
  Classes, SysUtils, GR32, GR32_Containers, GR32_Layers;

type
  
  TCustomRepaintOptimizer = class
  private
    FEnabled: Boolean;
    FLayerCollections: TList;
    FInvalidRects: TRectList;
    FBuffer: TBitmap32;
  protected
    function GetEnabled: Boolean; virtual;
    procedure SetEnabled(const Value: Boolean); virtual;
    property LayerCollections: TList read FLayerCollections write FLayerCollections;
    property Buffer: TBitmap32 read FBuffer write FBuffer;
    property InvalidRects: TRectList read FInvalidRects write FInvalidRects;
    
    procedure LayerCollectionNotifyHandler(Sender: TLayerCollection;
      Action: TLayerListNotification; Layer: TCustomLayer; Index: Integer); virtual; abstract;
  public
    constructor Create(Buffer: TBitmap32; InvalidRects: TRectList); virtual;
    destructor Destroy; override;

    procedure RegisterLayerCollection(Layers: TLayerCollection); virtual;
    procedure UnregisterLayerCollection(Layers: TLayerCollection); virtual;

    procedure BeginPaint; virtual;
    procedure EndPaint; virtual;
    procedure BeginPaintBuffer; virtual;
    procedure EndPaintBuffer; virtual;

    procedure Reset; virtual; abstract;
    function  UpdatesAvailable: Boolean; virtual; abstract;
    procedure PerformOptimization; virtual; abstract;
    
    procedure AreaUpdateHandler(Sender: TObject; const Area: TRect; const Info: Cardinal); virtual; abstract;
    procedure LayerUpdateHandler(Sender: TObject; Layer: TCustomLayer); virtual; abstract;
    procedure BufferResizedHandler(const NewWidth, NewHeight: Integer); virtual; abstract;

    property Enabled: Boolean read GetEnabled write SetEnabled;
  end;

  TCustomRepaintOptimizerClass = class of TCustomRepaintOptimizer;

procedure InflateArea(var Area: TRect; Dx, Dy: Integer);

implementation

procedure InflateArea(var Area: TRect; Dx, Dy: Integer);
begin
  if Area.Left > Area.Right then
    Dx := -Dx;

  if Area.Top > Area.Bottom then
    Dy := -Dy;

  Dec(Area.Left, Dx); Dec(Area.Top, Dy);
  Inc(Area.Right, Dx); Inc(Area.Bottom, Dy);
end;

type
  TLayerCollectionAccess = class(TLayerCollection);

constructor TCustomRepaintOptimizer.Create(Buffer: TBitmap32; InvalidRects: TRectList);
begin
  FLayerCollections := TList.Create;
  FInvalidRects := InvalidRects;
  FBuffer := Buffer;
end;

destructor TCustomRepaintOptimizer.Destroy;
var
  I: Integer;
begin
  for I := 0 to FLayerCollections.Count - 1 do
    UnregisterLayerCollection(TLayerCollection(FLayerCollections[I]));

  FLayerCollections.Free;
  inherited;
end;

function TCustomRepaintOptimizer.GetEnabled: Boolean;
begin
  Result := FEnabled;
end;

procedure TCustomRepaintOptimizer.SetEnabled(const Value: Boolean);
begin
  FEnabled := Value;
end;

procedure TCustomRepaintOptimizer.RegisterLayerCollection(Layers: TLayerCollection);
begin
  if FLayerCollections.IndexOf(Layers) = -1 then
  begin
    FLayerCollections.Add(Layers);
    TLayerCollectionAccess(Layers).OnListNotify := LayerCollectionNotifyHandler;
  end;
end;

procedure TCustomRepaintOptimizer.UnregisterLayerCollection(Layers: TLayerCollection);
begin
  TLayerCollectionAccess(Layers).OnListNotify := nil;
  FLayerCollections.Remove(Layers);
end;

procedure TCustomRepaintOptimizer.BeginPaint;
begin
  
end;

procedure TCustomRepaintOptimizer.EndPaint;
begin
  
end;

procedure TCustomRepaintOptimizer.BeginPaintBuffer;
begin
  
end;

procedure TCustomRepaintOptimizer.EndPaintBuffer;
begin
  
end;

end.
 