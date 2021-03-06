unit VTAccessibilityFactory;

interface

uses
  {$if CompilerVersion >= 18}
    oleacc, 
  {$ifend}
  Classes, VirtualTrees;

type
  IVTAccessibleProvider = interface
    function CreateIAccessible(ATree: TBaseVirtualTree): IAccessible;
  end;

  TVTAccessibilityFactory = class(TObject)
  private
    FAccessibleProviders: TInterfaceList;
  public
    constructor Create;
    destructor Destroy; override;
    function CreateIAccessible(ATree: TBaseVirtualTree): IAccessible;
    procedure RegisterAccessibleProvider(AProvider: IVTAccessibleProvider);
    procedure UnRegisterAccessibleProvider(AProvider: IVTAccessibleProvider);
  end;

function GetAccessibilityFactory: TVTAccessibilityFactory;

implementation

var
  VTAccessibleFactory: TVTAccessibilityFactory = nil;
  AccessibilityAvailable: Boolean = False;

constructor TVTAccessibilityFactory.Create;
begin
  inherited Create;
  FAccessibleProviders := TInterfaceList.Create;
  FAccessibleProviders.Clear;
end;

function TVTAccessibilityFactory.CreateIAccessible(
  ATree: TBaseVirtualTree): IAccessible;
var
  I: Integer;
  TmpIAccessible: IAccessible;

begin
  Result := nil;
  if ATree <> nil then
  begin
    if ATree.Accessible = nil then
    begin
      if FAccessibleProviders.Count > 0 then
      begin
        Result := IVTAccessibleProvider(FAccessibleProviders.Items[0]).CreateIAccessible(ATree);
        Exit;
      end;
    end;
    if ATree.AccessibleItem = nil then
    begin
      if FAccessibleProviders.Count > 0 then
      begin
        for I := FAccessibleProviders.Count - 1 downto 1 do
        begin
          TmpIAccessible := IVTAccessibleProvider(FAccessibleProviders.Items[I]).CreateIAccessible(ATree);
          if TmpIAccessible <> nil then
          begin
            Result := TmpIAccessible;
            Break;
          end;
        end;
        if TmpIAccessible = nil then
        begin
          Result := IVTAccessibleProvider(FAccessibleProviders.Items[0]).CreateIAccessible(ATree);
        end;
      end;
    end
    else
      Result := ATree.AccessibleItem;
  end;
end;

destructor TVTAccessibilityFactory.Destroy;
begin
  FAccessibleProviders.Free;
  FAccessibleProviders := nil;
  inherited Destroy;
end;

procedure TVTAccessibilityFactory.RegisterAccessibleProvider(
  AProvider: IVTAccessibleProvider);

begin
  if FAccessibleProviders.IndexOf(AProvider) < 0 then
    FAccessibleProviders.Add(AProvider)
end;

procedure TVTAccessibilityFactory.UnRegisterAccessibleProvider(
  AProvider: IVTAccessibleProvider);

begin
  if FAccessibleProviders.IndexOf(AProvider) >= 0 then
    FAccessibleProviders.Remove(AProvider);
end;

function GetAccessibilityFactory: TVTAccessibilityFactory;

begin
  
  if not AccessibilityAvailable then
    AccessibilityAvailable := True;
  if AccessibilityAvailable then
  begin
    
    if VTAccessibleFactory = nil then
      VTAccessibleFactory := TVTAccessibilityFactory.Create;
    Result := VTAccessibleFactory;
  end
  else
    Result := nil;
end;

initialization

finalization
  VTAccessibleFactory.Free;

end.
 